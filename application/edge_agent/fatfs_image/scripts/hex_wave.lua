local uart  = require("uart")
local delay = require("delay")

local ok, u = pcall(uart.new, 1, 47, 48, 115200)
if not ok then
    print("UART open FAILED: " .. tostring(u))
    return "uart open failed"
end
print("UART open ok")

local r1 = pcall(u.write, u, "B&")
print("write B: " .. tostring(r1))
delay.delay_ms(800)

local r2 = pcall(u.write, u, "K|1|14&")
print("write K|1|14: " .. tostring(r2))
delay.delay_ms(4000)

u:close()
print("UART closed")
return "vinkat klart"
