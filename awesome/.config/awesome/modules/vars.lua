-- Shared settings used by the other modules.
local vars = {}

vars.modkey     = "Mod4"  -- the "Windows" key
vars.terminal   = "wezterm"
vars.editor     = os.getenv("EDITOR") or os.getenv("VISUAL") or "vi"
vars.editor_cmd = vars.terminal .. " -e " .. vars.editor

-- Keyboard: German (US) = US layout, umlauts via AltGr (AltGr+a = ä, AltGr+s = ß)
vars.kbd_layout  = "de"
vars.kbd_variant = "us"

-- Lock screen: light-locker hands over to the LightDM greeter
vars.lock_cmd = "light-locker-command --lock"

-- Idle: blank the screen after 5 min, lock 10 s later, monitor off after 10 min
vars.idle_blank_seconds = 300
vars.idle_lock_delay    = 10
vars.idle_off_seconds   = 600

-- Screenshots taken with Shift+Print are saved here
vars.screenshot_dir = os.getenv("HOME") .. "/Pictures/Screenshots"

return vars
