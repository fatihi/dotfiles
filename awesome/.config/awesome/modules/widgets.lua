-- Widgets shown on the right side of the bar.
local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local vicious   = require("vicious")

local colors = beautiful.dracula or {}
local widgets = {}

local function colored(text, color)
    if not color then return text end
    return string.format('<span foreground="%s">%s</span>', color, text)
end

-- Separator between widgets
widgets.separator = wibox.widget.textbox(" | ")

-- Clock (German format via LC_TIME) with a month calendar on click
widgets.clock = wibox.widget.textclock(" %a %d.%m. %H:%M ")
widgets.calendar = awful.widget.calendar_popup.month({
    start_sunday  = false,
    long_weekdays = true,
    style_month   = { border_color = colors.purple, border_width = 2, padding = 8 },
    style_header  = { fg_color = colors.purple, border_width = 0 },
    style_weekday = { fg_color = colors.comment, border_width = 0 },
    style_normal  = { border_width = 0 },
    style_focus   = { fg_color = colors.bg, bg_color = colors.purple, border_width = 0 },
})
widgets.calendar:attach(widgets.clock, "tr", { on_hover = false })

-- CPU usage
widgets.cpu = wibox.widget.textbox()
vicious.register(widgets.cpu, vicious.widgets.cpu, "cpu: $1%", 2)

-- Battery: red below 20%, yellow below 50%, green otherwise
widgets.battery = wibox.widget.textbox()
vicious.register(widgets.battery, function(format, warg)
    local args = vicious.widgets.bat(format, warg)
    local pct = args[2] or 0
    if pct < 20 then
        args["{color}"] = colors.red or "red"
    elseif pct < 50 then
        args["{color}"] = colors.yellow or "yellow"
    else
        args["{color}"] = colors.green or "green"
    end
    return args
end, '<span foreground="${color}">bat: $2% $3h</span>', 10, "BAT0")

-- Volume (PipeWire via wpctl). Click: mute, scroll: change volume.
local volume_box = wibox.widget.textbox()
widgets.volume = { widget = volume_box }

function widgets.volume.update()
    awful.spawn.easy_async("wpctl get-volume @DEFAULT_AUDIO_SINK@", function(out)
        -- Output: "Volume: 0.40" or "Volume: 0.40 [MUTED]" (decimal may be "," in German locales)
        local int, frac = out:match("(%d+)[.,](%d+)")
        if not int then
            volume_box:set_markup("vol: ?")
            return
        end
        local pct = math.floor(tonumber(int) * 100 + tonumber(frac) * 10 ^ (2 - #frac) + 0.5)
        if out:find("MUTED") then
            volume_box:set_markup(colored("vol: muted", colors.comment))
        else
            volume_box:set_markup("vol: " .. pct .. "%")
        end
    end)
end

function widgets.volume.run(cmd)
    awful.spawn.easy_async(cmd, function() widgets.volume.update() end)
end

widgets.volume.cmd = {
    up        = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
    down      = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    mute      = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    mic_mute  = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
}

volume_box:buttons(gears.table.join(
    awful.button({ }, 1, function() widgets.volume.run(widgets.volume.cmd.mute) end),
    awful.button({ }, 4, function() widgets.volume.run(widgets.volume.cmd.up) end),
    awful.button({ }, 5, function() widgets.volume.run(widgets.volume.cmd.down) end)
))

-- Catch changes made elsewhere (e.g. pavucontrol) every few seconds
gears.timer({ timeout = 5, autostart = true, call_now = true, callback = widgets.volume.update })

return widgets
