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

-- Icons for menus and the launcher
theme.icon_theme = "Adwaita"

-- Gaps between tiled windows, slightly thicker border to show focus
theme.useless_gap   = 4
theme.border_width  = 2

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

-- {{{ Titlebar buttons: Dracula-coloured dots drawn in code (no image files)
-- Focused window: filled dot = on, ring = off. Unfocused window: grey.
-- Hovering a button shows it in the foreground colour.
local cairo = require("lgi").cairo

local function dot(color, ring)
  local size = 64
  local surface = cairo.ImageSurface.create(cairo.Format.ARGB32, size, size)
  local cr = cairo.Context(surface)
  cr:set_source(gears.color(color))
  cr:arc(size / 2, size / 2, size * 0.25, 0, 2 * math.pi)
  if ring then
    cr:set_line_width(size * 0.08)
    cr:stroke()
  else
    cr:fill()
  end
  return surface
end

-- Close button (no on/off state)
theme.titlebar_close_button_focus        = dot(c.red)
theme.titlebar_close_button_normal       = dot(c.comment)
theme.titlebar_close_button_focus_hover  = dot(c.fg)
theme.titlebar_close_button_normal_hover = dot(c.fg)

-- Toggle buttons
local toggles = {
  floating  = c.purple,
  maximized = c.green,
  ontop     = c.yellow,
  sticky    = c.cyan,
}
for name, color in pairs(toggles) do
  local prefix = "titlebar_" .. name .. "_button_"
  theme[prefix .. "focus_active"]          = dot(color)
  theme[prefix .. "focus_inactive"]        = dot(color, true)
  theme[prefix .. "normal_active"]         = dot(c.comment)
  theme[prefix .. "normal_inactive"]       = dot(c.comment, true)
  theme[prefix .. "focus_active_hover"]    = dot(c.fg)
  theme[prefix .. "focus_inactive_hover"]  = dot(c.fg, true)
  theme[prefix .. "normal_active_hover"]   = dot(c.fg)
  theme[prefix .. "normal_inactive_hover"] = dot(c.fg, true)
end
-- }}}

-- Solid Dracula background instead of the green openSUSE wallpaper
theme.wallpaper = function(s)
  return gears.surface.load_from_shape(
    s.geometry.width, s.geometry.height, gears.shape.rectangle, c.bg_dark)
end

return theme
