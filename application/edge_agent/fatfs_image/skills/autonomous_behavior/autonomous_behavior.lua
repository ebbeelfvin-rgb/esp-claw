-- SIGGE Autonomous Behavior State Machine
-- Intelligent navigation with investigation, crossing attempts, and avoidance
-- Distance sensor data read directly from kropp via UART (no HA dependency)

local uart  = require("uart")
local delay = require("delay")

-- State machine config
local state                 = "IDLE"
local speed                 = 50
local min_distance_mm       = 300
local investigate_threshold = 300
local cautious_threshold    = 500
local cautious_speed        = 25
local cautious_duration     = 1000
local state_changed         = true

-- UART
local u = uart.new(1, 47, 48, 115200)
u:write("B&")

print("[SIGGE] Autonomous Behavior starting...")

-- Sensor state (populated from kropp UART broadcasts)
local last_distance  = nil
local last_battery   = nil
local left_distance  = nil
local right_distance = nil
local stop_requested = false
local last_ack       = nil

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
        else
            local ack = msg:match("ACK|(.+)")
            if ack then
                last_ack = ack
            elseif msg == "STOP" or msg == "stop" then
                stop_requested = true
                print("[STOP] Received!")
            end
        end
    end
end

-- Send UART command and wait for ACK
local function send_command(cmd)
    print("[CMD] " .. cmd)
    last_ack = nil
    u:write(cmd .. "&")
    
    -- Wait for ACK (up to 100ms)
    for _ = 1, 10 do
        delay.delay_ms(10)
        drain_rx()
        if last_ack then
            return true
        end
    end
    print("[WARN] No ACK for: " .. cmd)
    return false
end

-- Transition to new state
local function set_state(new_state)
    if state ~= new_state then
        state = new_state
        state_changed = true
        print("[TRANSITION] -> " .. state)
    end
end

-- STATE: MOVING_FORWARD
local function state_moving_forward()
    if state_changed then
        state_changed = false
        print("[STATE] MOVING_FORWARD (speed=" .. speed .. ")")
        send_command("C|0|" .. speed .. "|0|600")
    end
    
    -- Check sensor every loop iteration
    drain_rx()
    local distance = last_distance
    if distance then
        if distance < investigate_threshold then
            print("[OBSTACLE] " .. distance .. "mm - stopping")
            set_state("STOP")
        elseif distance < cautious_threshold then
            print("[CAUTION] " .. distance .. "mm - slowing down")
            set_state("CAUTIOUS")
        end
    end
end

-- STATE: CAUTIOUS
local function state_cautious()
    if state_changed then
        state_changed = false
        print("[STATE] CAUTIOUS (speed=" .. cautious_speed .. ")")
        send_command("C|0|" .. cautious_speed .. "|0|" .. cautious_duration)
    end
    
    -- Check sensor
    drain_rx()
    local distance = last_distance
    if distance and distance < investigate_threshold then
        print("[OBSTACLE] " .. distance .. "mm - stopping")
        set_state("STOP")
    end
end

-- STATE: STOP
local function state_stop()
    if state_changed then
        state_changed = false
        print("[STATE] STOP")
        send_command("C|0|0|0")
    end
    
    -- After stopped, investigate
    delay.delay_ms(200)
    set_state("INVESTIGATING")
end

-- STATE: INVESTIGATING
local function state_investigating()
    if state_changed then
        state_changed = false
        print("[STATE] INVESTIGATING")
    end
    
    print("[LOOK] LEFT...")
    send_command("F|20|0|0|0|0|30|800")
    delay.delay_ms(700)
    drain_rx()
    left_distance = last_distance
    print("[LEFT] " .. (left_distance or "?") .. "mm")

    print("[LOOK] RIGHT...")
    send_command("F|-20|0|0|0|0|30")
    delay.delay_ms(700)
    drain_rx()
    right_distance = last_distance
    print("[RIGHT] " .. (right_distance or "?") .. "mm")

    local left_ok  = (left_distance  and left_distance  > min_distance_mm)
    local right_ok = (right_distance and right_distance > min_distance_mm)

    if left_ok or right_ok then
        print("[DECISION] Path found - turning")
        set_state("TURNING")
    else
        print("[DECISION] Path blocked both sides - backing up")
        set_state("AVOIDING")
    end
end

-- STATE: TURNING
local function state_turning()
    if state_changed then
        state_changed = false
        print("[STATE] TURNING")
        
        local go_left = false
        if left_distance and right_distance then
            go_left = (left_distance > right_distance)
        elseif left_distance then
            go_left = true
        end

        if go_left then
            print("[ACTION] Turn LEFT")
            send_command("C|0|0|1|600")
        else
            print("[ACTION] Turn RIGHT")
            send_command("C|0|0|2|600")
        end
    end
    
    delay.delay_ms(800)
    print("[ACTION] Step forward")
    send_command("F|0|0|0|0|0|0")
    delay.delay_ms(700)

    drain_rx()
    local distance = last_distance
    if distance and distance > min_distance_mm then
        print("[SUCCESS] Path clear - moving forward")
        set_state("MOVING_FORWARD")
    else
        print("[FAIL] Still blocked - avoiding")
        set_state("AVOIDING")
    end
end

-- STATE: AVOIDING
local function state_avoiding()
    if state_changed then
        state_changed = false
        print("[STATE] AVOIDING")
        
        print("[ACTION] Back up")
        send_command("C|0|-50|0|600")
    end
    
    delay.delay_ms(800)

    if math.random() > 0.5 then
        print("[ACTION] Turn LEFT")
        send_command("C|0|0|1")
    else
        print("[ACTION] Turn RIGHT")
        send_command("C|0|0|2")
    end
    delay.delay_ms(1000)

    drain_rx()
    local distance = last_distance
    if distance and distance > min_distance_mm + 100 then
        print("[CLEAR] Space found - moving forward")
        set_state("MOVING_FORWARD")
    else
        print("[BLOCKED] Still stuck - investigating")
        set_state("INVESTIGATING")
    end
end

-- Main loop
print("[START] Autonomous exploration starting...")
set_state("MOVING_FORWARD")

while not stop_requested do
    if     state == "MOVING_FORWARD" then state_moving_forward()
    elseif state == "CAUTIOUS"       then state_cautious()
    elseif state == "STOP"           then state_stop()
    elseif state == "INVESTIGATING"  then state_investigating()
    elseif state == "TURNING"        then state_turning()
    elseif state == "AVOIDING"       then state_avoiding()
    else
        print("[WARN] Unknown state: " .. state)
        set_state("MOVING_FORWARD")
    end
    delay.delay_ms(100)
end

send_command("C|0|0|0")
print("[DONE] Exploration stopped.")
u:close()
