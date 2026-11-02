-- Wallpaper, tags and the top bar for every screen.
local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local vars      = require("modules.vars")
local menu      = require("modules.menu")
local widgets   = require("modules.widgets")
local scaling   = require("modules.scaling")

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
            instance = awful.menu.clients({ theme = { width = beautiful.xresources.apply_dpi(300) } })
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
    -- Sizes in this function are scaled for this screen (see scaling.lua)
    scaling.apply(s)
    local function sdpi(v) return beautiful.xresources.apply_dpi(v, s) end
    local pad = sdpi(beautiful.bar_padding or 8)

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

    -- Only tags with windows, plus the one being viewed (Mod4+1..9 still reach all nine).
    -- Each tag is a padded block; the background colour comes from the theme.
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.noempty,
        buttons = taglist_buttons,
        widget_template = {
            {
                { id = "text_role", widget = wibox.widget.textbox },
                left = sdpi(9), right = sdpi(9),
                widget = wibox.container.margin,
            },
            id     = "background_role",
            widget = wibox.container.background,
        },
    }

    -- Window list: icon and title with some room around them
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        -- Each task at most this wide, so a few windows don't fill the whole bar
        -- with long titles (they get cut off with "...")
        layout  = {
            layout          = wibox.layout.flex.horizontal,
            max_widget_size = sdpi(300),
            spacing         = beautiful.tasklist_spacing,
        },
        widget_template = {
            {
                {
                    {
                        { id = "icon_role", widget = wibox.widget.imagebox },
                        margins = sdpi(4),
                        widget  = wibox.container.margin,
                    },
                    { id = "text_role", widget = wibox.widget.textbox },
                    spacing = sdpi(2),
                    layout  = wibox.layout.fixed.horizontal,
                },
                left = sdpi(6), right = sdpi(10),
                widget = wibox.container.margin,
            },
            id     = "background_role",
            widget = wibox.container.background,
        },
    }

    s.systray_separator = widgets.new_separator()
    s.systray_separator.visible = (s == screen.primary)

    local right = {
        layout = wibox.layout.fixed.horizontal,
        { wibox.widget.systray(), top = sdpi(4), bottom = sdpi(4),
          widget = wibox.container.margin },
        s.systray_separator,
        widgets.dnd.widget,
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
    table.insert(right, { s.mylayoutbox, left = pad, top = sdpi(5), bottom = sdpi(5),
                          widget = wibox.container.margin })

    s.mywibox = awful.wibar({ position = "top", screen = s,
                              height = sdpi(beautiful.bar_height or 26) })
    s.mywibox:setup {
        {
            { -- Left
                { menu.launcher, top = sdpi(4), bottom = sdpi(4), right = pad,
                  widget = wibox.container.margin },
                s.mytaglist,
                { s.mypromptbox, left = pad, widget = wibox.container.margin },
                layout = wibox.layout.fixed.horizontal,
            },
            { s.mytasklist, left = pad, right = pad, widget = wibox.container.margin },
            right,
            layout = wibox.layout.align.horizontal,
        },
        left = pad, right = pad,
        widget = wibox.container.margin,
    }
end)
