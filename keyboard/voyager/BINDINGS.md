# Voyager bindings

Generated from the firmware repo by `scripts/bindings.py`. Do not edit. Oryx source revision: `5L3pB/pjMyob`.
Each grid is one layer: rows r0 (top) to r3, left half `||` right half, then the thumb keys (left outer, left inner `||` right inner, right outer).
`·` falls through to Main. `X / hold Y` taps X, holds Y. Layer 7, the Nav boot key and the top-right cheat sheet key come from `patch_layout.py`, not Oryx.

## L0 Main
```
r0  BSPC | 1 | 2 | 3 | 4 | 5 || 6 | 7 | 8 | 9 | 0 | Ctrl+Alt+Shift+K
r1  Ctrl | Q | W | E | R | T || Y | U | I | O | P | Å
r2  ESCAPE / hold Shift | A / hold Alt | S / hold Win | D / hold Ctrl | F | G || H | J | K | L | Ö | Ä
r3  A / hold L6 | Z | X | C | V | B || N | M | , | . | - | TAB
thumbs  hold L1 | SPACE / hold L2 || ENTER / hold Ctrl | BSPC / hold Shift
```

## L1 Sym+Num
```
r0  QK_DYNAMIC_TAPPING_TERM_DOWN | QK_DYNAMIC_TAPPING_TERM_UP | QK_DYNAMIC_TAPPING_TERM_PRINT | · | · | · || · | · | · | · | · | ·
r1  · | % | { | } | @ | ~ || ´ | + | < | > | = | ·
r2  · | & | ( | ) | ! | ? || RAlt+Shift+- | - | \ | / | | | ·
r3  · | $ | [ | ] | # | · || ^ | * | ; | : | _ | Alt+-
thumbs  · | · || · | ·
```

## L2 Nav  (~ = Ctrl+ the key)
```
r0  BOOTLOADER | · | · | AUDIO_VOL_DOWN | AUDIO_VOL_UP | RAlt+Ctrl+5 || CAPS | NUM | MS_WH_DOWN | MS_WH_UP | · | DELETE
r1  · | Alt+F4 | ~G | ~E | ~R | Ctrl+Shift+T || · | Alt+LEFT | ~LEFT | ~RIGHT | Alt+RIGHT | ·
r2  · | ~R | Ctrl+Shift+TAB | ~TAB | ~T | ~W || · | LEFT | DOWN | UP | RIGHT | ·
r3  · | ~Z | Ctrl+Shift+Z | MEDIA_PREV_TRACK | MEDIA_NEXT_TRACK | MEDIA_PLAY_PAUSE || · | HOME | PGDN | PAGE_UP | END | go to L8
thumbs  · | · || · | ·
```

## L3 Cmd+Sft  (~ = Alt+Ctrl+; ^ = Alt+Ctrl+Shift+ the key)
```
r0  · | ~1 | ~2 | ~3 | ~4 | ~5 || ~6 | ~7 | ~8 | ~9 | ~0 | ·
r1  · | ~Q | ~W | ~E | ~R | ~T || ^Y | ^U | ^I | ^O | ^P | ·
r2  · | ~A | ~S | ~D | ~F | ~G || ^H | ^J | ^K | ^L | · | ·
r3  · | ~Z | ~X | ~C | ~V | ~B || ^N | ^M | · | · | · | ·
thumbs  · | · || · | ·
```

## L4 Fn
```
r0  · | F1 | F2 | F3 | F4 | F5 || · | · | · | · | · | ·
r1  · | F6 | F7 | F8 | F9 | F10 || · | · | · | · | · | ·
r2  · | · | · | · | F11 | F12 || · | · | · | · | · | ·
r3  · | · | · | · | · | · || · | · | · | · | · | ·
thumbs  · | · || · | ·
```

## L5 Color
```
r0  · | · | · | · | · | · || RGB_SLD | TOGGLE_LAYER_COLOR | RGB_TOG | · | LED_LEVEL | HSV_139_255_255
r1  · | · | · | · | · | · || · | · | · | · | · | HSV_202_255_255
r2  · | · | · | · | · | · || · | RGB_SAI | RGB_VAI | RGB_SPI | RGB_HUI | HSV_118_255_255
r3  · | · | · | · | · | · || RGB_MODE_FORWARD | RGB_SAD | RGB_VAD | RGB_SPD | RGB_HUD | HSV_40_255_255
thumbs  · | · || · | ·
```

## L6 NumPad  (~ = Alt+Ctrl+Shift+ the key)
```
r0  · | ~1 | ~2 | ~3 | ~4 | ~5 || · | · | · | · | · | ·
r1  · | ~Q | ~W | ~E | ~R | ~T || KP_PLUS | KP_7 | KP_8 | KP_9 | , | KP_EQUAL
r2  · | ~A | ~S | ~D | ~F | ~G || KP_MINUS | KP_4 | KP_5 | KP_6 | . | *
r3  · | ~Z | ~X | ~C | ~V | ~B || KP_0 | KP_1 | KP_2 | KP_3 | / | ·
thumbs  · | · || KP_ENTER | ·
```

## L7 Number  (~ = Ctrl+Alt+Win+ the key)
```
r0  · | ~1 | ~2 | ~3 | ~4 | ~5 || ~6 | ~7 | ~8 | ~9 | ~0 | ·
r1  · | ~Q | ~W | ~E | ~R | ~T || ~Y | ~U | ~I | ~O | ~P | ~Å
r2  · | ~A | ~S | ~D | ~F | ~G || ~H | ~J | ~K | ~L | ~Ö | ~Ä
r3  · | ~Z | ~X | ~C | ~V | ~B || ~N | ~M | · | · | · | ·
thumbs  · | · || · | ·
```

## L8 Plain
```
r0  · | · | · | · | · | · || · | · | · | · | · | ·
r1  · | Q | W | E | R | T || Y | U | I | O | · | ·
r2  · | A | S | D | F | G || H | J | K | L | · | ·
r3  · | Z | X | C | V | B || N | M | · | · | · | go to L0
thumbs  · | SPACE || · | ·
```

## Combos (Main only)
- SPACE / hold L2 + ESCAPE / hold Shift → RAlt+Ctrl+Shift+Win
- B + V + C → tap-toggle L5
- , + M → '
- SPACE / hold L2 + A / hold L6 → tap-toggle L4
- , + . → "
- L + J + K → Win+Ctrl+Shift+F12
- SPACE / hold L2 + C → Ctrl+C
- SPACE / hold L2 + B + V → Ctrl+Shift+V
- SPACE / hold L2 + B → Ctrl+V
- R + E + W → ENTER
- S / hold Win + F + D / hold Ctrl → ENTER
- SPACE / hold L2 + Ctrl → tap-toggle L3
- SPACE / hold L2 + X → Ctrl+X
- SPACE / hold L2 + E → Ctrl+E
- ENTER / hold Ctrl + SPACE / hold L2 → tap-toggle L7
- A / hold Alt + SPACE / hold L2 → Ctrl+A

## AutoHotkey slash-command chords (`hotkeys-and-remaps.ahk`)
- Ctrl+Alt+Win+R → types /mr:deep-review
- Ctrl+Alt+Win+T → types /generate:long-title
- Ctrl+Alt+Win+D → types /dev:restart
- Ctrl+Alt+Win+N → types /next
- Ctrl+Alt+Win+C → types /cut
- Ctrl+Alt+Shift+R → types /rebuild
- Ctrl+Alt+Shift+Z → types /generate:long-title, then /copy, then /rename

