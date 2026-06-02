local uart = require("uart")
local delay = require("delay")
local u = uart.new(1, 47, 48, 115200)
u:write("B&") delay.delay_ms(200)
for i=1,10 do u:write("C|0|0|2&")
return "svänger höger!"
