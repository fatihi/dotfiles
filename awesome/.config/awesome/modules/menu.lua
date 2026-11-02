-- Main menu (right-click on the desktop, Mod4+w) and the launcher icon in the bar.
local awful       = require("awful")
local beautiful   = require("beautiful")
local menubar     = require("menubar")
local freedesktop = require("freedesktop")
local lgi         = require("lgi")
local gtk         = lgi.require("Gtk", "3.0")
local gfs         = require("gears.filesystem")
local vars        = require("modules.vars")
local power       = require("modules.power")

local function lookup_icon(icon, size)
    local icon_theme = gtk.IconTheme.get_default()
    local icon_info = icon_theme:lookup_icon(icon, size, "USE_BUILTIN")
    return icon_info and icon_info:get_filename() or nil
end

-- Logout, reboot and shut down ask for confirmation (see power.lua)
local system_menu = {
    { "Lock Screen",     power.lock,     lookup_icon("system-lock-screen", 16) },
    { "Suspend",         power.suspend,  lookup_icon("system-suspend", 16)     },
    { "Logout",          power.logout,   lookup_icon("system-log-out", 16)     },
    { "Reboot System",   power.reboot,   lookup_icon("system-restart", 16)     },
    { "Shutdown System", power.shutdown, lookup_icon("system-shutdown", 16)    },
}

local awesome_menu = {
    { "Restart Awesome", awesome.restart, lookup_icon("view-refresh", 16) },
    { "Edit config", vars.editor_cmd .. " " .. gfs.get_configuration_dir(),
      lookup_icon("package_settings", 16) },
    { "Manual", vars.terminal .. " -e man awesome", lookup_icon("help-browser", 16) },
}

menubar.utils.terminal = vars.terminal

local menu = {}

menu.main = freedesktop.menu.build({
    before = {
        { "Awesome", awesome_menu, beautiful.awesome_icon },
    },
    after = {
        { "System",   system_menu,   lookup_icon("preferences-system", 16) },
        { "Terminal", vars.terminal, lookup_icon("utilities-terminal", 16) },
    },
})

menu.launcher = awful.widget.launcher({ image = beautiful.opensuse_icon, menu = menu.main })

return menu
