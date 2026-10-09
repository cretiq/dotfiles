#!/usr/bin/env python3
# The Mac layout is the master. Windows keeps L1 Meh and L3 Hyper, and gives GlazeWM its Alt chords.
import hashlib
import json
import re
import sys
from pathlib import Path

DIR = Path(__file__).resolve().parent
OUT = DIR / "q10max-win-v2.json"
DIGITS = set(range(30, 39))
JKLO = {13, 14, 15, 51}


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
    for layer in (0, 2):
        for k in km[layer]:
            if k["val"] == 0xB00:
                k["val"] = 0x600
    for rc, k in pos[1].items():
        code = base[rc]
        if k["val"] == 0xD00 | code and code:
            k["val"] = (0x400 if code in DIGITS or code in JKLO else 0x700) | code
    for k in km[3]:
        if k["val"] & 0xFF and (k["val"] & 0xFF00) == 0x700:
            k["val"] = 0xF00 | (k["val"] & 0xFF)
    for rc, k in pos[2].items():
        code = base[rc]
        if code in DIGITS and k["val"] == 0xE00 | code:
            k["val"] = 0x600 | code
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
