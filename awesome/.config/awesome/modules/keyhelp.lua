-- Searchable list of all key bindings (Mod4+F1), shown with rofi.
-- Every awful.key with a description is listed as "keys  description  [group]";
-- type to filter (fuzzy, best matches first), Enter runs the selected binding.
local awful   = require("awful")
local gfs     = require("gears.filesystem")
local scaling = require("modules.scaling")

local keyhelp = {}

local mod_names = { Mod4 = "Super", Mod1 = "Alt", Control = "Ctrl", Shift = "Shift" }
local mod_order = { "Mod4", "Control", "Mod1", "Shift" }

-- Keycodes #10..#19 are the number row (used so tag keys work on any layout)
local function key_name(k)
    local code = tonumber(k:match("^#(%d+)$"))
    if code and code >= 10 and code <= 19 then return tostring((code - 9) % 10) end
    return k
end

local function combo(entry)
    local parts, has = {}, {}
    for _, m in ipairs(entry.mod) do has[m] = true end
    for _, m in ipairs(mod_order) do
        if has[m] then table.insert(parts, mod_names[m]) end
    end
    table.insert(parts, key_name(entry.key))
    return table.concat(parts, "+")
end

-- Bindings with a description, grouped by group (in the order groups first appear)
local function entries()
    local list, group_rank = {}, {}
    for i, e in ipairs(awful.key.hotkeys) do
        if e.description and e.description ~= "" then
            local group = e.group or "other"
            group_rank[group] = group_rank[group] or i
            table.insert(list, { data = e, group = group, rank = group_rank[group], index = i })
        end
    end
    table.sort(list, function(a, b)
        if a.rank ~= b.rank then return a.rank < b.rank end
        return a.index < b.index
    end)
    return list
end

local function run(e)
    if not e.press then return end
    if e.client_key then
        local c = client.focus
        if c then e.press(c) end
    else
        e.press()
    end
end

function keyhelp.show()
    local list = entries()
    local width = 0
    for _, item in ipairs(list) do
        item.combo = combo(item.data)
        width = math.max(width, #item.combo)
    end

    local path = gfs.get_cache_dir() .. "keyhelp"
    local f = io.open(path, "w")
    if not f then return end
    for _, item in ipairs(list) do
        local desc = item.data.description:gsub("%s+", " ")
        f:write(string.format("%-" .. width .. "s   %s  [%s]\n", item.combo, desc, item.group))
    end
    f:close()

    -- Monospace rows so the key column lines up
    local cmd = scaling.rofi("-dmenu -i -no-custom -format i -p Keys "
        .. "-matching fuzzy -sort -sorting-method fzf "
        .. [[-theme-str 'window { width: 55%; } listview { lines: 15; } ]]
        .. [[element-text { font: "monospace 10"; }']])
        .. " < '" .. path .. "'"
    awful.spawn.easy_async_with_shell(cmd, function(out)
        local i = tonumber(out:match("%d+"))
        local item = i and list[i + 1]
        if item then run(item.data) end
    end)
end

return keyhelp
