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

-- Tray apps
run_once("nm-applet")
