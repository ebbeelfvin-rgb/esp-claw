local uart = require("uart")
local u = uart.new(1, 47, 48, 115200)
u:write("O&")
u:close()
return "reset ok"
