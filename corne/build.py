#!/usr/bin/env python3
"""
Translate ZSA Voyager (52-key, 4 rows + 4 thumbs) keymap → Corne SZRKBD VIAL JSON
(46-key, 3 letter rows + thumbs cluster, with inner-right extra column).

Strategy:
- Drop Voyager row 1 (number row)            → goes to layer 7
- Drop Voyager RGB layer 5                   → leaves base bare on Corne L5
- Voyager rows 2,3,4 → Corne rows 0,1,2
- Column shift rule on base layers:
    Voyager col 0    → Corne col 0
    Voyager col 1-5  → Corne col 1-5
    Voyager col 6-10 → Corne col 7-11   (right hand shifted right by 1)
    Voyager col 11   → Corne col 6      (outer-right → inner-right extra)
- Voyager row 4 col 11 (TAB) → Corne row 3 col 1 (preserved on thumb)
- Voyager 4 thumbs → Corne row 3 cols 4/5/6/7 (main thumb cluster)
- Outer thumb-row positions get preserved defaults + lost MEH/HYPR
"""

import json
from copy import deepcopy

VIL_TEMPLATE = "/Users/filipmellqvist/Downloads/corne.vil"
OUT = "/Users/filipmellqvist/.dotfiles/corne/keymap.vil"

# ─── Swedish keycode aliases (positional, host=Swedish OS layout) ───────────
SE = {
    "AA":   "KC_LBRC",          # Å
    "OSLH": "KC_SCLN",          # Ö
    "ADIA": "KC_QUOT",          # Ä
    "MINS": "KC_SLSH",          # -
    "ACUT": "KC_EQL",           # ´
    "PLUS": "KC_MINS",          # +
    "LESS": "KC_NUBS",          # <
    "GRTR": "LSFT(KC_NUBS)",    # >
    "EQL":  "LSFT(KC_0)",       # =
    "AMPR": "LSFT(KC_6)",       # &
    "LPRN": "LSFT(KC_8)",       # (
    "RPRN": "LSFT(KC_9)",       # )
    "QUES": "LSFT(KC_MINS)",    # ?
    "DLR":  "RALT(KC_4)",       # $
    "LBRC": "RALT(KC_8)",       # [
    "RBRC": "RALT(KC_9)",       # ]
    "LCBR": "RALT(KC_7)",       # {
    "RCBR": "RALT(KC_0)",       # }
    "AT":   "RALT(KC_2)",       # @
    "TILD": "RALT(KC_RBRC)",    # ~
    "BSLS": "RALT(KC_MINS)",    # \
    "SLSH": "LSFT(KC_7)",       # /
    "PIPE": "RALT(KC_NUBS)",    # |
    "CIRC": "LSFT(KC_RBRC)",    # ^
    "ASTR": "LSFT(KC_NUHS)",    # *
    "SCLN": "LSFT(KC_COMMA)",   # ;
    "COLN": "LSFT(KC_DOT)",     # :
    "UNDS": "LSFT(KC_SLSH)",    # _
    "APOS": "KC_NUHS",          # '
    "DQUO": "LSFT(KC_2)",       # "
    "HASH": "KC_NONUS_HASH",    # # (alias used in Voyager src as KC_HASH)
    "EXLM": "LSFT(KC_1)",       # !
    "PERC": "LSFT(KC_5)",       # %
}

# ─── Voyager → VIAL keycode normalization ───────────────────────────────────
TR = {
    "KC_TRANSPARENT":      "KC_TRNS",
    "KC_NO":               "KC_NO",
    "KC_LEFT_CTRL":        "KC_LCTRL",
    "KC_LCTL":             "KC_LCTRL",
    "KC_LSFT":             "KC_LSHIFT",
    "KC_LSHIFT":           "KC_LSHIFT",
    "KC_LALT":             "KC_LALT",
    "KC_LGUI":             "KC_LGUI",
    "KC_RCTL":             "KC_RCTRL",
    "KC_RSFT":             "KC_RSHIFT",
    "KC_RGUI":             "KC_RGUI",
    "KC_RALT":             "KC_RALT",
    "KC_HYPR":             "KC_HYPR",
    "KC_MEH":              "KC_MEH",
    "KC_ESCAPE":           "KC_ESCAPE",
    "KC_ESC":              "KC_ESCAPE",
    "KC_ENTER":            "KC_ENTER",
    "KC_ENT":              "KC_ENTER",
    "KC_SPACE":            "KC_SPACE",
    "KC_SPC":              "KC_SPACE",
    "KC_BSPC":             "KC_BSPACE",
    "KC_BSPACE":           "KC_BSPACE",
    "KC_TAB":              "KC_TAB",
    "KC_DELETE":           "KC_DELETE",
    "KC_DEL":              "KC_DELETE",
    "KC_HOME":             "KC_HOME",
    "KC_END":              "KC_END",
    "KC_PAGE_UP":          "KC_PGUP",
    "KC_PGUP":             "KC_PGUP",
    "KC_PAGE_DOWN":        "KC_PGDOWN",
    "KC_PGDN":             "KC_PGDOWN",
    "KC_LEFT":             "KC_LEFT",
    "KC_RIGHT":            "KC_RIGHT",
    "KC_UP":               "KC_UP",
    "KC_DOWN":             "KC_DOWN",
    "KC_AUDIO_VOL_UP":     "KC_VOLU",
    "KC_AUDIO_VOL_DOWN":   "KC_VOLD",
    "KC_AUDIO_MUTE":       "KC_MUTE",
    "KC_MEDIA_PLAY_PAUSE": "KC_MPLY",
    "KC_MEDIA_NEXT_TRACK": "KC_MNXT",
    "KC_MEDIA_PREV_TRACK": "KC_MPRV",
    "KC_MS_WH_UP":         "KC_MS_WH_UP",
    "KC_MS_WH_DOWN":       "KC_MS_WH_DOWN",
    "KC_CAPS":             "KC_CAPSLOCK",
    "KC_NUM":              "KC_NUMLOCK",
    "KC_KP_PLUS":          "KC_KP_PLUS",
    "KC_KP_MINUS":         "KC_KP_MINUS",
    "KC_KP_EQUAL":         "KC_KP_EQUAL",
    "KC_KP_ENTER":         "KC_KP_ENTER",
    "KC_KP_0":             "KC_KP_0",
    "KC_KP_1":             "KC_KP_1",
    "KC_KP_2":             "KC_KP_2",
    "KC_KP_3":             "KC_KP_3",
    "KC_KP_4":             "KC_KP_4",
    "KC_KP_5":             "KC_KP_5",
    "KC_KP_6":             "KC_KP_6",
    "KC_KP_7":             "KC_KP_7",
    "KC_KP_8":             "KC_KP_8",
    "KC_KP_9":             "KC_KP_9",
    "KC_F1":  "KC_F1",  "KC_F2":  "KC_F2",  "KC_F3":  "KC_F3",  "KC_F4":  "KC_F4",
    "KC_F5":  "KC_F5",  "KC_F6":  "KC_F6",  "KC_F7":  "KC_F7",  "KC_F8":  "KC_F8",
    "KC_F9":  "KC_F9",  "KC_F10": "KC_F10", "KC_F11": "KC_F11", "KC_F12": "KC_F12",
    "KC_COMMA": "KC_COMMA", "KC_DOT": "KC_DOT", "KC_SLASH": "KC_SLASH",
    "KC_HASH":  "KC_NONUS_HASH",
    "KC_EXLM":  "LSFT(KC_1)",
    "KC_PERC":  "LSFT(KC_5)",     # SE: %
    "KC_AT":    "RALT(KC_2)",     # SE: @
    "KC_DLR":   "RALT(KC_4)",     # SE: $
    "KC_AMPR":  "LSFT(KC_6)",     # SE: &
    "KC_QUES":  "LSFT(KC_MINS)",  # SE: ?
    "KC_LPRN":  "LSFT(KC_8)",     # SE: (
    "KC_RPRN":  "LSFT(KC_9)",     # SE: )
    "KC_LCBR":  "RALT(KC_7)",     # SE: {
    "KC_RCBR":  "RALT(KC_0)",     # SE: }
    "KC_LBRC":  "RALT(KC_8)",     # SE: [
    "KC_RBRC":  "RALT(KC_9)",     # SE: ]
    "KC_PIPE":  "RALT(KC_NUBS)",  # SE: |
    "KC_BSLS":  "RALT(KC_MINS)",  # SE: \
    "KC_CIRC":  "LSFT(KC_RBRC)",  # SE: ^
    "KC_TILD":  "RALT(KC_RBRC)",  # SE: ~
    "KC_UNDS":  "LSFT(KC_SLSH)",  # SE: _
    "KC_PLUS":  "KC_MINS",         # SE: +
    "KC_EQL":   "LSFT(KC_0)",      # SE: =
    "KC_MINUS": "KC_SLASH",        # SE: -
    "KC_LT":    "KC_NUBS",         # SE: <
    "KC_GT":    "LSFT(KC_NUBS)",   # SE: >
    "KC_ASTR":  "LSFT(KC_NUHS)",  # SE: *
    "KC_ASTERISK": "LSFT(KC_NUHS)",
    "KC_QUOT":  "KC_NUHS",         # SE: '
    "KC_DQUO":  "LSFT(KC_2)",      # SE: "
    "KC_COLN":  "LSFT(KC_DOT)",    # SE: :
    "KC_SCLN":  "LSFT(KC_COMMA)",  # SE: ;
    "KC_NUHS":  "KC_NUHS",
    "KC_NUBS":  "KC_NUBS",
    "KC_RBRC_": "KC_RBRC",   # placeholder, never used
    "QK_DYNAMIC_TAPPING_TERM_DOWN":  "QK_DYNAMIC_TAPPING_TERM_DOWN",
    "QK_DYNAMIC_TAPPING_TERM_UP":    "QK_DYNAMIC_TAPPING_TERM_UP",
    "QK_DYNAMIC_TAPPING_TERM_PRINT": "QK_DYNAMIC_TAPPING_TERM_PRINT",
    "RGB_SLD": "KC_TRNS", "TOGGLE_LAYER_COLOR": "KC_TRNS", "RGB_TOG": "KC_TRNS",
    "LED_LEVEL": "KC_TRNS", "RGB_SAI": "KC_TRNS", "RGB_VAI": "KC_TRNS",
    "RGB_SPI": "KC_TRNS", "RGB_HUI": "KC_TRNS", "RGB_SAD": "KC_TRNS",
    "RGB_VAD": "KC_TRNS", "RGB_SPD": "KC_TRNS", "RGB_HUD": "KC_TRNS",
    "RGB_MODE_FORWARD": "KC_TRNS",
    "HSV_139_255_255": "KC_TRNS", "HSV_202_255_255": "KC_TRNS",
    "HSV_118_255_255": "KC_TRNS", "HSV_40_255_255":  "KC_TRNS",
    # Voyager Swedish keycodes (used as bare identifiers in some Oryx sources)
    **{f"SE_{k}": v for k, v in SE.items()},
}


def conv(kc):
    """Voyager keycode string → VIAL keycode string."""
    kc = kc.strip()
    if kc in TR:
        return TR[kc]
    # Letters A-Z and digits 0-9 pass through unchanged
    if kc.startswith("KC_") and len(kc) == 4 and (kc[3].isalpha() or kc[3].isdigit()):
        return kc
    # MT(MOD_LSFT, KC_ESCAPE) → LSFT_T(KC_ESCAPE)
    if kc.startswith("MT(MOD_"):
        inside = kc[3:-1]                                # MOD_LSFT, KC_ESCAPE
        mod, key = [s.strip() for s in inside.split(",", 1)]
        prefix = {
            "MOD_LSFT": "LSFT_T", "MOD_LCTL": "LCTL_T",
            "MOD_LALT": "LALT_T", "MOD_LGUI": "LGUI_T",
            "MOD_RSFT": "RSFT_T", "MOD_RCTL": "RCTL_T",
            "MOD_RALT": "RALT_T", "MOD_RGUI": "RGUI_T",
        }[mod]
        return f"{prefix}({conv(key)})"
    # LT(layer, kc), MO(n), TG(n), TT(n), TO(n)
    for fn in ("LT(", "MO(", "TG(", "TT(", "TO(", "LM("):
        if kc.startswith(fn):
            inside = kc[len(fn):-1]
            if "," in inside:
                a, b = [s.strip() for s in inside.split(",", 1)]
                return f"{fn}{a}, {conv(b)})"
            return f"{fn}{inside})"
    # Modifier wrappers: LSFT, LCTL, LALT, LGUI, RSFT, RCTL, RALT, RGUI, S, C, A, G
    for wrap in ("LSFT(", "LCTL(", "LALT(", "LGUI(",
                 "RSFT(", "RCTL(", "RALT(", "RGUI(",
                 "S(", "C(", "A(", "G("):
        if kc.startswith(wrap):
            inside = kc[len(wrap):-1]
            return f"{wrap}{conv(inside)})"
    raise ValueError(f"Unknown keycode: {kc!r}")


# ─── Voyager source layers (parsed from keymap.c) ──────────────────────────
# Each layer is 4 rows × 12 cols + 4 thumbs (last 2 lefts then 2 rights).
V = [
    # Layer 0 — base
    [
        ["KC_MEH","KC_1","KC_2","KC_3","KC_4","KC_5","KC_6","KC_7","KC_8","KC_9","KC_0","KC_HYPR"],
        ["KC_LEFT_CTRL","KC_Q","KC_W","KC_E","KC_R","KC_T","KC_Y","KC_U","KC_I","KC_O","KC_P","SE_AA"],
        ["MT(MOD_LSFT, KC_ESCAPE)","KC_A","KC_S","KC_D","KC_F","KC_G","KC_H","KC_J","KC_K","KC_L","SE_OSLH","SE_ADIA"],
        ["LT(6, KC_A)","KC_Z","KC_X","KC_C","KC_V","KC_B","KC_N","KC_M","KC_COMMA","KC_DOT","SE_MINS","KC_TAB"],
    ],
    # Layer 1 — symbols
    [
        ["QK_DYNAMIC_TAPPING_TERM_DOWN","QK_DYNAMIC_TAPPING_TERM_UP","QK_DYNAMIC_TAPPING_TERM_PRINT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_CAPS","KC_NUM"],
        ["KC_TRANSPARENT","KC_PERC","SE_LCBR","SE_RCBR","SE_AT","SE_TILD","SE_ACUT","SE_PLUS","SE_LESS","SE_GRTR","SE_EQL","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","SE_AMPR","SE_LPRN","SE_RPRN","KC_EXLM","SE_QUES","RALT(RSFT(SE_MINS))","SE_MINS","SE_BSLS","SE_SLSH","SE_PIPE","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","SE_DLR","SE_LBRC","SE_RBRC","KC_HASH","KC_TRANSPARENT","SE_CIRC","SE_ASTR","SE_SCLN","SE_COLN","SE_UNDS","LALT(SE_MINS)"],
    ],
    # Layer 2 — nav / media (Mac shortcuts: LCTL → LGUI for app actions; tab cycling stays LCTL on Mac)
    [
        ["KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_AUDIO_VOL_DOWN","KC_AUDIO_VOL_UP","LGUI(LSFT(KC_5))","KC_TRANSPARENT","KC_TRANSPARENT","KC_MS_WH_DOWN","KC_MS_WH_UP","KC_TRANSPARENT","KC_DELETE"],
        ["KC_TRANSPARENT","LGUI(KC_Q)","LGUI(KC_W)","LGUI(KC_E)","LGUI(KC_R)","LGUI(LSFT(KC_T))","KC_TRANSPARENT","LALT(KC_LEFT)","LCTL(KC_LEFT)","LCTL(KC_RIGHT)","LALT(KC_RIGHT)","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","LGUI(KC_R)","LCTL(LSFT(KC_TAB))","LCTL(KC_TAB)","LGUI(KC_T)","LGUI(KC_W)","KC_TRANSPARENT","KC_LEFT","KC_DOWN","KC_UP","KC_RIGHT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","LGUI(KC_Z)","LGUI(LSFT(KC_Z))","KC_MEDIA_PREV_TRACK","KC_MEDIA_NEXT_TRACK","KC_MEDIA_PLAY_PAUSE","KC_TRANSPARENT","KC_HOME","KC_PGDN","KC_PAGE_UP","KC_END","KC_TRANSPARENT"],
    ],
    # Layer 3 — screenshot / system shortcuts
    [
        ["KC_TRANSPARENT","LALT(LCTL(LSFT(KC_1)))","LALT(LCTL(LSFT(KC_2)))","LALT(LCTL(LSFT(KC_3)))","LALT(LCTL(LSFT(KC_4)))","LALT(LCTL(LSFT(KC_5)))","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","LALT(LCTL(KC_Q))","LALT(LCTL(KC_W))","LALT(LCTL(KC_E))","LALT(LCTL(KC_R))","LALT(LCTL(KC_T))","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","LALT(LCTL(KC_A))","LALT(LCTL(KC_S))","LALT(LCTL(KC_D))","LALT(LCTL(KC_F))","LALT(LCTL(KC_G))","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","LALT(LCTL(KC_Z))","LALT(LCTL(KC_X))","LALT(LCTL(KC_C))","LALT(LCTL(KC_V))","LALT(LCTL(KC_B))","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
    ],
    # Layer 4 — F-keys
    [
        ["KC_TRANSPARENT","KC_F1","KC_F2","KC_F3","KC_F4","KC_F5","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","KC_F6","KC_F7","KC_F8","KC_F9","KC_F10","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_F11","KC_F12","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
    ],
    # Layer 5 — gamer layer (overridden in main() — see new_layout[5] below)
    [["KC_TRANSPARENT"]*12 for _ in range(4)],
    # Layer 6 — numpad + Win+Shift+letter app shortcuts
    [
        ["KC_TRANSPARENT","LALT(LSFT(KC_1))","LALT(LSFT(KC_2))","LALT(LSFT(KC_3))","LALT(LSFT(KC_4))","LALT(LSFT(KC_5))","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","LALT(LSFT(KC_Q))","LALT(LSFT(KC_W))","LALT(LSFT(KC_E))","LALT(LSFT(KC_R))","LALT(LSFT(KC_T))","KC_KP_PLUS","KC_KP_7","KC_KP_8","KC_KP_9","KC_COMMA","KC_KP_EQUAL"],
        ["KC_TRANSPARENT","LALT(LSFT(KC_A))","LALT(LSFT(KC_S))","LALT(LSFT(KC_D))","LALT(LSFT(KC_F))","LALT(LSFT(KC_G))","KC_KP_MINUS","KC_KP_4","KC_KP_5","KC_KP_6","KC_DOT","KC_ASTR"],
        ["KC_TRANSPARENT","LALT(LSFT(KC_Z))","LALT(LSFT(KC_X))","LALT(LSFT(KC_C))","LALT(LSFT(KC_V))","LALT(LSFT(KC_B))","KC_KP_0","KC_KP_1","KC_KP_2","KC_KP_3","KC_SLASH","KC_TRANSPARENT"],
    ],
    # Layer 7 — number row replacement
    [
        ["KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","KC_1","KC_2","KC_3","KC_4","KC_5","KC_6","KC_7","KC_8","KC_9","KC_0","KC_TRANSPARENT"],
        ["KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT","KC_TRANSPARENT"],
    ],
]

# Voyager thumbs per layer:  [L_thumb1, L_thumb2, R_thumb1, R_thumb2]
V_THUMBS = [
    ["MO(1)",          "LT(2, KC_SPACE)",  "MT(MOD_RGUI, KC_ENTER)", "MT(MOD_LSFT, KC_BSPC)"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_TRANSPARENT",         "KC_TRANSPARENT"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_TRANSPARENT",         "KC_TRANSPARENT"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_TRANSPARENT",         "KC_TRANSPARENT"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_TRANSPARENT",         "KC_TRANSPARENT"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_TRANSPARENT",         "KC_TRANSPARENT"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_KP_ENTER",            "KC_TRANSPARENT"],
    ["KC_TRANSPARENT", "KC_TRANSPARENT",   "KC_TRANSPARENT",         "KC_TRANSPARENT"],
]


def map_row(voy_row, voy_row4_col11_to_thumb=False):
    """
    Voyager 12-col row → Corne 12-col row.
    Mapping:
        v0     → c0
        v1..5  → c1..5
        v11    → c6        (outer-right Voyager → inner-right Corne extra)
        v6..10 → c7..11    (right hand shifted right by 1)
    """
    c = ["KC_TRNS"] * 12
    c[0] = conv(voy_row[0])
    for i in range(1, 6):
        c[i] = conv(voy_row[i])
    c[6] = conv(voy_row[11])
    for i in range(6, 11):
        c[i + 1] = conv(voy_row[i])
    return c


def build_layer(layer_idx):
    """Build a Corne layer (4 rows × 12 cols, with -1 for missing positions)."""
    voy = V[layer_idx]
    # Corne row 0 ← Voyager row 2
    r0 = map_row(voy[1])
    # Corne row 1 ← Voyager row 3
    r1 = map_row(voy[2])
    # Corne row 2 ← Voyager row 4 (col 6 has no physical key on this Corne)
    r2 = map_row(voy[3])
    r2[6] = -1   # vendor's null position

    # Corne row 3 (thumbs + extras)
    t = V_THUMBS[layer_idx]
    if layer_idx == 0:
        r3 = [
            "KC_NO",                         # col 0
            "KC_NO",                         # col 1
            -1,                              # col 2  (no physical key)
            "KC_LALT",                       # col 3  ← outer-left thumb-extra (F1 phys key) = Alt
            conv(t[0]),                      # col 4  ← Voy L-thumb1 (MO 1)
            conv(t[1]),                      # col 5  ← Voy L-thumb2 (LT 2 SPC)
            conv(t[2]),                      # col 6  ← Voy R-thumb1 (GUI/ENT)
            conv(t[3]),                      # col 7  ← Voy R-thumb2 (SFT/BSPC)
            "LCTL_T(KC_BSPACE)",             # col 8  ← outer-right thumb-extra (F2 phys key) = Ctrl-tap
            "KC_SCLN",                       # col 9
            "KC_QUOT",                       # col 10
            "KC_TAB",                        # col 11
        ]
    else:
        # Other layers: thumbs transparent unless Voyager set them; extras transparent
        r3 = [
            "KC_TRNS", "KC_TRNS", -1, "KC_TRNS",
            conv(t[0]), conv(t[1]),
            conv(t[2]), conv(t[3]),
            "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS",
        ]
    return [r0, r1, r2, r3]


# ─── Combos: 14 from Voyager ────────────────────────────────────────────────
# Vial combo format = [t1, t2, t3, t4, output]
# Need to use the Corne keycodes (not Voyager source codes) for triggers.
COMBOS_RAW = [
    # (trigger_keycodes_in_corne, output)
    (["LT(2, KC_SPACE)", "LSFT_T(KC_ESCAPE)"],                        "RALT(RCTL(RSFT(KC_RGUI)))"),    # SPC+ESC = Hyper
    (["KC_B", "KC_V", "KC_C"],                                         "TT(5)"),                         # B+V+C = TG L5 (RGB — keep slot, no effect)
    (["KC_COMMA", "KC_M"],                                             SE["APOS"]),                      # ,+M = '
    (["LT(2, KC_SPACE)", "LT(6, KC_A)"],                               "TT(4)"),                         # SPC+LT6/A = TG L4 (F-keys)
    (["KC_COMMA", "KC_DOT"],                                           SE["DQUO"]),                      # ,+. = "
    (["LT(2, KC_SPACE)", "KC_C"],                                      "LGUI(KC_C)"),                    # SPC+C = Cmd+C
    (["LT(2, KC_SPACE)", "KC_B", "KC_V"],                              "LCTL(LSFT(KC_V))"),              # SPC+B+V = Ctrl+Shift+V
    (["LT(2, KC_SPACE)", "KC_B"],                                      "LGUI(KC_V)"),                    # SPC+B = Cmd+V
    (["LCTL_T(KC_S)", "KC_F", "LGUI_T(KC_D)"],                         "KC_ENTER"),                      # CTL/S+F+GUI/D = Enter
    (["LT(2, KC_SPACE)", "KC_LCTRL"],                                  "TT(3)"),                         # SPC+LCTL = TG L3
    (["LT(2, KC_SPACE)", "KC_X"],                                      "LCTL(KC_X)"),                    # SPC+X = Ctrl+X
    (["LT(2, KC_SPACE)", "KC_E"],                                      "LCTL(KC_E)"),                    # SPC+E = Ctrl+E
    (["RGUI_T(KC_ENTER)", "LT(2, KC_SPACE)"],                          "TT(7)"),                         # GUI/ENT+SPC = TG L7 (numbers)
]


def pad_combo(triggers, output):
    """Pad triggers to 4 slots + output = 5 strings."""
    pad = list(triggers) + ["KC_NO"] * (4 - len(triggers))
    return pad + [output]


def build_combos():
    out = []
    for trig, output in COMBOS_RAW:
        out.append(pad_combo(trig, output))
    # Pad to 32 total slots
    while len(out) < 32:
        out.append(["KC_NO", "KC_NO", "KC_NO", "KC_NO", "KC_NO"])
    return out


# ─── Main ───────────────────────────────────────────────────────────────────
def main():
    with open(VIL_TEMPLATE) as f:
        v = json.load(f)

    # Build layers 0..7
    new_layout = []
    for i in range(8):
        new_layout.append(build_layer(i))

    # Special override: Layer 5 = gamer layer. Plain keys only — no mod-tap,
    # no layer-tap — so dual-role behavior on home row / thumbs disappears
    # while gaming. Combos still fire across layers (firmware-level), so
    # B+V+C still toggles in/out, S+D+F still triggers ESC.
    new_layout[5] = [
        ["KC_LCTRL", "KC_Q", "KC_W", "KC_E", "KC_R", "KC_T",
         "KC_NO",   "KC_Y", "KC_U", "KC_I", "KC_O", "KC_P"],
        ["KC_ESCAPE","KC_A", "KC_S", "KC_D", "KC_F", "KC_G",
         "KC_NO",   "KC_H", "KC_J", "KC_K", "KC_L", "KC_LBRC"],
        ["KC_LSHIFT","KC_Z", "KC_X", "KC_C", "KC_V", "KC_B",
         -1,         "KC_N", "KC_M", "KC_COMMA", "KC_DOT", "KC_SLASH"],
        ["KC_NO",   "KC_NO", -1,    "KC_NO", "KC_LSHIFT", "KC_SPACE",
         "KC_ENTER","KC_BSPACE", "KC_NO", "KC_SCLN", "KC_QUOT", "KC_TAB"],
    ]

    # Special override: Layer 4 (F-keys). Voyager spread F1-F12 over 3 rows
    # (rows 1/2/3); the default row-drop loses F1-F5. Re-place all F-keys.
    new_layout[4] = [
        ["KC_TRNS", "KC_F1", "KC_F2", "KC_F3", "KC_F4",  "KC_F5",
         "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS"],
        ["KC_TRNS", "KC_F6", "KC_F7", "KC_F8", "KC_F9",  "KC_F10",
         "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS"],
        ["KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_F11", "KC_F12",
         -1,        "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS"],
        ["KC_TRNS", "KC_TRNS", -1, "KC_TRNS", "KC_TRNS", "KC_TRNS",
         "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS", "KC_TRNS"],
    ]

    v["layout"] = new_layout

    # Build combos
    v["combo"] = build_combos()

    # Preserve everything else (settings, macros, tap_dance, key_override,
    # alt_repeat_key, encoder_layout) untouched.

    with open(OUT, "w") as f:
        json.dump(v, f, indent=2)

    # Sanity report
    print(f"Wrote {OUT}")
    print(f"Layers: {len(v['layout'])}")
    for i, L in enumerate(v["layout"]):
        active = sum(1 for r in L for k in r if k != -1)
        print(f"  L{i}: {active} active keys")
    print(f"Combos: {len([c for c in v['combo'] if c[0] != 'KC_NO'])} active")
    print(f"\nLayer 0 base preview:")
    for r in v["layout"][0]:
        print("  " + " | ".join(f"{str(k):<22}" for k in r))


if __name__ == "__main__":
    main()
