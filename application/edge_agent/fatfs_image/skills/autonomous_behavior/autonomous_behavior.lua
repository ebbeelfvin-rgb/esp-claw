-- SIGGE Autonomous Behavior State Machine
-- Intelligent navigation with investigation, crossing attempts, and avoidance
-- Distance sensor data read directly from kropp via UART (no HA dependency)

local uart  = require("uart")
local delay = require("delay")
local log   = require("log")

-- State machine config
local state                 = "IDLE"
local speed                 = 50
local min_distance_mm       = 300
local investigate_threshold = 200
local poll_interval_ms      = 200

-- UART
local u = uart.new(1, 47, 48, 115200)
u:write("B&")

log.info("SIGGE Autonomous Behavior starting...")

-- Sensor state (populated from kropp UART broadcasts)
local last_distance  = nil
local last_battery   = nil
local left_distance  = nil
local right_distance = nil
local stop_requested = false

-- Drain RX buffer and parse messages from kropp
local rx_buf = ""
local function drain_rx()
    local avail = u:available()
    if avail <= 0 then return end
    local data = u:read(avail, 0)
    if not data or #data == 0 then return end
    rx_buf = rx_buf .. data
    while true do
        local s = rx_buf:find("&")
        if not s then break end
        local msg = rx_buf:sub(1, s - 1)
        rx_buf = rx_buf:sub(s + 1)
        local bat, dist = msg:match("A|(%d+)|(%d+)")
        if bat and dist then
            last_battery  = tonumber(bat)
            last_distance = tonumber(dist)
        elseif msg == "STOP" or msg == "stop" then
            stop_requested = true
            log.warn("STOP received!")
        end
    end
end

-- Returns latest distance; waits up to ~1200ms on first call
local function read_distance()
    for _ = 1, 6 do
        drain_rx()
        if last_distance then return last_distance end
        delay.delay_ms(200)
    end
    return last_distance
end

-- Send UART command
local function send_uart(cmd)
    log.info("  -> UART: " .. cmd)
    u:write(cmd)
end

-- STATE: IDLE
local function state_idle()
    log.info("STATE: IDLE")
    state = "IDLE"
    delay.delay_ms(500)
end

-- STATE: MOVING_FORWARD
local function state_moving_forward()
    log.info("STATE: MOVING_FORWARD")
    state = "MOVING_FORWARD"
    send_uart("C|0|" .. speed .. "|0|600|&")

    while state == "MOVING_FORWARD" and not stop_requested do
        delay.delay_ms(poll_interval_ms)
        local distance = read_distance()
        if distance then
            log.info("Distance: " .. distance .. "mm")
            if distance < investigate_threshold then
                log.warn("Obstacle detected! " .. distance .. "mm")
                state = "INVESTIGATING"
                break
            end
        end
        send_uart("C|0|" .. speed .. "|0|&")
    end
end

-- STATE: INVESTIGATING
local function state_investigating()
    log.info("STATE: INVESTIGATING")
    state = "INVESTIGATING"

    send_uart("C|0|0|0|&")
    delay.delay_ms(300)

    log.info("  Looking LEFT...")
    send_uart("F|20|0|0|0|0|30|800|&")
    delay.delay_ms(700)
    drain_rx()
    left_distance = last_distance
    log.info("  Left: " .. (left_distance or "?") .. "mm")

    log.info("  Looking RIGHT...")
    send_uart("F|-20|0|0|0|0|30|&")
    delay.delay_ms(700)
    drain_rx()
    right_distance = last_distance
    log.info("  Right: " .. (right_distance or "?") .. "mm")

    local left_ok  = (left_distance  and left_distance  > min_distance_mm)
    local right_ok = (right_distance and right_distance > min_distance_mm)

    if left_ok or right_ok then
        log.info("Path found! Attempting to cross...")
        state = "TRY_CROSSING"
    else
        log.warn("Path blocked both sides. Avoiding...")
        state = "AVOIDING"
    end
end

-- STATE: TRY_CROSSING
local function state_try_crossing()
    log.info("STATE: TRY_CROSSING")
    state = "TRY_CROSSING"

    local go_left = false
    if left_distance and right_distance then
        go_left = (left_distance > right_distance)
    elseif left_distance then
        go_left = true
    end

    if go_left then
        log.info("  Turning LEFT...")
        send_uart("C|0|0|1|600|&")
    else
        log.info("  Turning RIGHT...")
        send_uart("C|0|0|2|600|&")
    end
    delay.delay_ms(800)

    send_uart("F|0|0|0|0|0|0|&")
    delay.delay_ms(700)

    drain_rx()
    local distance = last_distance
    if distance and distance > min_distance_mm then
        log.info("Crossed! Returning to forward movement...")
        state = "MOVING_FORWARD"
    else
        log.warn("Crossing failed. Falling back to avoidance...")
        state = "AVOIDING"
    end
end

-- STATE: AVOIDING
local function state_avoiding()
    log.info("STATE: AVOIDING")
    state = "AVOIDING"

    send_uart("C|0|-50|0|600|&")
    delay.delay_ms(800)

    if math.random() > 0.5 then
        log.info("  Turning LEFT...")
        send_uart("C|0|0|1|&")
    else
        log.info("  Turning RIGHT...")
        send_uart("C|0|0|2|&")
    end
    delay.delay_ms(1000)

    drain_rx()
    local distance = last_distance
    if distance and distance > min_distance_mm + 100 then
        log.info("Space cleared! Returning to forward...")
        state = "MOVING_FORWARD"
    else
        log.info("Still blocked. Trying another direction...")
        state = "AVOIDING"
    end
end

-- STATE: STALKING
local function state_stalking()
    log.info("STATE: STALKING (slow approach)")
    state = "STALKING"
    send_uart("C|0|30|0|1500|&")

    while state == "STALKING" and not stop_requested do
        delay.delay_ms(poll_interval_ms)
        drain_rx()
        local distance = last_distance
        if distance then
            log.info("Stalk distance: " .. distance .. "mm")
            if distance < 150 then
                log.info("Target reached!")
                send_uart("C|0|0|0|&")
                state = "IDLE"
                break
            end
        end
        send_uart("C|0|30|0|&")
    end
end

-- Main loop
log.info("Starting state machine...")
state = "MOVING_FORWARD"

while not stop_requested do
    if     state == "IDLE"           then state_idle()
    elseif state == "MOVING_FORWARD" then state_moving_forward()
    elseif state == "INVESTIGATING"  then state_investigating()
    elseif state == "TRY_CROSSING"   then state_try_crossing()
    elseif state == "AVOIDING"       then state_avoiding()
    elseif state == "STALKING"       then state_stalking()
    else
        log.warn("Unknown state: " .. state)
        state = "IDLE"
    end
    drain_rx()
    delay.delay_ms(100)
end

send_uart("C|0|0|0|&")
log.info("Stopped.")
u:close()
