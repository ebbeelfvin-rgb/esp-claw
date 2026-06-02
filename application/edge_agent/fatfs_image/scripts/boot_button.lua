local thread = require("thread")
local gpio   = require("gpio")
local delay  = require("delay")
local sys    = require("system")

local BUTTON_PIN = 0
local HOLD_MS    = 1500
local POLL_MS    = 50

gpio.set_direction(BUTTON_PIN, gpio.INPUT)
gpio.set_pull_mode(BUTTON_PIN, gpio.PULLUP)

thread.create(function()
    local held = 0
    while true do
        local level = gpio.get_level(BUTTON_PIN)
        if level == 0 then
            held = held + POLL_MS
            if held >= HOLD_MS then
                print("[boot_button] Restarting...")
                sys.restart()
            end
        else
            held = 0
        end
        delay.delay_ms(POLL_MS)
    end
end)
