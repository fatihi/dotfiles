-- Layouts cycled with Mod4+Space. The first one is the default for every tag.
local awful = require("awful")

awful.layout.layouts = {
    awful.layout.suit.tile,         -- master on the left, others stacked on the right
    awful.layout.suit.tile.bottom,  -- master on top, others side by side below
    awful.layout.suit.max,          -- one window fills the screen
    awful.layout.suit.floating,     -- free placement
}
