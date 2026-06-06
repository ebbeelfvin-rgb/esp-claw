local uart  = require("uart")
local delay = require("delay")

local duration_ms = (type(args) == "table" and type(args.duration_ms) == "number") and args.duration_ms or 0

local u = uart.new(1, 47, 48, 115200)
u:write("B&")
u:write("C|0|0|1&")
if duration_ms > 0 then
  delay.delay_ms(duration_ms)
  u:write("C|0|0|0&")
end
u:close()
return duration_ms > 0 and ("svänger vänster " .. duration_ms .. "ms") or "svänger vänster"
