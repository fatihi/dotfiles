-- Main menu (right-click on the desktop, Mod4+w) and the launcher icon in the bar.
local awful       = require("awful")
local beautiful   = require("beautiful")
local menubar     = require("menubar")
local freedesktop = require("freedesktop")
local gears       = require("gears")
local gfs         = require("gears.filesystem")
local cairo       = require("lgi").cairo
local GdkPixbuf   = require("lgi").GdkPixbuf
local vars        = require("modules.vars")
local power       = require("modules.power")

-- {{{ Icons for the Awesome and System submenus: Adwaita's symbolic icons, drawn
-- in the theme's text colour at the scaled size (see scaling.lua), so they stay
-- sharp and readable on the dark background. (The app entries use their own icons.)
local icon_size  = beautiful.xresources.apply_dpi(16)
local row_height = beautiful.menu_height or icon_size
local icon_dirs  = {}
for _, base in ipairs({ os.getenv("HOME") .. "/.local/share/icons", "/usr/share/icons" }) do
    for _, theme in ipairs({ beautiful.icon_theme or "Adwaita", "Adwaita" }) do
        table.insert(icon_dirs, base .. "/" .. theme .. "/symbolic/")
    end
end
local icon_categories = { "actions", "status", "categories", "apps", "devices", "places", "legacy" }

local function find_symbolic(name)
    for _, dir in ipairs(icon_dirs) do
        for _, category in ipairs(icon_categories) do
            local path = dir .. category .. "/" .. name .. "-symbolic.svg"
            if gfs.file_readable(path) then return path end
        end
    end
end

-- Returns a surface (icon centred in a square as tall as a menu row), or nil
local function lookup_icon(name)
    local path = find_symbolic(name)
    if not path then return nil end
    local pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(path, icon_size, icon_size)
    if not pixbuf then return nil end
    local icon = gears.surface(awesome.pixbuf_to_surface(pixbuf._native, path))
    gears.color.recolor_image(icon, beautiful.fg_normal)
    local canvas = cairo.ImageSurface(cairo.Format.ARGB32, row_height, row_height)
    local cr = cairo.Context(canvas)
    cr:set_source_surface(icon, math.floor((row_height - icon:get_width()) / 2),
                                math.floor((row_height - icon:get_height()) / 2))
    cr:paint()
    return canvas
end
-- }}}

-- Logout, reboot and shut down ask for confirmation (see power.lua)
local system_menu = {
    { "Lock Screen",     power.lock,     lookup_icon("system-lock-screen")   },
    { "Suspend",         power.suspend,  lookup_icon("weather-clear-night") },
    { "Logout",          power.logout,   lookup_icon("system-log-out")      },
    { "Reboot System",   power.reboot,   lookup_icon("system-reboot")       },
    { "Shutdown System", power.shutdown, lookup_icon("system-shutdown")     },
}

local awesome_menu = {
    { "Restart Awesome", awesome.restart, lookup_icon("view-refresh") },
    { "Edit config", vars.editor_cmd .. " " .. gfs.get_configuration_dir(),
      lookup_icon("document-edit") },
    { "Manual", vars.terminal .. " -e man awesome", lookup_icon("help-browser") },
}

menubar.utils.terminal = vars.terminal

local menu = {}

menu.main = freedesktop.menu.build({
    before = {
        { "Awesome", awesome_menu, beautiful.awesome_icon },
    },
    after = {
        { "System",   system_menu,   lookup_icon("preferences-system") },
        { "Terminal", vars.terminal, lookup_icon("utilities-terminal") },
    },
})

menu.launcher = awful.widget.launcher({ image = beautiful.opensuse_icon, menu = menu.main })

return menu
