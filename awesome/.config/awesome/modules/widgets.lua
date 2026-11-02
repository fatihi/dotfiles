-- Widgets shown on the right side of the bar, plus on-screen popups (OSD)
-- for volume and brightness.
local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local naughty   = require("naughty")
local vicious   = require("vicious")
local GLib      = require("lgi").GLib

local dpi = beautiful.xresources.apply_dpi

local colors = beautiful.dracula or {}
local widgets = {}

local function colored(text, color)
    if not color then return text end
    return string.format('<span foreground="%s">%s</span>', color, text)
end

-- "cpu 12%": dimmed name, then the value
local function label(name, value)
    return colored(name, colors.comment) .. " " .. value
end

-- {{{ OSD: one notification per kind that replaces itself, e.g. while holding a volume key
local osd_ids = {}

-- pct = nil shows only the title (e.g. "Microphone muted")
function widgets.osd(kind, title, pct)
    local text = title
    if pct then
        local filled = math.floor(math.min(pct, 100) / 5 + 0.5)
        text = string.format("%s  %d%%\n%s%s", title, pct,
            colored(string.rep("━", filled), colors.purple),
            colored(string.rep("━", 20 - filled), colors.selection))
    end
    local n = naughty.notify({
        text        = text,
        timeout     = 1.5,
        replaces_id = osd_ids[kind],
        position    = "top_middle",
    })
    if n then osd_ids[kind] = n.id end
end
-- }}}

-- Separator between widgets: a short vertical line with space on both sides.
-- new_separator() makes another one (a widget that is hidden on some screens
-- needs its own, see bar.lua).
function widgets.new_separator()
    return wibox.widget {
        widget       = wibox.widget.separator,
        orientation  = "vertical",
        forced_width = dpi(2 * beautiful.bar_padding + 1),
        span_ratio   = 0.5,
        thickness    = dpi(1),
        color        = colors.selection,
    }
end
widgets.separator = widgets.new_separator()

-- {{{ Clock (German format via LC_TIME) with a month calendar on click
widgets.clock = wibox.widget.textclock(
    colored("%a %d.%m.", colors.comment) .. " <b>%H:%M</b>")
widgets.calendar = awful.widget.calendar_popup.month({
    start_sunday  = false,
    long_weekdays = true,
    spacing       = dpi(4),
    style_month   = { border_color = colors.purple, border_width = dpi(2), padding = dpi(10) },
    style_header  = { fg_color = colors.purple, border_width = 0 },
    style_weekday = { fg_color = colors.comment, border_width = 0 },
    style_normal  = { border_width = 0 },
    style_focus   = { fg_color = colors.bg, bg_color = colors.purple, border_width = 0 },
})
widgets.calendar:attach(widgets.clock, "tr", { on_hover = false })
-- }}}

-- CPU usage
widgets.cpu = wibox.widget.textbox()
vicious.register(widgets.cpu, vicious.widgets.cpu, function(_, args)
    return label("cpu", args[1] .. "%")
end, 2)

-- {{{ Battery: red below 20%, yellow below 50%, green otherwise.
-- "+" = charging, "-" = discharging. Warns once at 10% and once at 5% while discharging.
-- widgets.battery is nil on machines without a battery (the bar then leaves it out).

-- First system battery in /sys/class/power_supply (BAT0, BAT1, CMB0, ...).
-- Skips device batteries such as a wireless mouse (scope = Device).
local function find_battery()
    local base = "/sys/class/power_supply/"
    local ok, dir = pcall(GLib.Dir.open, base, 0)
    if not ok or not dir then return nil end
    local function read(path)
        local f = io.open(path)
        if not f then return nil end
        local v = f:read("l")
        f:close()
        return v
    end
    local found
    for name in function() return dir:read_name() end do
        if read(base .. name .. "/type") == "Battery"
            and read(base .. name .. "/scope") ~= "Device" then
            found = name
            break
        end
    end
    -- No dir:close(): lgi closes it when garbage-collected, and closing it
    -- here as well frees it twice and crashes awesome.
    return found
end

local battery_name = find_battery()
local battery_warn_levels = { 10, 5 }
local battery_warned = {}

widgets.battery = battery_name and wibox.widget.textbox() or nil
if widgets.battery then vicious.register(widgets.battery, vicious.widgets.bat, function(_, args)
    local state, pct = args[1], args[2] or 0
    local time = args[3] ~= "N/A" and args[3] or nil  -- "hh:mm" left, unknown right after unplugging
    local discharging = state == "-"

    if discharging then
        for _, level in ipairs(battery_warn_levels) do
            if pct <= level and not battery_warned[level] then
                battery_warned[level] = true
                naughty.notify({
                    preset = naughty.config.presets.critical,
                    title  = "Battery low: " .. pct .. "%",
                    text   = "Plug in the charger" .. (time and " (" .. time .. "h left)." or "."),
                })
            end
        end
    elseif state == "+" or state == "↯" then  -- charging or full
        battery_warned = {}
    end

    local color = (pct < 20 and colors.red) or (pct < 50 and colors.yellow) or colors.green
    local value = (state == "+" and "+" or "") .. pct .. "%"
    if discharging and time then value = value .. " " .. time .. "h" end
    return label("bat", colored(value, color))
end, 10, battery_name) end
-- }}}

-- {{{ Volume (PipeWire via wpctl). Click: mute, scroll: change volume.
local volume_box = wibox.widget.textbox()
widgets.volume = { widget = volume_box }

-- Reads the current volume, updates the bar and, with show_osd, shows a popup
function widgets.volume.update(show_osd)
    awful.spawn.easy_async("wpctl get-volume @DEFAULT_AUDIO_SINK@", function(out)
        -- Output: "Volume: 0.40" or "Volume: 0.40 [MUTED]" (decimal may be "," in German locales)
        local int, frac = out:match("(%d+)[.,](%d+)")
        if not int then
            volume_box:set_markup(label("vol", "?"))
            return
        end
        local pct = math.floor(tonumber(int) * 100 + tonumber(frac) * 10 ^ (2 - #frac) + 0.5)
        local muted = out:find("MUTED") ~= nil
        if muted then
            volume_box:set_markup(label("vol", colored("muted", colors.comment)))
        else
            volume_box:set_markup(label("vol", pct .. "%"))
        end
        if show_osd then
            widgets.osd("volume", muted and "Volume (muted)" or "Volume", pct)
        end
    end)
end

-- Runs a wpctl command, then updates the bar and shows the popup
function widgets.volume.run(cmd)
    awful.spawn.easy_async(cmd, function() widgets.volume.update(true) end)
end

widgets.volume.cmd = {
    up        = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
    down      = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    mute      = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    mic_mute  = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
}

function widgets.volume.toggle_mic()
    awful.spawn.easy_async(widgets.volume.cmd.mic_mute, function()
        awful.spawn.easy_async("wpctl get-volume @DEFAULT_AUDIO_SOURCE@", function(out)
            widgets.osd("mic", out:find("MUTED") and "Microphone muted" or "Microphone on")
        end)
    end)
end

volume_box:buttons(gears.table.join(
    awful.button({ }, 1, function() widgets.volume.run(widgets.volume.cmd.mute) end),
    awful.button({ }, 4, function() widgets.volume.run(widgets.volume.cmd.up) end),
    awful.button({ }, 5, function() widgets.volume.run(widgets.volume.cmd.down) end)
))

-- Catch changes made elsewhere (e.g. pavucontrol, headphones plugged in):
-- `pactl subscribe` prints a line for every audio event. Events come in bursts,
-- so wait briefly and update once. Restarts itself if PipeWire restarts.
local volume_debounce = gears.timer({
    timeout = 0.1, single_shot = true, callback = function() widgets.volume.update() end,
})
local volume_watch_pid

local function watch_volume()
    volume_watch_pid = awful.spawn.with_line_callback("pactl subscribe", {
        stdout = function(line)
            -- "on sink #" but not "on sink-input #" (individual app streams)
            if line:find("on sink #", 1, true) or line:find("on server", 1, true) then
                volume_debounce:again()
            end
        end,
        exit = function()
            volume_watch_pid = nil
            gears.timer.start_new(3, function() watch_volume() return false end)
        end,
    })
    if type(volume_watch_pid) ~= "number" then volume_watch_pid = nil end
end

watch_volume()
widgets.volume.update()

-- Don't leave the watcher running after an awesome restart
awesome.connect_signal("exit", function()
    if volume_watch_pid then awesome.kill(volume_watch_pid, awesome.unix_signal.SIGTERM) end
end)
-- }}}

-- {{{ Brightness (brightnessctl). -n keeps the screen from going fully dark.
widgets.brightness = {}

function widgets.brightness.change(arg)
    awful.spawn.easy_async({ "brightnessctl", "-m", "-n", "set", arg }, function(out)
        -- Machine-readable output: "device,class,current,45%,max"
        local pct = tonumber(out:match(",(%d+)%%,"))
        if pct then widgets.osd("brightness", "Brightness", pct) end
    end)
end
-- }}}

return widgets
