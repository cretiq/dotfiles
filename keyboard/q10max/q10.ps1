# Windows: swap the Keychron Q10 Max keymap over raw HID (VIA protocol). Wired USB only.
#   q10.ps1 probe                       list Keychron HID interfaces, no I/O
#   q10.ps1 selftest                    prove the safety rules block every other command, no device contact
#   q10.ps1 dump  -File x.json          read the keymap from the keyboard, compare with x.json (read-only)
#   q10.ps1 apply -File x.json          dry run: print what would change, send nothing
#   q10.ps1 apply -File x.json -Yes     write only the changed 28-byte chunks, then verify every byte
#   q10.ps1 install                     copy this script and the Windows keymap to %LOCALAPPDATA%\q10 for ahk/watchers.ahk
# Allowed on the wire: VIA 0x01, 0x11, 0x12 (reads) and 0x13 (keymap write, apply -Yes only, inside the 768-byte keymap).
# Knob/encoders, macros, RGB, settings and firmware are never touched.
param(
    [Parameter(Position = 0)][ValidateSet('probe', 'selftest', 'dump', 'apply', 'install')][string]$Mode = 'probe',
    [string]$File,
    [switch]$Yes,
    [switch]$AnyPid,
    [string]$RawOut,
    [int]$MaxCells = 32
)
$ErrorActionPreference = 'Stop'

$Pid_Q10 = 0x08A1
$Layers = 4; $Rows = 6; $Cols = 16

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public class Q10Dev : IDisposable {
    public const int KeymapBytes = 768;

    [StructLayout(LayoutKind.Sequential)] struct ATTR { public uint Size; public ushort Vid, Pid, Ver; }
    [StructLayout(LayoutKind.Sequential)] struct CAPS {
        public ushort Usage, UsagePage, InLen, OutLen, FeatLen;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 17)] public ushort[] Res;
        public ushort Nodes, InBtn, InVal, InIdx, OutBtn, OutVal, OutIdx, FeatBtn, FeatVal, FeatIdx;
    }
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFile(string n, uint access, uint share, IntPtr sec, uint disp, uint flags, IntPtr t);
    [DllImport("hid.dll")] static extern bool HidD_GetAttributes(SafeFileHandle h, ref ATTR a);
    [DllImport("hid.dll")] static extern bool HidD_GetPreparsedData(SafeFileHandle h, out IntPtr p);
    [DllImport("hid.dll")] static extern bool HidD_FreePreparsedData(IntPtr p);
    [DllImport("hid.dll")] static extern int HidP_GetCaps(IntPtr p, ref CAPS c);

    public static int[] Describe(string path) {
        using (var h = CreateFile(path, 0, 3, IntPtr.Zero, 3, 0, IntPtr.Zero)) {
            if (h.IsInvalid) return new int[] { -1, Marshal.GetLastWin32Error() };
            var a = new ATTR(); a.Size = (uint)Marshal.SizeOf(typeof(ATTR));
            if (!HidD_GetAttributes(h, ref a)) return new int[] { -2, 0 };
            IntPtr p;
            if (!HidD_GetPreparsedData(h, out p)) return new int[] { -3, 0 };
            var c = new CAPS();
            HidP_GetCaps(p, ref c);
            HidD_FreePreparsedData(p);
            return new int[] { 0, a.Vid, a.Pid, c.UsagePage, c.Usage, c.InLen, c.OutLen };
        }
    }

    // The only gate between this script and the keyboard. Every request passes through here before any I/O.
    public static void Validate(byte[] req, bool allowWrite) {
        if (req == null || req.Length < 1) throw new InvalidOperationException("empty request");
        byte c = req[0];
        if (c == 0x01 || c == 0x11) return;
        if (c == 0x12 || c == 0x13) {
            if (req.Length < 4) throw new InvalidOperationException("request too short");
            int off = (req[1] << 8) | req[2];
            int size = req[3];
            if (size < 1 || size > 28) throw new InvalidOperationException("size must be 1..28");
            if (off + size > KeymapBytes) throw new InvalidOperationException("range outside the keymap (0.." + KeymapBytes + ")");
            if (c == 0x13) {
                if (!allowWrite) throw new InvalidOperationException("write not allowed");
                if (req.Length != 4 + size) throw new InvalidOperationException("payload length does not match size");
            }
            return;
        }
        throw new InvalidOperationException("blocked VIA command 0x" + c.ToString("X2"));
    }

    FileStream fs; int inLen, outLen;
    public bool AllowWrite;

    public Q10Dev(string path, int inLen, int outLen) {
        this.inLen = inLen; this.outLen = outLen;
        var h = CreateFile(path, 0xC0000000, 3, IntPtr.Zero, 3, 0x40000000, IntPtr.Zero);
        if (h.IsInvalid) throw new IOException("open failed, win32 error " + Marshal.GetLastWin32Error());
        fs = new FileStream(h, FileAccess.ReadWrite, 1, true);
    }

    public byte[] Xfer(byte[] req, int timeoutMs) {
        Validate(req, AllowWrite);
        var o = new byte[outLen];
        Array.Copy(req, 0, o, 1, Math.Min(req.Length, outLen - 1));
        var w = fs.WriteAsync(o, 0, o.Length);
        if (!w.Wait(timeoutMs)) throw new TimeoutException("write timed out");
        var r = new byte[inLen];
        var rd = fs.ReadAsync(r, 0, r.Length);
        if (!rd.Wait(timeoutMs)) throw new TimeoutException("no reply from device");
        var d = new byte[inLen - 1];
        Array.Copy(r, 1, d, 0, d.Length);
        return d;
    }

    public void Dispose() { if (fs != null) fs.Dispose(); }
}
'@

function Get-Interfaces {
    Get-PnpDevice -PresentOnly -Class HIDClass |
        Where-Object { $_.InstanceId -match '^HID\\VID_3434' } |
        ForEach-Object {
            $path = '\\?\' + ($_.InstanceId -replace '\\', '#') + '#{4d1e55b2-f16f-11cf-88cb-001111000030}'
            $d = [Q10Dev]::Describe($path)
            [pscustomobject]@{
                Path = $path; Id = $_.InstanceId
                Ok = ($d[0] -eq 0)
                Pid = if ($d[0] -eq 0) { $d[2] } else { 0 }
                Page = if ($d[0] -eq 0) { $d[3] } else { 0 }
                Usage = if ($d[0] -eq 0) { $d[4] } else { 0 }
                InLen = if ($d[0] -eq 0) { $d[5] } else { 0 }
                OutLen = if ($d[0] -eq 0) { $d[6] } else { 0 }
                Err = if ($d[0] -ne 0) { "$($d[0]) / $($d[1])" } else { '' }
            }
        }
}

function Open-Keyboard {
    $raw = Get-Interfaces | Where-Object { $_.Ok -and $_.Page -eq 0xFF60 -and $_.Usage -eq 0x61 -and ($AnyPid -or $_.Pid -eq $Pid_Q10) }
    if (-not $raw) { throw "No raw-HID interface (usage page 0xFF60) for PID 0x08A1. Plug the keyboard in with the USB cable (not the 2.4 GHz receiver) and run 'probe'." }
    $i = @($raw)[0]
    [Q10Dev]::new($i.Path, $i.InLen, $i.OutLen)
}

function Read-Keymap($dev) {
    $proto = $dev.Xfer([byte[]](0x01), 1500)
    $layers = $dev.Xfer([byte[]](0x11), 1500)[1]
    "VIA protocol 0x{0:X2}{1:X2}, layers {2}" -f $proto[1], $proto[2], $layers | Write-Host
    if ($layers -ne $Layers) { throw "Expected $Layers layers, device reports $layers" }
    $len = $Layers * $Rows * $Cols * 2
    $buf = New-Object byte[] $len
    for ($off = 0; $off -lt $len; $off += 28) {
        $n = [Math]::Min(28, $len - $off)
        $r = $dev.Xfer([byte[]](0x12, ($off -shr 8), ($off -band 0xFF), $n), 1500)
        [Array]::Copy($r, 4, $buf, $off, $n)
    }
    , $buf
}

function Read-JsonCells($path) {
    $j = Get-Content -Raw $path | ConvertFrom-Json
    $cells = @{}
    for ($l = 0; $l -lt $Layers; $l++) {
        foreach ($k in $j.keymap[$l]) { if ($k.row -lt $Rows -and $k.col -lt $Cols) { $cells["$l,$($k.row),$($k.col)"] = [int]$k.val } }
    }
    $cells
}

function Cell-Offset($l, $r, $c) { (($l * $Rows + $r) * $Cols + $c) * 2 }

function Diff-Keymap($buf, $cells) {
    $diffs = @()
    foreach ($key in $cells.Keys) {
        $p = $key -split ','
        $o = Cell-Offset ([int]$p[0]) ([int]$p[1]) ([int]$p[2])
        $dv = ([int]$buf[$o] -shl 8) -bor [int]$buf[$o + 1]
        if ($dv -ne $cells[$key]) { $diffs += [pscustomobject]@{ Layer = [int]$p[0]; Row = [int]$p[1]; Col = [int]$p[2]; Device = '0x{0:x4}' -f $dv; Json = '0x{0:x4}' -f $cells[$key] } }
    }
    $diffs | Sort-Object Layer, Row, Col
}

function Differing-Bytes($a, $b) {
    for ($i = 0; $i -lt $a.Length; $i++) { if ($a[$i] -ne $b[$i]) { $i } }
}

switch ($Mode) {
    'install' {
        $dst = Join-Path $env:LOCALAPPDATA 'q10'
        New-Item -ItemType Directory -Force $dst | Out-Null
        foreach ($f in 'q10.ps1', 'q10max-win-v2.json') { Copy-Item -Force (Join-Path $PSScriptRoot $f) $dst }
        "Copied q10.ps1 and q10max-win-v2.json to $dst (used by watchers.ahk on cable connect)."
    }
    'probe' {
        Get-Interfaces | Format-Table Id, Ok, @{n = 'PID'; e = { '0x{0:X4}' -f $_.Pid } }, @{n = 'Page'; e = { '0x{0:X4}' -f $_.Page } }, @{n = 'Usage'; e = { '0x{0:X2}' -f $_.Usage } }, InLen, OutLen, Err -AutoSize | Out-String -Width 250
        'Target: a row with PID 0x08A1, Page 0xFF60, Usage 0x61, InLen/OutLen 33.'
    }
    'selftest' {
        $cases = @(
            @{ n = 'reset keymap 0x06'; r = [byte[]](0x06); w = $true },
            @{ n = 'eeprom reset 0x0A'; r = [byte[]](0x0A); w = $true },
            @{ n = 'bootloader jump 0x0B'; r = [byte[]](0x0B); w = $true },
            @{ n = 'macro set buffer 0x0F'; r = [byte[]](0x0F, 0, 0, 4, 0, 0, 0, 0); w = $true },
            @{ n = 'macro reset 0x10'; r = [byte[]](0x10); w = $true },
            @{ n = 'custom set value 0x07'; r = [byte[]](0x07, 0, 0, 0); w = $true },
            @{ n = 'custom save 0x09'; r = [byte[]](0x09, 0, 0, 0); w = $true },
            @{ n = 'set keyboard value 0x03'; r = [byte[]](0x03, 0, 0, 0); w = $true },
            @{ n = 'set keycode 0x05'; r = [byte[]](0x05, 0, 0, 0, 0); w = $true },
            @{ n = 'set encoder 0x15'; r = [byte[]](0x15, 0, 0, 0, 0, 0); w = $true },
            @{ n = 'keymap write without allow flag'; r = [byte[]](0x13, 0, 0, 2, 0, 0); w = $false },
            @{ n = 'keymap write size 29'; r = [byte[]](0x13, 0, 0, 29) + (New-Object byte[] 29); w = $true },
            @{ n = 'keymap write size 0'; r = [byte[]](0x13, 0, 0, 0); w = $true },
            @{ n = 'keymap write past end (offset 760, size 28)'; r = [byte[]](0x13, 0x02, 0xF8, 28) + (New-Object byte[] 28); w = $true },
            @{ n = 'keymap write payload length mismatch'; r = [byte[]](0x13, 0, 0, 4, 0, 0); w = $true },
            @{ n = 'keymap read past end'; r = [byte[]](0x12, 0x03, 0x00, 28); w = $false }
        )
        $ok = $true
        foreach ($c in $cases) {
            try { [Q10Dev]::Validate($c.r, $c.w); "ALLOWED (BAD)  $($c.n)" | Write-Host -ForegroundColor Red; $ok = $false }
            catch { "blocked        $($c.n): $($_.Exception.InnerException.Message)" | Write-Host }
        }
        $allowed = @(
            @{ n = 'protocol version 0x01'; r = [byte[]](0x01); w = $false },
            @{ n = 'layer count 0x11'; r = [byte[]](0x11); w = $false },
            @{ n = 'keymap read 0..28'; r = [byte[]](0x12, 0, 0, 28); w = $false },
            @{ n = 'keymap write 140..168 (with flag)'; r = [byte[]](0x13, 0, 140, 28) + (New-Object byte[] 28); w = $true }
        )
        foreach ($c in $allowed) {
            try { [Q10Dev]::Validate($c.r, $c.w); "allowed        $($c.n)" | Write-Host }
            catch { "BLOCKED (BAD)  $($c.n): $($_.Exception.InnerException.Message)" | Write-Host -ForegroundColor Red; $ok = $false }
        }
        if ($ok) { 'selftest passed: no device contact was made.' | Write-Host -ForegroundColor Green } else { throw 'selftest FAILED' }
    }
    'dump' {
        if (-not $File) { throw '-File is required' }
        $dev = Open-Keyboard
        try {
            $buf = Read-Keymap $dev
            if ($RawOut) { ($buf | ForEach-Object { '{0:x2}' -f $_ }) -join '' | Set-Content $RawOut }
            $cells = Read-JsonCells $File
            $d = @(Diff-Keymap $buf $cells)
            "{0} cells compared, {1} differ" -f $cells.Count, $d.Count | Write-Host
            $d | Select-Object -First 40 | Format-Table -AutoSize | Out-String | Write-Host
        } finally { $dev.Dispose() }
    }
    'apply' {
        if (-not $File) { throw '-File is required' }
        if ($AnyPid) { throw 'apply never accepts -AnyPid: it only talks to PID 0x08A1' }
        $dev = Open-Keyboard
        try {
            $cur = Read-Keymap $dev
            $cells = Read-JsonCells $File
            $plan = @(Diff-Keymap $cur $cells)
            if ($plan.Count -eq 0) { 'Keyboard already matches the file. Nothing to write.' | Write-Host; return }
            "{0} cell(s) would change:" -f $plan.Count | Write-Host
            $plan | Format-Table -AutoSize | Out-String | Write-Host
            if ($plan.Count -gt $MaxCells) { throw "Refusing: $($plan.Count) cells differ, limit is $MaxCells (-MaxCells). Wrong file?" }
            $want = $cur.Clone()
            foreach ($key in $cells.Keys) {
                $p = $key -split ','
                $o = Cell-Offset ([int]$p[0]) ([int]$p[1]) ([int]$p[2])
                $want[$o] = ($cells[$key] -shr 8) -band 0xFF; $want[$o + 1] = $cells[$key] -band 0xFF
            }
            $planned = @(Differing-Bytes $cur $want)
            "{0} byte(s) would change at offsets: {1}" -f $planned.Count, ($planned -join ', ') | Write-Host
            if (-not $Yes) { 'Dry run only. Re-run with -Yes to write.' | Write-Host; return }
            $dir = Join-Path $env:LOCALAPPDATA 'q10'; New-Item -ItemType Directory -Force $dir | Out-Null
            $bak = Join-Path $dir ("backup-{0}.hex" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
            ($cur | ForEach-Object { '{0:x2}' -f $_ }) -join '' | Set-Content $bak
            "Backup of the current keymap bytes: $bak" | Write-Host
            $dev.AllowWrite = $true
            $written = 0
            for ($off = 0; $off -lt $want.Length; $off += 28) {
                $n = [Math]::Min(28, $want.Length - $off)
                $a = [byte[]]$cur[$off..($off + $n - 1)]; $b = [byte[]]$want[$off..($off + $n - 1)]
                if (-not [System.Linq.Enumerable]::SequenceEqual($a, $b)) {
                    [void]$dev.Xfer(([byte[]](0x13, ($off -shr 8), ($off -band 0xFF), $n) + $b), 1500)
                    $written++
                }
            }
            "Wrote $written chunk(s)." | Write-Host
            $dev.AllowWrite = $false
            $after = Read-Keymap $dev
            $changed = @(Differing-Bytes $cur $after)
            $unexpected = @(Differing-Bytes $want $after)
            "{0} byte(s) changed vs before; {1} byte(s) differ from the intended result." -f $changed.Count, $unexpected.Count | Write-Host
            if ($unexpected.Count -or $changed.Count -ne $planned.Count) { 'VERIFY FAILED. Restore with: apply -File <previous json> -Yes (or import in the Launcher).' | Write-Host -ForegroundColor Red }
            else { 'Verified: only the planned bytes changed and the keyboard matches the file.' | Write-Host -ForegroundColor Green }
        } finally { $dev.Dispose() }
    }
}
