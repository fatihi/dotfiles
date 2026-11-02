-- Rules applied to new windows.
local awful     = require("awful")
local beautiful = require("beautiful")
local keys      = require("modules.keys")

awful.rules.rules = {
    -- All windows
    { rule = { },
      properties = {
          border_width = beautiful.border_width,
          border_color = beautiful.border_normal,
          focus        = awful.client.focus.filter,
          raise        = true,
          keys         = keys.client,
          buttons      = keys.client_buttons,
          screen       = awful.screen.preferred,
          placement    = awful.placement.no_overlap + awful.placement.no_offscreen,
      },
    },

    -- Windows that should always float, centred on the screen.
    -- Values are Lua patterns (case-sensitive, partial match): escape - . + * ? [ ] ^ $ ( ) % with %.
    { rule_any = {
        instance = {
            "pinentry",
        },
        class = {
            "Arandr",
            "Pavucontrol", "org%.pulseaudio%.pavucontrol",
            "Nm%-connection%-editor",
            "flameshot",
        },
        name = {
            "Event Tester",  -- xev
        },
        role = {
            "pop-up",        -- e.g. a browser's detached developer tools
        },
      }, properties = { floating = true,
                        placement = awful.placement.centered + awful.placement.no_offscreen } },

    -- Dialogs open in the middle of the screen
    { rule = { type = "dialog" },
      properties = { placement = awful.placement.centered + awful.placement.no_offscreen } },

    -- Create titlebars for normal windows and dialogs.
    -- signals.lua only shows them while a window is floating (or a dialog).
    { rule_any = { type = { "normal", "dialog" } },
      properties = { titlebars_enabled = true } },
}
