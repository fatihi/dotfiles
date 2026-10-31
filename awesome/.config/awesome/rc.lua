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
-- Colours, fonts and gaps are in themes/theme.lua.

pcall(require, "luarocks.loader")

local awful     = require("awful")
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

-- {{{ Theme (must be loaded before the modules)
do
    local user_theme = awful.util.getdir("config") .. "/themes/theme.lua"
    local f = io.open(user_theme)
    if f then
        f:close()
        beautiful.init(user_theme)
    else
        beautiful.init(awful.util.get_themes_dir() .. "openSUSE/theme.lua")
    end
end
-- }}}

require("modules.layouts")
require("modules.bar")
require("modules.keys")
require("modules.rules")
require("modules.signals")
require("modules.autostart")
