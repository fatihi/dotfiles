-- Programs and settings applied at startup (also re-run on Mod4+Ctrl+r).
local awful = require("awful")
local vars  = require("modules.vars")

-- Start a program unless it is already running (survives awesome restarts)
local function run_once(cmd, process_name)
    process_name = process_name or cmd:match("^(%S+)")
    awful.spawn.with_shell(string.format(
        "pgrep -u \"$USER\" -x '%s' >/dev/null || exec %s", process_name, cmd))
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

-- Tray apps
run_once("nm-applet")
