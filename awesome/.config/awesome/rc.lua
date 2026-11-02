-- awesome configuration. The actual setup lives in modules/:
--   vars.lua       shared settings (terminal, modkey, keyboard layout)
--   layouts.lua    available layouts
--   menu.lua       main menu and launcher icon
--   widgets.lua    clock/calendar, volume, cpu, battery
--   bar.lua        wallpaper, tags and the top bar
--   keys.lua       key and mouse bindings (Mod4+F1 lists them)
--   rules.lua      rules for new windows
--   signals.lua    titlebars, focus, borders
--   autostart.lua  keyboard layout and tray apps
--   scaling.lua    size of awesome's UI per screen (DPI)
-- Colours, fonts, sizes and gaps are in themes/theme.lua.

pcall(require, "luarocks.loader")

local awful     = require("awful")
local gfs       = require("gears.filesystem")
local beautiful = require("beautiful")
local naughty   = require("naughty")
require("awful.autofocus")

-- {{{ Error handling: show errors as notifications
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Theme (must be loaded before the modules; the DPI before the theme)
require("modules.scaling").init()
local dpi = beautiful.xresources.apply_dpi

do
    local user_theme = gfs.get_configuration_dir() .. "themes/theme.lua"
    local f = io.open(user_theme)
    if f then
        f:close()
        beautiful.init(user_theme)
    else
        beautiful.init(gfs.get_themes_dir() .. "openSUSE/theme.lua")
    end
end
-- }}}

-- {{{ Notifications: spacing and the critical style (colours/border are in the theme)
naughty.config.padding = dpi(10)  -- distance from the screen edge
naughty.config.spacing = dpi(6)   -- distance between notifications
naughty.config.defaults.margin       = dpi(12)
naughty.config.defaults.border_width = dpi(2)
naughty.config.defaults.icon_size    = dpi(48)
if beautiful.dracula then
    naughty.config.presets.critical.bg = beautiful.dracula.red
    naughty.config.presets.critical.fg = beautiful.dracula.bg
    naughty.config.presets.critical.border_color = beautiful.dracula.red
end
-- }}}

require("modules.layouts")
require("modules.bar")
require("modules.keys")
require("modules.rules")
require("modules.signals")
require("modules.autostart")
