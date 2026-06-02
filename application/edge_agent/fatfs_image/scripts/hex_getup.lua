local uart  = require("uart")
local delay = require("delay")
local u = uart.new(1, 47, 48, 115200)
u:write("K|1|18&") delay.delay_ms(4000)
u:write("B&")
u:close()
return "getup ok"
