#!/usr/bin/env python3
# The Mac layout is the master. Windows gives GlazeWM its Alt chords on L1, makes L3 Ctrl+Alt+Win like the Voyager's layer 7, and makes M3 Hyper.
import hashlib
import json
import re
import sys
from pathlib import Path

DIR = Path(__file__).resolve().parent
OUT = DIR / "q10max-win-v2.json"
DIGITS = set(range(30, 39))
# M stays Meh (Convey's memory capture) and Y stays Meh (hotkeys-and-remaps.ahk); GlazeWM's alt+m needs the real Alt.
ALT_KEYS = DIGITS | {4, 6, 7, 8, 9, 11, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24, 25, 26, 51}
# Middle key letters copy the Voyager's Nav layer (keyboard/voyager/BINDINGS.md), so a letter does the same on both
# keyboards here. Not copied: A (split-focus Meh), U/P (start/end of text), - (split down with A).
VOYAGER_NAV = {
    20: 0x43D,  # Q  Alt+F4
    26: 0x10A,  # W  Ctrl+G
    8: 0x108,  # E  Ctrl+E
    21: 0x115,  # R  Ctrl+R
    23: 0x317,  # T  Ctrl+Shift+T
    22: 0x32B,  # S  Ctrl+Shift+Tab
    7: 0x12B,  # D  Ctrl+Tab
    9: 0x117,  # F  Ctrl+T
    10: 0x11A,  # G  Ctrl+W
    29: 0x11D,  # Z  Ctrl+Z
    27: 0x31D,  # X  Ctrl+Shift+Z
    6: 0xAC,  # C  previous track
    25: 0xAB,  # V  next track
    5: 0xAE,  # B  play/pause
    16: 0x4A,  # M  Home
    54: 0x4E,  # ,  Page Down
    55: 0x4B,  # .  Page Up
}


def newest_mac():
    best = max((int(m.group(1)), p) for p in DIR.glob("q10max-v*.json") if (m := re.fullmatch(r"q10max-v(\d+)\.json", p.name)))
    return best[1]


def convert(d):
    km = d["keymap"]
    pos = [{(k["row"], k["col"]): k for k in layer} for layer in km]
    base = {rc: k["val"] for rc, k in pos[0].items()}
    assert [pos[0][(5, c)]["val"] for c in (1, 2, 3)] == [0x7E02, 0xE0, 0x7E00], "unexpected Mac bottom-left keys"
    for c, v in zip((1, 2, 3), (0xE0, 0xE3, 0xE2)):
        pos[0][(5, c)]["val"] = v
    # M5 opens the Convey cheat sheet: Hammerspoon turns the Mac's Shift+Cmd+§ into it, Convey listens on Ctrl+Alt+Shift+K here.
    assert pos[0][(5, 0)]["val"] == 0xA35, "unexpected Mac M5 key"
    pos[0][(5, 0)]["val"] = 0x700 | 14
    # M3 launches apps on both machines: Hammerspoon on the Mac, the Ctrl+Alt+Shift+Win hotkeys in hotkeys-and-remaps.ahk here.
    for layer in (0, 2):
        for k in km[layer]:
            if k["val"] == 0xB00:
                k["val"] = 0xF00
    for rc, k in pos[1].items():
        code = base[rc]
        if k["val"] == 0xD00 | code and code:
            k["val"] = (0x400 if code in ALT_KEYS else 0x700) | code
    for rc, k in pos[0].items():
        if k["val"] == 40 and pos[1][rc]["val"] == 1:
            pos[1][rc]["val"] = 0x400 | 40
    # Right big key + key = Ctrl+Alt+Win + key, the Voyager's layer 7 chords, so both keyboards share the slash commands in hotkeys-and-remaps.ahk.
    for k in km[3]:
        if k["val"] & 0xFF and (k["val"] & 0xFF00) == 0x700:
            k["val"] = 0xD00 | (k["val"] & 0xFF)
    # Middle key + U I O P: the Mac's Cmd/Opt arrows become Win/Alt arrows here (snap, Terminal pane focus).
    # Windows equivalents instead: start of text, word left, word right, end of text.
    by_code = {base[rc]: k for rc, k in pos[2].items()}
    for code, mac, win in ((24, 0x852, 0x14A), (12, 0x450, 0x150), (18, 0x44F, 0x14F), (19, 0x851, 0x14D)):
        assert by_code[code]["val"] == mac, f"unexpected Mac middle-key value for keycode {code}"
        by_code[code]["val"] = win
    for rc, k in pos[2].items():
        if base[rc] in VOYAGER_NAV:
            k["val"] = VOYAGER_NAV[base[rc]]
    # Middle key + A holds Meh instead of the Mac's Cmd+R. With the middle key's arrows that makes Meh+arrows,
    # the one chord for focusing a split or pane in any app; Windows Terminal binds it, no app claims it by default.
    assert pos[2][(3, 2)]["val"] == 0x815, "unexpected Mac middle-key A value"
    pos[2][(3, 2)]["val"] = 0x700
    # Middle key + 1 / 2 connect / disconnect the AirPods: audio-tray's own Ctrl+Alt+Shift+Win+1 / 2.
    # 3-9 send nothing: Win+Shift+digit opens taskbar apps here, and moving windows belongs to left space.
    for rc, k in pos[2].items():
        code = base[rc]
        if code in DIGITS and k["val"] == 0xE00 | code:
            k["val"] = 0xF00 | code if code in (30, 31) else 0
    d["MD5"] = hashlib.md5(json.dumps(km, separators=(",", ":")).encode()).hexdigest()
    return d


def main():
    src = newest_mac()
    out = json.dumps(convert(json.loads(src.read_text())), separators=(",", ":"))
    if "--check" in sys.argv:
        same = OUT.exists() and json.loads(OUT.read_text()) == json.loads(out)
        print(f"{OUT.name} {'matches' if same else 'DIFFERS from'} {src.name}")
        sys.exit(0 if same else 1)
    OUT.write_text(out)
    print(f"wrote {OUT.name} from {src.name}")


if __name__ == "__main__":
    main()
