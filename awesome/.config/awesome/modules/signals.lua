-- Reactions to window events: titlebars, focus, borders.
local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")

-- {{{ Titlebars only on floating windows and dialogs
local function is_floating(c)
    return c.floating or c.type == "dialog"
        or (c.first_tag and c.first_tag.layout == awful.layout.suit.floating)
end

local function update_titlebar(c)
    if c.requests_no_titlebar or c.fullscreen then return end
    if is_floating(c) and not c.maximized then
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
end

client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )
    awful.titlebar(c):setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal,
        },
        { -- Middle
            { align = "center", widget = awful.titlebar.widget.titlewidget(c) },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal,
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal(),
        },
        layout = wibox.layout.align.horizontal,
    }
end)

client.connect_signal("property::floating",  update_titlebar)
client.connect_signal("property::maximized", update_titlebar)

-- Switching a tag to/from the floating layout affects all its windows
tag.connect_signal("property::layout", function(t)
    for _, c in ipairs(t:clients()) do update_titlebar(c) end
end)
-- }}}

-- {{{ New windows
client.connect_signal("manage", function(c)
    -- Prevent windows from being unreachable after the screen count changes
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
    update_titlebar(c)
end)
-- }}}

-- {{{ Focus follows mouse, coloured border on the focused window
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
