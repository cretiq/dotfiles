import CoreGraphics
import Foundation

let laptopFont = 15
let externalFont = 17
struct AppConfig {
    let path: String
    let app: String
}
let configs: [AppConfig] = [
    ("~/.config/ghostty/config", "Ghostty"),
    ("~/.config/scarry/config", "Scarry"),
].map { AppConfig(
    path: URL(fileURLWithPath: NSString(string: $0.0).expandingTildeInPath).resolvingSymlinksInPath().path,
    app: $0.1
) }

var lastExternal: Bool? = nil

func isClamshell() -> Bool {
    let task = Process()
    let pipe = Pipe()
    task.launchPath = "/usr/sbin/ioreg"
    task.arguments = ["-r", "-k", "AppleClamshellState", "-d", "4"]
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return output.contains("\"AppleClamshellState\" = Yes")
}

func isExternalDisplay() -> Bool {
    var count: UInt32 = 0
    CGGetOnlineDisplayList(10, nil, &count)
    return count > 1 || isClamshell()
}

func shell(_ command: String) {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    try? task.run()
    task.waitUntilExit()
}

func updateFontSize(_ external: Bool) {
    let size = external ? externalFont : laptopFont

    for cfg in configs {
        shell("sed -i '' 's/^font-size = .*/font-size = \(size)/' '\(cfg.path)'")
        shell("""
            osascript -e 'tell application "\(cfg.app)"
                repeat with t in every terminal
                    perform action "set_font_size:\(size)" on t
                end repeat
            end tell'
        """)
    }
    shell("pkill -SIGUSR2 ghostty")
}

func displayCallback(_: CGDirectDisplayID, _: CGDisplayChangeSummaryFlags, _: UnsafeMutableRawPointer?) {
    let external = isExternalDisplay()
    if external != lastExternal {
        lastExternal = external
        updateFontSize(external)
    }
}

// Set initial state
lastExternal = isExternalDisplay()
updateFontSize(lastExternal!)

// Listen for display changes (blocks forever, zero CPU when idle)
CGDisplayRegisterReconfigurationCallback(displayCallback, nil)
CFRunLoopRun()
