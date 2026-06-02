local uart  = require("uart")
local delay = require("delay")
local u = uart.new(1, 47, 48, 115200)
u:write("B&") delay.delay_ms(800)
u:write("K|1|17&") delay.delay_ms(4000)
u:close()
return "rest ok"
