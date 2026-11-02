-- Power menu (Mod4+Shift+q): lock, suspend, logout, reboot, shut down via rofi.
-- Logout, reboot and shut down ask for confirmation first.
local awful = require("awful")
local vars    = require("modules.vars")
local scaling = require("modules.scaling")

local power = {}

-- Ask a question with rofi, call on_choice(choice) with the selected line.
-- (Labels and prompt are fixed strings below, so plain single quotes are enough.)
local function rofi_choose(prompt, lines, on_choice)
    local cmd = string.format("printf '%%s\\n' '%s' | %s",
        table.concat(lines, "' '"),
        scaling.rofi(string.format("-dmenu -i -no-custom -p '%s'", prompt)))
    awful.spawn.easy_async_with_shell(cmd, function(out)
        local choice = out:gsub("%s+$", "")
        if choice ~= "" then on_choice(choice) end
    end)
end

local function confirm(question, action)
    rofi_choose(question, { "No", "Yes" }, function(choice)
        if choice == "Yes" then action() end
    end)
end

power.lock     = function() awful.spawn(vars.lock_cmd) end
power.suspend  = function() awful.spawn("systemctl suspend") end  -- light-locker locks on suspend
power.logout   = function() confirm("Log out?",  function() awesome.quit() end) end
power.reboot   = function() confirm("Reboot?",   function() awful.spawn("systemctl reboot") end) end
power.shutdown = function() confirm("Shut down?", function() awful.spawn("systemctl poweroff") end) end

local entries = {
    { "Lock",      power.lock     },
    { "Suspend",   power.suspend  },
    { "Log out",   power.logout   },
    { "Reboot",    power.reboot   },
    { "Shut down", power.shutdown },
}

function power.menu()
    local labels = {}
    for i, e in ipairs(entries) do labels[i] = e[1] end
    rofi_choose("Power", labels, function(choice)
        for _, e in ipairs(entries) do
            if e[1] == choice then e[2]() return end
        end
    end)
end

return power
