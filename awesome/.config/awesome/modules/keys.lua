-- Key and mouse bindings. Mod4+F1 lists them (searchable), Mod4+Shift+F1 as a popup.
local awful         = require("awful")
local gears         = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local vars          = require("modules.vars")
local menu          = require("modules.menu")
local widgets       = require("modules.widgets")
local power         = require("modules.power")
local scaling       = require("modules.scaling")
local gfs           = require("gears.filesystem")
local beautiful     = require("beautiful")
local keyhelp       = require("modules.keyhelp")

local modkey   = vars.modkey
local terminal = vars.terminal

local keys = {}

-- {{{ Mouse on the desktop
root.buttons(gears.table.join(
    awful.button({ }, 3, function() menu.main:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ SSH prompt: completes the host aliases from ~/.ssh/config
-- Only "Host" lines count (not "HostName"), so picking a host keeps its User, Port, ...
-- "Host a b" gives two entries; patterns (*, ?) and negations (!) are skipped.
local function ssh_hosts()
    local hosts, seen = {}, {}
    local f = io.open(os.getenv("HOME") .. "/.ssh/config")
    if not f then return hosts end
    for line in f:lines() do
        local names = line:gsub("#.*", ""):match("^%s*[Hh][Oo][Ss][Tt]%s*[%s=]%s*(.-)%s*$")
        for name in (names or ""):gmatch("%S+") do
            if not name:find("[*?!]") and not seen[name] then
                seen[name] = true
                table.insert(hosts, name)
            end
        end
    end
    f:close()
    table.sort(hosts)
    return hosts
end

local function ssh_prompt()
    awful.prompt.run {
        prompt       = "ssh: ",
        textbox      = awful.screen.focused().mypromptbox.widget,
        exe_callback = function(h) awful.spawn(terminal .. " -e ssh " .. h) end,
        completion_callback = function(cmd, cur_pos, ncomp)
            local hosts = ssh_hosts()
            if cur_pos ~= #cmd + 1 and cmd:sub(cur_pos, cur_pos) ~= " " then
                return cmd, cur_pos
            end
            local matches = {}
            local typed = cmd:sub(1, cur_pos - 1)
            for _, host in ipairs(hosts) do
                if host:sub(1, #typed) == typed then table.insert(matches, host) end
            end
            if #matches == 0 then return cmd, cur_pos end
            while ncomp > #matches do ncomp = ncomp - #matches end
            return matches[ncomp], #matches[ncomp] + 1
        end,
        history_path = gfs.get_cache_dir() .. "ssh_history",
    }
end
-- }}}

-- {{{ Move the focused window to the previous/next tag (wrapping around) and follow it
local function move_to_adjacent_tag(direction)
    local c = client.focus
    if not c or not c.first_tag then return end
    local tags = c.screen.tags
    local target = tags[(c.first_tag.index - 1 + direction) % #tags + 1]
    c:move_to_tag(target)
    target:view_only()
    client.focus = c
    c:raise()
end
-- }}}

-- {{{ Global keys
local globalkeys = gears.table.join(
    -- Awesome
    awful.key({ modkey }, "F1", keyhelp.show,
              { description = "search key bindings (Enter runs one)", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "F1", hotkeys_popup.show_help,
              { description = "show key bindings popup", group = "awesome" }),
    awful.key({ modkey }, "w", function() menu.main:show() end,
              { description = "show main menu", group = "awesome" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", power.menu,
              { description = "power menu (lock, suspend, logout, reboot, shut down)", group = "awesome" }),
    awful.key({ modkey, "Control" }, "Escape", power.lock,
              { description = "lock screen", group = "awesome" }),
    awful.key({ modkey }, "x", function()
        awful.prompt.run {
            prompt       = "Run Lua code: ",
            textbox      = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = gfs.get_cache_dir() .. "history_eval",
        }
    end, { description = "lua execute prompt", group = "awesome" }),

    -- Tags
    awful.key({ modkey }, "Left",   awful.tag.viewprev,
              { description = "view previous", group = "tag" }),
    awful.key({ modkey }, "Right",  awful.tag.viewnext,
              { description = "view next", group = "tag" }),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
              { description = "go back", group = "tag" }),
    awful.key({ modkey, "Shift" }, "Left",  function() move_to_adjacent_tag(-1) end,
              { description = "move focused client to previous tag and follow", group = "tag" }),
    awful.key({ modkey, "Shift" }, "Right", function() move_to_adjacent_tag( 1) end,
              { description = "move focused client to next tag and follow", group = "tag" }),

    -- Client focus and order
    -- Focus/swap by direction (h/j/k/l = left/down/up/right) are added below the table
    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
              { description = "jump to urgent client", group = "client" }),
    awful.key({ modkey }, "Tab", function()
        awful.client.focus.history.previous()
        if client.focus then client.focus:raise() end
    end, { description = "go back", group = "client" }),
    awful.key({ modkey, "Shift" }, "Tab", function() awful.spawn(scaling.rofi("-show window")) end,
              { description = "switch to any window (rofi)", group = "client" }),
    awful.key({ modkey, "Control" }, "n", function()
        local c = awful.client.restore()
        if c then
            client.focus = c
            c:raise()
        end
    end, { description = "restore minimized", group = "client" }),

    -- Screens
    awful.key({ modkey, "Control" }, "j", function() awful.screen.focus_relative( 1) end,
              { description = "focus the next screen", group = "screen" }),
    awful.key({ modkey, "Control" }, "k", function() awful.screen.focus_relative(-1) end,
              { description = "focus the previous screen", group = "screen" }),

    -- Layout
    -- Master width: Mod4+Alt+h/l (resize keys, client group)
    awful.key({ modkey, "Control", "Shift" }, "h", function() awful.tag.incnmaster( 1, nil, true) end,
              { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control", "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
              { description = "decrease the number of master clients", group = "layout" }),
    awful.key({ modkey, "Control" }, "h", function() awful.tag.incncol( 1, nil, true) end,
              { description = "increase the number of columns", group = "layout" }),
    awful.key({ modkey, "Control" }, "l", function() awful.tag.incncol(-1, nil, true) end,
              { description = "decrease the number of columns", group = "layout" }),
    awful.key({ modkey }, "space", function() awful.layout.inc( 1) end,
              { description = "select next", group = "layout" }),
    awful.key({ modkey, "Shift" }, "space", function() awful.layout.inc(-1) end,
              { description = "select previous", group = "layout" }),

    -- Launchers
    awful.key({ modkey }, "Return", function() awful.spawn(terminal) end,
              { description = "open a terminal", group = "launcher" }),
    awful.key({ modkey }, "p", function() awful.spawn(scaling.rofi("-show drun")) end,
              { description = "app launcher (rofi)", group = "launcher" }),
    awful.key({ modkey, "Shift" }, "p", function() awful.spawn(scaling.rofi("-show run")) end,
              { description = "run command (rofi)", group = "launcher" }),
    awful.key({ modkey }, "r", function() awful.screen.focused().mypromptbox:run() end,
              { description = "run prompt", group = "launcher" }),
    awful.key({ modkey }, "s", ssh_prompt,
              { description = "ssh login", group = "launcher" }),

    -- Volume
    awful.key({ }, "XF86AudioRaiseVolume", function() widgets.volume.run(widgets.volume.cmd.up) end,
              { description = "volume up", group = "media" }),
    awful.key({ }, "XF86AudioLowerVolume", function() widgets.volume.run(widgets.volume.cmd.down) end,
              { description = "volume down", group = "media" }),
    awful.key({ }, "XF86AudioMute", function() widgets.volume.run(widgets.volume.cmd.mute) end,
              { description = "toggle mute", group = "media" }),
    awful.key({ }, "XF86AudioMicMute", widgets.volume.toggle_mic,
              { description = "toggle microphone mute", group = "media" }),

    -- Media players (any app that supports MPRIS: browsers, Spotify, mpv, ...)
    awful.key({ }, "XF86AudioPlay",  function() awful.spawn("playerctl play-pause") end,
              { description = "play/pause", group = "media" }),
    awful.key({ }, "XF86AudioPause", function() awful.spawn("playerctl pause") end,
              { description = "pause", group = "media" }),
    awful.key({ }, "XF86AudioStop",  function() awful.spawn("playerctl stop") end,
              { description = "stop", group = "media" }),
    awful.key({ }, "XF86AudioNext",  function() awful.spawn("playerctl next") end,
              { description = "next track", group = "media" }),
    awful.key({ }, "XF86AudioPrev",  function() awful.spawn("playerctl previous") end,
              { description = "previous track", group = "media" }),

    -- Brightness
    awful.key({ }, "XF86MonBrightnessUp",   function() widgets.brightness.change("5%+") end,
              { description = "brightness up", group = "media" }),
    awful.key({ }, "XF86MonBrightnessDown", function() widgets.brightness.change("5%-") end,
              { description = "brightness down", group = "media" }),

    -- Monitors (autorandr profiles, see README)
    awful.key({ }, "XF86Display", function() awful.spawn("autorandr --cycle") end,
              { description = "next monitor profile (autorandr)", group = "screen" }),
    awful.key({ modkey, "Shift" }, "o", function() awful.spawn("autorandr --change --force") end,
              { description = "re-apply matching monitor profile (autorandr)", group = "screen" }),

    -- Screenshots
    awful.key({ }, "Print", function() awful.spawn("flameshot gui") end,
              { description = "screenshot: select area", group = "screenshot" }),
    awful.key({ "Shift" }, "Print", function()
        awful.spawn.with_shell(string.format("mkdir -p '%s' && flameshot full -c -p '%s'",
            vars.screenshot_dir, vars.screenshot_dir))
    end, { description = "screenshot: whole screen (saved + clipboard)", group = "screenshot" })
)

-- Mod4+h/j/k/l: focus the window to the left/below/above/to the right (crosses to
-- another monitor at the screen edge). +Shift: swap with that window.
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, key, function()
            awful.client.focus.global_bydirection(dir)
            if client.focus then client.focus:raise() end
        end, { description = "focus " .. dir, group = "client" }),
        awful.key({ modkey, "Shift" }, key, function()
            awful.client.swap.global_bydirection(dir)
        end, { description = "swap with the window " .. (dir == "left" and "to the left"
            or dir == "right" and "to the right" or dir == "up" and "above" or "below"),
            group = "client" })
    )
end

-- Do not disturb: hold back notifications (shown when turned off again)
globalkeys = gears.table.join(globalkeys,
    awful.key({ modkey, "Shift" }, "d", widgets.dnd.toggle,
              { description = "toggle do not disturb", group = "awesome" }))

-- Mod4+1..9: view tag, +Ctrl: toggle tag, +Shift: move window, +Ctrl+Shift: toggle window on tag.
-- Keycodes (#10..#18) keep this working on any keyboard layout.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function()
            local tag = awful.screen.focused().tags[i]
            if tag then tag:view_only() end
        end, { description = "view tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Control" }, "#" .. i + 9, function()
            local tag = awful.screen.focused().tags[i]
            if tag then awful.tag.viewtoggle(tag) end
        end, { description = "toggle tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end, { description = "move focused client to tag #" .. i, group = "tag" }),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:toggle_tag(tag) end
            end
        end, { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

root.keys(globalkeys)
-- }}}

-- {{{ Client keys and buttons (applied through rules.lua)

-- Resize the focused window from the keyboard (Mod4+Alt+h/j/k/l).
--   Floating: h/l = narrower/wider, k/j = shorter/taller, in steps scaled for the screen.
--   Tiled:    h/l = narrower/wider, k/j = shorter/taller, by moving the main split
--             (the key along the split's direction) or the window's share of its stack.
local resize_step_px     = 40  -- at 96 DPI
local resize_step_factor = 0.05

local function resize(c, key)
    local floating = c.floating
        or awful.layout.get(c.screen) == awful.layout.suit.floating
    if floating then
        local step = beautiful.xresources.apply_dpi(resize_step_px, c.screen)
        local dw, dh = 0, 0
        if key == "h" then dw = -step
        elseif key == "l" then dw = step
        elseif key == "k" then dh = -step
        elseif key == "j" then dh = step end
        c:relative_move(0, 0, dw, dh)
    else
        -- tile/tile.left split left|right (h/l move it); tile.bottom/tile.top split
        -- top|bottom (k/j move it). The other pair resizes the window within its stack.
        local layout = awful.layout.get(c.screen)
        local split_is_vertical = layout == awful.layout.suit.tile.bottom
            or layout == awful.layout.suit.tile.top
        local along_split = split_is_vertical == (key == "k" or key == "j")
        local grow = key == "l" or key == "j"
        local delta = grow and resize_step_factor or -resize_step_factor
        if along_split then
            -- Column 0 is the main area: growing it means a bigger main factor,
            -- growing a window in the stack means a smaller one.
            local idx = awful.client.idx(c)
            local in_main = idx and idx.col == 0
            awful.tag.incmwfact(in_main and delta or -delta)
        else
            awful.client.incwfact(delta, c)
        end
    end
end

-- Bindings created from here on act on a window; keyhelp passes them client.focus
local first_client_key = #awful.key.hotkeys + 1

local resize_keys = {}
for key, description in pairs({ h = "narrower", l = "wider", k = "shorter", j = "taller" }) do
    resize_keys = gears.table.join(resize_keys,
        awful.key({ modkey, "Mod1" }, key, function(c) resize(c, key) end,
                  { description = "resize window: " .. description, group = "client" }))
end

keys.client = gears.table.join(resize_keys,
    awful.key({ modkey }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, { description = "toggle fullscreen", group = "client" }),
    awful.key({ modkey, "Shift" }, "c", function(c) c:kill() end,
              { description = "close", group = "client" }),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle,
              { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Control" }, "Return", function(c) c:swap(awful.client.getmaster()) end,
              { description = "move to master", group = "client" }),
    awful.key({ modkey }, "o", function(c) c:move_to_screen() end,
              { description = "move to screen", group = "client" }),
    awful.key({ modkey }, "t", function(c) c.ontop = not c.ontop end,
              { description = "toggle keep on top", group = "client" }),
    awful.key({ modkey }, "n", function(c) c.minimized = true end,
              { description = "minimize", group = "client" }),
    awful.key({ modkey }, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, { description = "maximize", group = "client" })
)

for i = first_client_key, #awful.key.hotkeys do
    awful.key.hotkeys[i].client_key = true
end

keys.client_buttons = gears.table.join(
    awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize),
    -- Touchpad-friendly resize: tap-and-drag holds the left button
    awful.button({ modkey, "Shift" }, 1, awful.mouse.client.resize)
)
-- }}}

return keys
