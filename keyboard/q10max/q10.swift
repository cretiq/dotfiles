// Only VIA reads (0x01, 0x11, 0x12) and keymap writes (0x13, inside the 768-byte keymap, apply --yes only) are ever sent.
// Knob, macros, RGB, settings and firmware stay untouched. Wired USB only: the 2.4 GHz receiver is a different PID.
import Foundation
import IOKit.hid

let vendorID = 0x3434
let pidQ10 = 0x08A1
let keymapBytes = 768
let layerCount = 4, rowCount = 6, colCount = 16
let supportDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/share/q10")

struct Q10Error: Error, CustomStringConvertible {
    let description: String
    init(_ d: String) { description = d }
}

func say(_ s: String) { print(s) }

func validate(_ req: [UInt8], allowWrite: Bool) throws {
    guard let c = req.first else { throw Q10Error("empty request") }
    if c == 0x01 || c == 0x11 { return }
    if c == 0x12 || c == 0x13 {
        guard req.count >= 4 else { throw Q10Error("request too short") }
        let off = (Int(req[1]) << 8) | Int(req[2])
        let size = Int(req[3])
        guard size >= 1 && size <= 28 else { throw Q10Error("size must be 1..28") }
        guard off + size <= keymapBytes else { throw Q10Error("range outside the keymap (0..\(keymapBytes))") }
        if c == 0x13 {
            guard allowWrite else { throw Q10Error("write not allowed") }
            guard req.count == 4 + size else { throw Q10Error("payload length does not match size") }
        }
        return
    }
    throw Q10Error(String(format: "blocked VIA command 0x%02X", c))
}

final class ReplyBox {
    var data: [UInt8]? = nil
}

let inputCallback: IOHIDReportCallback = { context, _, _, _, _, report, length in
    guard let context = context else { return }
    let box = Unmanaged<ReplyBox>.fromOpaque(context).takeUnretainedValue()
    box.data = Array(UnsafeBufferPointer(start: report, count: length))
}

final class Device {
    let dev: IOHIDDevice
    let box = ReplyBox()
    let inBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    var allowWrite = false

    init(_ dev: IOHIDDevice) throws {
        self.dev = dev
        let r = IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        guard r == kIOReturnSuccess else {
            throw Q10Error(String(format: "open failed, IOReturn 0x%08X (grant Input Monitoring to the calling app, or run from Terminal)", r))
        }
        IOHIDDeviceRegisterInputReportCallback(dev, inBuf, 64, inputCallback, Unmanaged.passUnretained(box).toOpaque())
        IOHIDDeviceScheduleWithRunLoop(dev, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }

    func xfer(_ req: [UInt8], timeout: Double = 1.5) throws -> [UInt8] {
        try validate(req, allowWrite: allowWrite)
        var out = [UInt8](repeating: 0, count: 32)
        for (i, b) in req.prefix(32).enumerated() { out[i] = b }
        box.data = nil
        let r = IOHIDDeviceSetReport(dev, kIOHIDReportTypeOutput, 0, out, 32)
        guard r == kIOReturnSuccess else { throw Q10Error(String(format: "write failed, IOReturn 0x%08X", r)) }
        let echo = req[0] == 0x12 || req[0] == 0x13 ? 4 : 1
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            CFRunLoopRunInMode(.defaultMode, 0.005, false)
            if let d = box.data {
                if d.count >= echo && Array(d.prefix(echo)) == Array(req.prefix(echo)) { return d }
                box.data = nil
            }
        }
        throw Q10Error("no matching reply from device")
    }

    func close() {
        IOHIDDeviceUnscheduleFromRunLoop(dev, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}

func intProp(_ d: IOHIDDevice, _ key: String) -> Int {
    (IOHIDDeviceGetProperty(d, key as CFString) as? NSNumber)?.intValue ?? 0
}

func hidDevices(matching: [String: Int]) -> [IOHIDDevice] {
    let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    IOHIDManagerSetDeviceMatching(mgr, matching as CFDictionary)
    IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
    guard let set = IOHIDManagerCopyDevices(mgr) as? Set<IOHIDDevice> else { return [] }
    return Array(set)
}

func openKeyboard() throws -> Device {
    let found = hidDevices(matching: [
        kIOHIDVendorIDKey: vendorID, kIOHIDProductIDKey: pidQ10,
        kIOHIDPrimaryUsagePageKey: 0xFF60, kIOHIDPrimaryUsageKey: 0x61,
    ])
    guard let first = found.first else {
        throw Q10Error("No raw-HID interface (usage page 0xFF60) for PID 0x08A1. Plug the keyboard in with the USB cable (not the 2.4 GHz receiver) and run 'probe'.")
    }
    return try Device(first)
}

func readKeymap(_ dev: Device) throws -> [UInt8] {
    let proto = try dev.xfer([0x01])
    let layers = try dev.xfer([0x11])[1]
    say(String(format: "VIA protocol 0x%02X%02X, layers %d", proto[1], proto[2], layers))
    guard Int(layers) == layerCount else { throw Q10Error("Expected \(layerCount) layers, device reports \(layers)") }
    var buf = [UInt8](repeating: 0, count: keymapBytes)
    var off = 0
    while off < keymapBytes {
        let n = min(28, keymapBytes - off)
        let r = try dev.xfer([0x12, UInt8(off >> 8), UInt8(off & 0xFF), UInt8(n)])
        for i in 0..<n { buf[off + i] = r[4 + i] }
        off += 28
    }
    return buf
}

func cellOffset(_ l: Int, _ r: Int, _ c: Int) -> Int { ((l * rowCount + r) * colCount + c) * 2 }

func readJSONCells(_ path: String) throws -> [Int: Int] {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let km = j["keymap"] as? [[[String: Any]]], km.count == layerCount else { throw Q10Error("not a Launcher keymap export: \(path)") }
    var cells: [Int: Int] = [:]
    for (l, layer) in km.enumerated() {
        for k in layer {
            guard let r = k["row"] as? Int, let c = k["col"] as? Int, let v = k["val"] as? Int else { continue }
            if r < rowCount && c < colCount { cells[cellOffset(l, r, c)] = v }
        }
    }
    return cells
}

func describe(_ off: Int) -> String {
    let cell = off / 2
    let l = cell / (rowCount * colCount), r = (cell / colCount) % rowCount, c = cell % colCount
    return "L\(l) (\(r),\(c))"
}

func diffKeymap(_ buf: [UInt8], _ cells: [Int: Int]) -> [(off: Int, dev: Int, want: Int)] {
    cells.keys.sorted().compactMap { off in
        let dv = (Int(buf[off]) << 8) | Int(buf[off + 1])
        return dv != cells[off]! ? (off, dv, cells[off]!) : nil
    }
}

func differingBytes(_ a: [UInt8], _ b: [UInt8]) -> [Int] {
    (0..<a.count).filter { a[$0] != b[$0] }
}

func hex(_ b: [UInt8]) -> String { b.map { String(format: "%02x", $0) }.joined() }

func selftest() throws {
    struct Case { let name: String; let req: [UInt8]; let write: Bool }
    let blocked: [Case] = [
        Case(name: "reset keymap 0x06", req: [0x06], write: true),
        Case(name: "eeprom reset 0x0A", req: [0x0A], write: true),
        Case(name: "bootloader jump 0x0B", req: [0x0B], write: true),
        Case(name: "macro set buffer 0x0F", req: [0x0F, 0, 0, 4, 0, 0, 0, 0], write: true),
        Case(name: "macro reset 0x10", req: [0x10], write: true),
        Case(name: "custom set value 0x07", req: [0x07, 0, 0, 0], write: true),
        Case(name: "custom save 0x09", req: [0x09, 0, 0, 0], write: true),
        Case(name: "set keyboard value 0x03", req: [0x03, 0, 0, 0], write: true),
        Case(name: "set keycode 0x05", req: [0x05, 0, 0, 0, 0], write: true),
        Case(name: "set encoder 0x15", req: [0x15, 0, 0, 0, 0, 0], write: true),
        Case(name: "keymap write without allow flag", req: [0x13, 0, 0, 2, 0, 0], write: false),
        Case(name: "keymap write size 29", req: [0x13, 0, 0, 29] + [UInt8](repeating: 0, count: 29), write: true),
        Case(name: "keymap write size 0", req: [0x13, 0, 0, 0], write: true),
        Case(name: "keymap write past end (offset 760, size 28)", req: [0x13, 0x02, 0xF8, 28] + [UInt8](repeating: 0, count: 28), write: true),
        Case(name: "keymap write payload length mismatch", req: [0x13, 0, 0, 4, 0, 0], write: true),
        Case(name: "keymap read past end", req: [0x12, 0x03, 0x00, 28], write: false),
    ]
    let allowed: [Case] = [
        Case(name: "protocol version 0x01", req: [0x01], write: false),
        Case(name: "layer count 0x11", req: [0x11], write: false),
        Case(name: "keymap read 0..28", req: [0x12, 0, 0, 28], write: false),
        Case(name: "keymap write 140..168 (with flag)", req: [0x13, 0, 140, 28] + [UInt8](repeating: 0, count: 28), write: true),
    ]
    var ok = true
    for c in blocked {
        do { try validate(c.req, allowWrite: c.write); say("ALLOWED (BAD)  \(c.name)"); ok = false }
        catch { say("blocked        \(c.name): \(error)") }
    }
    for c in allowed {
        do { try validate(c.req, allowWrite: c.write); say("allowed        \(c.name)") }
        catch { say("BLOCKED (BAD)  \(c.name): \(error)"); ok = false }
    }
    guard ok else { throw Q10Error("selftest FAILED") }
    say("selftest passed: no device contact was made.")
}

func probe() {
    let devs = hidDevices(matching: [kIOHIDVendorIDKey: vendorID])
    if devs.isEmpty { say("No Keychron (VID 0x3434) HID interfaces found."); return }
    for d in devs.sorted(by: { intProp($0, kIOHIDProductIDKey) < intProp($1, kIOHIDProductIDKey) }) {
        let name = (IOHIDDeviceGetProperty(d, kIOHIDProductKey as CFString) as? String) ?? "?"
        say(String(format: "PID 0x%04X  page 0x%04X  usage 0x%02X  %@", intProp(d, kIOHIDProductIDKey), intProp(d, kIOHIDPrimaryUsagePageKey), intProp(d, kIOHIDPrimaryUsageKey), name))
    }
    say("Target: PID 0x08A1, page 0xFF60, usage 0x61.")
}

func arg(_ name: String, in args: [String]) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}

func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    let mode = args.first ?? "probe"
    switch mode {
    case "probe": probe()
    case "selftest": try selftest()
    case "dump":
        guard let file = arg("-f", in: args) else { throw Q10Error("-f is required") }
        let dev = try openKeyboard()
        defer { dev.close() }
        let buf = try readKeymap(dev)
        let cells = try readJSONCells(file)
        let d = diffKeymap(buf, cells)
        say("\(cells.count) cells compared, \(d.count) differ")
        for x in d.prefix(40) { say(String(format: "%@  device 0x%04x  file 0x%04x", describe(x.off), x.dev, x.want)) }
    case "apply":
        guard let file = arg("-f", in: args) else { throw Q10Error("-f is required") }
        let yes = args.contains("--yes")
        let maxCells = Int(arg("--max-cells", in: args) ?? "32") ?? 32
        let dev = try openKeyboard()
        defer { dev.close() }
        let cur = try readKeymap(dev)
        let cells = try readJSONCells(file)
        let plan = diffKeymap(cur, cells)
        if plan.isEmpty { say("Keyboard already matches the file. Nothing to write."); return }
        say("\(plan.count) cell(s) would change:")
        for x in plan { say(String(format: "%@  device 0x%04x  file 0x%04x", describe(x.off), x.dev, x.want)) }
        if plan.count > maxCells { throw Q10Error("Refusing: \(plan.count) cells differ, limit is \(maxCells) (--max-cells). Wrong file?") }
        var want = cur
        for (off, v) in cells { want[off] = UInt8((v >> 8) & 0xFF); want[off + 1] = UInt8(v & 0xFF) }
        let planned = differingBytes(cur, want)
        say("\(planned.count) byte(s) would change at offsets: \(planned.map(String.init).joined(separator: ", "))")
        if !yes { say("Dry run only. Re-run with --yes to write."); return }
        try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let stamp = DateFormatter(); stamp.dateFormat = "yyyyMMdd-HHmmss"
        let bak = supportDir.appendingPathComponent("backup-\(stamp.string(from: Date())).hex")
        try hex(cur).write(to: bak, atomically: true, encoding: .utf8)
        say("Backup of the current keymap bytes: \(bak.path)")
        dev.allowWrite = true
        var written = 0
        var off = 0
        while off < want.count {
            let n = min(28, want.count - off)
            let a = Array(cur[off..<off + n]), b = Array(want[off..<off + n])
            if a != b {
                _ = try dev.xfer([0x13, UInt8(off >> 8), UInt8(off & 0xFF), UInt8(n)] + b)
                written += 1
            }
            off += 28
        }
        say("Wrote \(written) chunk(s).")
        dev.allowWrite = false
        let after = try readKeymap(dev)
        let changed = differingBytes(cur, after)
        let unexpected = differingBytes(want, after)
        say("\(changed.count) byte(s) changed vs before; \(unexpected.count) byte(s) differ from the intended result.")
        if !unexpected.isEmpty || changed.count != planned.count {
            say("VERIFY FAILED. Restore with: apply -f <previous json> --yes (or import in the Launcher).")
            exit(2)
        }
        say("Verified: only the planned bytes changed and the keyboard matches the file.")
    default:
        throw Q10Error("unknown command '\(mode)'. Use probe, selftest, dump -f x.json, apply -f x.json [--yes].")
    }
}

do { try run() } catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
