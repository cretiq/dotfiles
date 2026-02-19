# Monokai color scheme for ranger
from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import Color, reverse, bold, normal

class Monokai(ColorScheme):
    progress_bar_color = 208

    def use(self, context):
        fg, bg, attr = context.keys

        if context.highlight:
            attr |= reverse

        if context.in_titlebar:
            fg = 231
            bg = 233

        elif context.in_statusbar:
            if context.permissions:
                fg = 148 if context.good else 196
            fg = 231

        if context.directory:
            fg = 81
        elif context.executable and not any((context.media, context.image, context.video, context.audio)):
            fg = 148
        elif context.link:
            fg = 208
        elif context.broken:
            fg = 196
        elif context.tag_marker and not context.selected:
            fg = 196
        elif any((context.image, context.video, context.audio)):
            fg = 228
        elif context.document and context.image_ext:
            fg = 228

        if context.selected:
            attr |= reverse
            fg = 231

        if context.empty or context.error:
            fg = 196

        if context.border:
            fg = 240

        if context.media:
            fg = 228

        if context.container:
            fg = 196

        return fg, bg, attr
