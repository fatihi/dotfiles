-- Wallpaper, tags and the top bar for every screen.
local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local vars      = require("modules.vars")
local menu      = require("modules.menu")
local widgets   = require("modules.widgets")

local modkey = vars.modkey

local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local function client_menu_toggle_fn()
    local instance = nil
    return function()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

local tasklist_buttons = gears.table.join(
    awful.button({ }, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 3, client_menu_toggle_fn()),
    awful.button({ }, 4, function() awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- The systray only draws on the primary screen (and follows it when the primary
-- changes), so its separator is hidden on the other screens.
local function update_systray_separators()
    for s in screen do
        if s.systray_separator then s.systray_separator.visible = (s == screen.primary) end
    end
end
screen.connect_signal("primary_changed", update_systray_separators)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function() awful.layout.inc( 1) end),
        awful.button({ }, 3, function() awful.layout.inc(-1) end),
        awful.button({ }, 4, function() awful.layout.inc( 1) end),
        awful.button({ }, 5, function() awful.layout.inc(-1) end)
    ))

    -- Only tags with windows, plus the one being viewed (Mod4+1..9 still reach all nine)
    s.mytaglist  = awful.widget.taglist(s, awful.widget.taglist.filter.noempty, taglist_buttons)
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    s.systray_separator = wibox.widget.textbox(widgets.separator.text)
    s.systray_separator.visible = (s == screen.primary)

    local right = {
        layout = wibox.layout.fixed.horizontal,
        wibox.widget.systray(),
        s.systray_separator,
        widgets.volume.widget,
        widgets.separator,
        widgets.cpu,
    }
    if widgets.battery then  -- nil without a battery
        table.insert(right, widgets.separator)
        table.insert(right, widgets.battery)
    end
    table.insert(right, widgets.separator)
    table.insert(right, widgets.clock)
    table.insert(right, s.mylayoutbox)

    s.mywibox = awful.wibar({ position = "top", screen = s })
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left
            layout = wibox.layout.fixed.horizontal,
            menu.launcher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle
        right,
    }
end)
