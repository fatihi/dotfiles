-- Size of awesome's own UI (bar, menus, popups, titlebars) per screen.
-- X reports 96 DPI for every screen, which makes everything tiny on a dense
-- laptop panel. This measures each screen's real DPI from its physical size and
-- rounds it to a fixed step, so text and sizes look the same on every screen.
-- Only awesome is affected; apps (terminal, browser, ...) keep their own sizes.
local beautiful = require("beautiful")

local scaling = {}

-- Physical DPI -> DPI used by awesome. 96 = 1x, 120 = 1.25x, 144 = 1.5x.
-- To make everything bigger or smaller, move a screen into another step.
--   24" 4K (~185)                       -> 144
--   14" 1920x1200 laptop (~160), 27" 4K -> 120
--   27" 1440p (~110), 24" 1080p         -> 96
local steps = {
    { min = 175, dpi = 144 },
    { min = 125, dpi = 120 },
}

-- Real DPI from the size the monitor reports, or nil if unknown (e.g. projectors)
local function physical_dpi(s)
    local dpi
    for _, o in pairs(s.outputs or {}) do
        if o.mm_width and o.mm_width > 0 and o.mm_height and o.mm_height > 0 then
            local d = math.min(s.geometry.width  * 25.4 / o.mm_width,
                               s.geometry.height * 25.4 / o.mm_height)
            dpi = math.min(dpi or d, d)
        end
    end
    return dpi
end

function scaling.screen_dpi(s)
    local phys = physical_dpi(s)
    if phys then
        for _, step in ipairs(steps) do
            if phys >= step.min then return step.dpi end
        end
    end
    return 96
end

-- Set the DPI of one screen (text in its bar and popups follows it)
function scaling.apply(s)
    s.dpi = scaling.screen_dpi(s)
end

-- rofi command sized like awesome on the focused screen: "rofi -dpi 120 <args>".
-- (rofi's own dpi: 0 would use the raw panel density, ~160, which is too big.)
function scaling.rofi(args)
    local s = require("awful").screen.focused()
    return string.format("rofi -dpi %d %s", math.floor((s and s.dpi or 96) + 0.5), args)
end

-- Call before beautiful.init(). Sets every screen's DPI, and uses the highest
-- one for sizes that are the same on all screens (menus, notifications,
-- titlebars, gaps), so text never gets cut off. A screen plugged in later gets
-- its own DPI for the bar; restart awesome (Mod4+Ctrl+r) to recompute the rest.
function scaling.init()
    local highest = 96
    for s in screen do
        scaling.apply(s)
        highest = math.max(highest, s.dpi)
    end
    beautiful.xresources.set_dpi(highest)
end

return scaling
