local uart = require("uart")
local delay = require("delay")
local u = uart.new(1, 47, 48, 115200)
if u:write("B&") then
    delay.delay_ms(500) then
    u:write("C|0|50|0&")

    elif u:write("C|0|50|0&")

return "Går frammåt!"
