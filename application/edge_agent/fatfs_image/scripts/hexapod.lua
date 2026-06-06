-- hexapod.lua  – SIGGE body control via UART (GPIO47 TX / GPIO48 RX)
-- Protocol: FUNCTION|data1|data2|...|dataN&
-- Coordinate system: Y+ = forward, X+ = right
-- C command: C|X|Y|Z&  where X=sideways(-50..50), Y=forward(-50..50), Z=rotation(0/1/2)

local uart  = require("uart")
local delay = require("delay")

local PORT      = 1
local TX_GPIO   = 47
local RX_GPIO   = 48
local BAUD_RATE = 115200

local u = nil

local function open()
    if u then return true end
    local ok, handle = pcall(uart.new, PORT, TX_GPIO, RX_GPIO, BAUD_RATE)
    if not ok then return false end
    u = handle
    return true
end

local function send(cmd)
    if not open() then return "uart open failed" end
    local ok, err = pcall(u.write, u, cmd .. "&")
    if not ok then u = nil return tostring(err) end
    return "ok"
end

local actions = {}

-- Gait/state commands
function actions.crawl()  return send("B") end        -- enter walk-ready stance
function actions.stop()   return send("C|0|0|0") end  -- stop all motion
function actions.reset()  return send("O") end        -- 

-- Movement: C|X|Y|Z&
--   X = sideways translation  -50(left) .. 50(right)
--   Y = forward/back          -50(back) .. 50(forward)
--   Z = rotation direction    0=none, 1=CCW(left), 2=CW(right)
function actions.forward(a)
    local s = tonumber(a and a.speed) or 50
    return send(string.format("C|0|%d|0", s))
end

function actions.backward(a)
    local s = tonumber(a and a.speed) or 50
    return send(string.format("C|0|%d|0", -s))
end

function actions.strafe_right(a)
    local s = tonumber(a and a.speed) or 50
    return send(string.format("C|%d|0|0", s))
end

function actions.strafe_left(a)
    local s = tonumber(a and a.speed) or 50
    return send(string.format("C|%d|0|0", -s))
end

function actions.turn_left()  return send("C|0|0|1") end  -- CCW rotation
function actions.turn_right() return send("C|0|0|2") end  -- CW rotation

function actions.move(a)
    local x     = tonumber(a and a.x)     or 0
    local y     = tonumber(a and a.y)     or 0
    local omega = tonumber(a and a.omega) or 0
    return send(string.format("C|%d|%d|%d", x, y, omega))
end

-- Posture control: F|Yaw|Roll|Pitch|X|Y|Z&  (all -50..50 except Z: -10..30)
function actions.pose(a)
    local yaw   = tonumber(a and a.yaw)   or 0
    local roll  = tonumber(a and a.roll)  or 0
    local pitch = tonumber(a and a.pitch) or 0
    local px    = tonumber(a and a.x)     or 0
    local py    = tonumber(a and a.y)     or 0
    local pz    = tonumber(a and a.z)     or 15
    return send(string.format("F|%d|%d|%d|%d|%d|%d", yaw, roll, pitch, px, py, pz))
end

-- RGB ultrasonic LED: H|R|G|B&
function actions.rgb(a)
    local r = tonumber(a and a.r) or 0
    local g = tonumber(a and a.g) or 0
    local b = tonumber(a and a.b) or 0
    return send(string.format("H|%d|%d|%d", r, g, b))
end

-- Obstacle avoidance: I|0/1&
function actions.avoid(a)
    local on = tonumber(a and a.on) or 0
    return send(string.format("I|%d", on))
end

-- Self-balancing: J|0/1&
function actions.balance(a)
    local on = tonumber(a and a.on) or 0
    return send(string.format("J|%d", on))
end

-- Action group: K|1|id&  (IDs 0-25 fixed, 26-150 free)
function actions.action(a)
    local id = tonumber(a and a.id) or 0
    return send(string.format("K|1|%d", id))
end

-- Dance sequence — runs multiple actions internally (1 tool call)
function actions.dance(a)
    local style = tostring(a and a.style or "default")
    actions.crawl()
    delay.delay_ms(800)
    if style == "combat" then
        actions.action({id=7})  delay.delay_ms(3000)
        actions.action({id=8})  delay.delay_ms(3000)
        actions.action({id=1})  delay.delay_ms(3000)
    elseif style == "cute" then
        actions.action({id=5})  delay.delay_ms(3000)
        actions.action({id=14}) delay.delay_ms(3000)
        actions.action({id=5})  delay.delay_ms(3000)
    elseif style == "kick" then
        actions.action({id=9})  delay.delay_ms(2000)
        actions.action({id=11}) delay.delay_ms(2000)
        actions.action({id=10}) delay.delay_ms(2000)
        actions.action({id=12}) delay.delay_ms(2000)
    else
        -- default dance mix
        actions.action({id=1})  delay.delay_ms(3000)
        actions.action({id=5})  delay.delay_ms(3000)
        actions.action({id=14}) delay.delay_ms(3000)
        actions.action({id=2})  delay.delay_ms(3000)
    end
    actions.crawl()
    return "dance done"
end

-- Walk with optional duration. ms=0 (default): starts and keeps going until stop is called.
function actions.walk_for(a)
    local x     = tonumber(a and a.x)     or 0
    local y     = tonumber(a and a.y)     or 50
    local omega = tonumber(a and a.omega) or 0
    local ms    = tonumber(a and a.ms)    or 0
    actions.move({x=x, y=y, omega=omega})
    if ms > 0 then
        delay.delay_ms(ms)
        actions.stop()
        return "walked " .. ms .. "ms"
    end
    return "walking"
end

-- Dispatch
local args = (type(args) == "table" and args) or {}
local action_name = tostring(args.action or "")
print("[hexapod] action=" .. action_name)

if action_name == "" then
    return "no action — use args.action: crawl|stop|reset|forward|backward|strafe_left|strafe_right|turn_left|turn_right|move|pose|rgb|avoid|balance|action|walk_for"
end

local fn = actions[action_name]
if not fn then
    return "unknown action: " .. action_name
end

local result = fn(args)
if u then pcall(u.close, u); u = nil end
print("[hexapod] " .. action_name .. " -> " .. tostring(result))
return result
