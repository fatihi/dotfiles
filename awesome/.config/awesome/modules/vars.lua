-- Shared settings used by the other modules.
local vars = {}

vars.modkey     = "Mod4"  -- the "Windows" key
vars.terminal   = "wezterm"
vars.editor     = os.getenv("EDITOR") or os.getenv("VISUAL") or "vi"
vars.editor_cmd = vars.terminal .. " -e " .. vars.editor

-- Keyboard: German (US) = US layout, umlauts via AltGr (AltGr+a = ä, AltGr+s = ß)
vars.kbd_layout  = "de"
vars.kbd_variant = "us"

-- Screenshots taken with Shift+Print are saved here
vars.screenshot_dir = os.getenv("HOME") .. "/Pictures/Screenshots"

return vars
