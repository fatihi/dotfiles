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

    -- Windows that should always float
    { rule_any = {
        instance = {
            "DTA",     -- Firefox addon DownThemAll.
            "copyq",   -- Includes session name in class.
        },
        class = {
            "Arandr",
            "Gpick",
            "Kruler",
            "MessageWin",  -- kalarm.
            "Sxiv",
            "Wpa_gui",
            "pinentry",
            "veromix",
            "xtightvncviewer",
            "flameshot",
        },
        name = {
            "Event Tester",  -- xev.
        },
        role = {
            "AlarmWindow",   -- Thunderbird's calendar.
            "ConfigManager", -- Thunderbird's about:config.
            "pop-up",        -- e.g. Google Chrome's (detached) Developer Tools.
        },
      }, properties = { floating = true } },

    -- Create titlebars for normal windows and dialogs.
    -- signals.lua only shows them while a window is floating (or a dialog).
    { rule_any = { type = { "normal", "dialog" } },
      properties = { titlebars_enabled = true } },
}
