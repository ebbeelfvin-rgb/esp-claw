-- SIGGE Eye Color Controller
-- Changes RGB eye color via UART to hexapod body
-- Args: either 'color' (named) or 'r', 'g', 'b' (RGB values 0-255)

local uart = require("uart")
local delay = require("delay")

-- Named color mappings
local colors = {
    red = {r=255, g=0, b=0},
    green = {r=0, g=255, b=0},
    blue = {r=0, g=0, b=255},
    yellow = {r=255, g=255, b=0},
    cyan = {r=0, g=255, b=255},
    magenta = {r=255, g=0, b=255},
    white = {r=255, g=255, b=255},
    off = {r=0, g=0, b=0}
}

-- Get color from args
local r, g, b
if args.color then
    local named = colors[args.color]
    if not named then
        error("Unknown color: " .. args.color)
    end
    r, g, b = named.r, named.g, named.b
else
    r = args.r or 0
    g = args.g or 0
    b = args.b or 0
end

-- Validate RGB range
if r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then
    error("RGB values must be 0-255")
end

-- Initialize UART
local ok, u = pcall(uart.new, 1, 47, 48, 115200)
if not ok then
    print("UART open FAILED: " .. tostring(u))
    return "uart open failed"
end
print("UART open ok")

-- Send RGB command: H|r|g|b&
local cmd = string.format("H|%d|%d|%d&", r, g, b)
print("Setting eyes to RGB(" .. r .. "," .. g .. "," .. b .. ")")

local write_ok = pcall(u.write, u, cmd)
print("write H|" .. r .. "|" .. g .. "|" .. b .. "&: " .. tostring(write_ok))

delay.delay_ms(100)
u:close()
print("Eyes set successfully!")
