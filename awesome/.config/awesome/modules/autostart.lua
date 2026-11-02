-- Programs and settings applied at startup (also re-run on Mod4+Ctrl+r).
local awful = require("awful")
local gfs   = require("gears.filesystem")
local vars  = require("modules.vars")

-- Start a program unless it is already running (survives awesome restarts).
-- pgrep -x compares against the kernel's process name, which is cut to 15 characters.
local function run_once(cmd, process_name)
    process_name = process_name or cmd:match("^(%S+)"):match("[^/]+$")
    awful.spawn.with_shell(string.format(
        "pgrep -u \"$USER\" -x '%s' >/dev/null || exec %s", process_name:sub(1, 15), cmd))
end

-- Keyboard layout
awful.spawn({ "setxkbmap", "-layout", vars.kbd_layout, "-variant", vars.kbd_variant }, false)

-- Idle timers (X screensaver = blank screen, DPMS = monitor off)
awful.spawn({ "xset", "s", tostring(vars.idle_blank_seconds), tostring(vars.idle_blank_seconds) }, false)
awful.spawn({ "xset", "dpms", tostring(vars.idle_off_seconds),
              tostring(vars.idle_off_seconds), tostring(vars.idle_off_seconds) }, false)

-- Screen locker: locks when idle, on suspend and on lid close.
-- Restart it after changing these flags: pkill light-locker, then Mod4+Ctrl+r.
run_once(string.format("light-locker --lock-after-screensaver=%d --lock-on-suspend --lock-on-lid",
    vars.idle_lock_delay), "light-locker")

-- Compositor (vsync, shadows, fades). Config: ~/.config/picom/picom.conf
run_once("picom")

-- Polkit agent: password prompt when an app needs admin rights (YaST, GParted, ...)
for _, agent in ipairs({
    "/usr/libexec/polkit-gnome-authentication-agent-1",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
}) do
    if gfs.file_executable(agent) then
        run_once(agent)
        break
    end
end

-- Tray apps
run_once("nm-applet")
