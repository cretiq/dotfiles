# Dracula color scheme for ranger
from ranger.gui.colorscheme import ColorScheme
from ranger.gui.color import Color, reverse, bold, normal

class Dracula(ColorScheme):
    progress_bar_color = 50

    def use(self, context):
        fg, bg, attr = context.keys

        if context.highlight:
            attr |= reverse

        if context.in_titlebar:
            fg = 15
            bg = 8

        elif context.in_statusbar:
            if context.permissions:
                fg = 11 if context.good else 1
            fg = 15

        if context.directory:
            fg = 4
        elif context.executable and not any((context.Media, context.Image, context.Video, context.Audio)):
            fg = 2
        elif context.link:
            fg = 5
        elif context.broken:
            fg = 1
        elif context.tag_marker and not context.selected:
            fg = 1
        elif any((context.image, context.video, context.audio)):
            fg = 3
        elif context.document and context.image_ext:
            fg = 3

        if context.selected:
            attr |= reverse
            fg = 15

        if context.empty or context.error:
            fg = 1

        if context.border:
            fg = 8

        if context.media:
            fg = 3

        if context.container:
            fg = 1

        return fg, bg, attr
