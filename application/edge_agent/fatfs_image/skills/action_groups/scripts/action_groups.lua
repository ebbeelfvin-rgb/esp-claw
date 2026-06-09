-- action_groups.lua – SIGGE action sequences via UART
local uart  = require("uart")
local delay = require("delay")

local u = uart.new(1, 47, 48, 115200)
u:write("B&")

local function send_uart(cmd)
    u:write(cmd .. "&")
end

local actions = {}

function actions.wave()
    send_uart("K|1|14")
    delay.delay_ms(2000)
    return "waved"
end

function actions.cute()
    send_uart("K|1|5")
    delay.delay_ms(3000)
    return "cute pose"
end

function actions.dance(style)
    style = style or "default"
    if style == "combat" then
        send_uart("K|1|7")   delay.delay_ms(3000)
        send_uart("K|1|8")   delay.delay_ms(3000)
        send_uart("K|1|1")   delay.delay_ms(3000)
    elseif style == "cute" then
        send_uart("K|1|5")   delay.delay_ms(3000)
        send_uart("K|1|14")  delay.delay_ms(3000)
        send_uart("K|1|5")   delay.delay_ms(3000)
    elseif style == "kick" then
        send_uart("K|1|9")   delay.delay_ms(2000)
        send_uart("K|1|11")  delay.delay_ms(2000)
        send_uart("K|1|10")  delay.delay_ms(2000)
        send_uart("K|1|12")  delay.delay_ms(2000)
    else
        -- default mix
        send_uart("K|1|1")   delay.delay_ms(3000)
        send_uart("K|1|5")   delay.delay_ms(3000)
        send_uart("K|1|14")  delay.delay_ms(3000)
        send_uart("K|1|2")   delay.delay_ms(3000)
    end
    send_uart("C|0|0|0")
    return "dance done"
end

function actions.rest()
    send_uart("K|1|17")
    delay.delay_ms(2000)
    return "resting"
end

function actions.getup()
    send_uart("K|1|18")
    delay.delay_ms(2000)
    return "got up"
end

-- Dispatch
local args = (type(args) == "table" and args) or {}
local action = tostring(args.action or "")

if action == "" then
    return "no action — use args.action: wave|cute|dance|rest|getup"
end

local fn = actions[action]
if not fn then
    u:close()
    return "unknown action: " .. action
end

local result = fn(args.style)
u:close()
return result
