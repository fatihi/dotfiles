-- Dracula theme for awesome (https://draculatheme.com/contribute)
-- Reuses the icons of the openSUSE theme and only replaces the colours.
-- rc.lua loads this file automatically if it exists.

local gears = require("gears")

local theme = dofile("/usr/share/awesome/themes/openSUSE/theme.lua")

-- Dracula palette
local c = {
  bg        = "#282a36",
  bg_dark   = "#21222c",
  selection = "#44475a",
  fg        = "#f8f8f2",
  comment   = "#6272a4",
  cyan      = "#8be9fd",
  green     = "#50fa7b",
  orange    = "#ffb86c",
  pink      = "#ff79c6",
  purple    = "#bd93f9",
  red       = "#ff5555",
  yellow    = "#f1fa8c",
}
theme.dracula = c

theme.bg_normal   = c.bg
theme.bg_focus    = c.selection
theme.bg_urgent   = c.red
theme.bg_minimize = c.bg_dark
theme.bg_systray  = c.bg

theme.fg_normal   = c.fg
theme.fg_focus    = c.fg
theme.fg_urgent   = c.bg
theme.fg_minimize = c.comment

theme.border_normal = c.selection
theme.border_focus  = c.purple
theme.border_marked = c.pink

-- Current tag highlighted in purple
theme.taglist_bg_focus = c.purple
theme.taglist_fg_focus = c.bg

theme.titlebar_bg_normal = c.bg
theme.titlebar_bg_focus  = c.selection

theme.menu_bg_normal    = c.bg
theme.menu_bg_focus     = c.selection
theme.menu_border_color = c.purple

theme.tooltip_bg_color     = c.bg_dark
theme.tooltip_fg_color     = c.fg
theme.tooltip_border_color = c.purple

theme.hotkeys_bg           = c.bg
theme.hotkeys_fg           = c.fg
theme.hotkeys_border_color = c.purple
theme.hotkeys_modifiers_fg = c.comment

-- Solid Dracula background instead of the green openSUSE wallpaper
theme.wallpaper = function(s)
  return gears.surface.load_from_shape(
    s.geometry.width, s.geometry.height, gears.shape.rectangle, c.bg_dark)
end

return theme
