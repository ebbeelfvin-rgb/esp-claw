local uart = require("uart")
local u = uart.new(1, 47, 48, 115200)
u:write("C|0|0|0&")
u:close()
return "stop ok"
