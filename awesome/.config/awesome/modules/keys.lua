-- Key and mouse bindings. Mod4+F1 shows all of them.
local awful         = require("awful")
local gears         = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local vars          = require("modules.vars")
local menu          = require("modules.menu")
local widgets       = require("modules.widgets")

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

-- {{{ SSH prompt: completes host names from ~/.ssh/config
local function ssh_prompt()
    awful.prompt.run {
        prompt       = "ssh: ",
        textbox      = awful.screen.focused().mypromptbox.widget,
        exe_callback = function(h) awful.spawn(terminal .. " -e ssh " .. h) end,
        completion_callback = function(cmd, cur_pos, ncomp)
            local hosts = {}
            local f = io.popen("sed 's/#.*//;/[ \\t]*Host\\(Name\\)\\?[ \\t]\\+/!d;s///;/[*?]/d' "
                .. os.getenv("HOME") .. "/.ssh/config 2>/dev/null | sort")
            for host in f:lines() do table.insert(hosts, host) end
            f:close()
            if cur_pos ~= #cmd + 1 and cmd:sub(cur_pos, cur_pos) ~= " " then
                return cmd, cur_pos
            end
            local matches = {}
            local prefix = "^" .. cmd:sub(1, cur_pos):gsub("[-]", "[-]")
            for _, host in ipairs(hosts) do
                if host:find(prefix) then table.insert(matches, host) end
            end
            if #matches == 0 then return cmd, cur_pos end
            while ncomp > #matches do ncomp = ncomp - #matches end
            return matches[ncomp], #matches[ncomp] + 1
        end,
        history_path = awful.util.get_cache_dir() .. "/ssh_history",
    }
end
-- }}}

-- {{{ Global keys
local globalkeys = gears.table.join(
    -- Awesome
    awful.key({ modkey }, "F1", hotkeys_popup.show_help,
              { description = "show help", group = "awesome" }),
    awful.key({ modkey }, "w", function() menu.main:show() end,
              { description = "show main menu", group = "awesome" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
              { description = "quit awesome", group = "awesome" }),
    awful.key({ modkey }, "x", function()
        awful.prompt.run {
            prompt       = "Run Lua code: ",
            textbox      = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval",
        }
    end, { description = "lua execute prompt", group = "awesome" }),

    -- Tags
    awful.key({ modkey }, "Left",   awful.tag.viewprev,
              { description = "view previous", group = "tag" }),
    awful.key({ modkey }, "Right",  awful.tag.viewnext,
              { description = "view next", group = "tag" }),
    awful.key({ modkey }, "Escape", awful.tag.history.restore,
              { description = "go back", group = "tag" }),

    -- Client focus and order
    awful.key({ modkey }, "j", function() awful.client.focus.byidx( 1) end,
              { description = "focus next by index", group = "client" }),
    awful.key({ modkey }, "k", function() awful.client.focus.byidx(-1) end,
              { description = "focus previous by index", group = "client" }),
    awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.byidx( 1) end,
              { description = "swap with next client by index", group = "client" }),
    awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.byidx(-1) end,
              { description = "swap with previous client by index", group = "client" }),
    awful.key({ modkey }, "u", awful.client.urgent.jumpto,
              { description = "jump to urgent client", group = "client" }),
    awful.key({ modkey }, "Tab", function()
        awful.client.focus.history.previous()
        if client.focus then client.focus:raise() end
    end, { description = "go back", group = "client" }),
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
    awful.key({ modkey }, "l", function() awful.tag.incmwfact( 0.05) end,
              { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey }, "h", function() awful.tag.incmwfact(-0.05) end,
              { description = "decrease master width factor", group = "layout" }),
    awful.key({ modkey, "Shift" }, "h", function() awful.tag.incnmaster( 1, nil, true) end,
              { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Shift" }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
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
    awful.key({ modkey }, "p", function() awful.spawn("rofi -show drun") end,
              { description = "app launcher (rofi)", group = "launcher" }),
    awful.key({ modkey, "Shift" }, "p", function() awful.spawn("rofi -show run") end,
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
    awful.key({ }, "XF86AudioMicMute", function() awful.spawn(widgets.volume.cmd.mic_mute) end,
              { description = "toggle microphone mute", group = "media" }),

    -- Brightness (-n keeps the screen from going fully dark)
    awful.key({ }, "XF86MonBrightnessUp", function() awful.spawn("brightnessctl -q set 5%+") end,
              { description = "brightness up", group = "media" }),
    awful.key({ }, "XF86MonBrightnessDown", function() awful.spawn("brightnessctl -q -n set 5%-") end,
              { description = "brightness down", group = "media" }),

    -- Screenshots
    awful.key({ }, "Print", function() awful.spawn("flameshot gui") end,
              { description = "screenshot: select area", group = "screenshot" }),
    awful.key({ "Shift" }, "Print", function()
        awful.spawn.with_shell(string.format("mkdir -p '%s' && flameshot full -c -p '%s'",
            vars.screenshot_dir, vars.screenshot_dir))
    end, { description = "screenshot: whole screen (saved + clipboard)", group = "screenshot" })
)

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
keys.client = gears.table.join(
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

keys.client_buttons = gears.table.join(
    awful.button({ }, 1, function(c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)
-- }}}

return keys
