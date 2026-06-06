-- SIGGE Autonomous Behavior State Machine
-- Intelligent navigation with investigation, crossing attempts, and avoidance
-- Uses ultraljud sensor + posture control + transition timing

local uart = require("uart")
local delay = require("delay")
local call_cap = require("call_capability")
local json = require("lua_module_json")
local log = require("log")

-- Configuration
local HA_URL = "http://192.168.86.73:8123"
local HA_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIyMDExOWE0YWEwNzk0YjdmODljZDU5OGZlYmY1ZDkyMCIsImlhdCI6MTc4MDY3MTIyMCwiZXhwIjoyMDk2MDMxMjIwfQ.u-LAAj5emZtfpnvEvXD6j3_AjnMtTPLAlaab3LLCKmI"
local SENSOR_ID = "sensor.sigge_avstand"

-- State machine
local state = "IDLE"
local speed = 30  -- reduced for more controlled movement
local min_distance_mm = 300
local investigate_threshold = 200  -- how close before investigating
local poll_interval_ms = 200
local last_distance = nil
local left_distance = nil
local right_distance = nil

-- UART connection
local u = uart.new(1, 47, 48, 115200)
u:write("B&")  -- Initialize crawl state

log.info("🕷️ SIGGE Autonomous Behavior starting...")
log.info("  State: " .. state)

-- Helper: Read distance from HA
local function read_distance()
  local status, response = call_cap("cap_http_request", {
    url = HA_URL .. "/api/states/" .. SENSOR_ID,
    method = "GET",
    headers = {
      Authorization = "Bearer " .. HA_TOKEN,
      ["Content-Type"] = "application/json"
    },
    timeout_ms = 2000
  })
  
  if status and response then
    local ok, data = pcall(function() return json.decode(response) end)
    if ok and data and data.state then
      return tonumber(data.state)
    end
  end
  return nil
end

-- Helper: Send UART command
local function send_uart(cmd)
  log.info("  → UART: " .. cmd)
  u:write(cmd)
end

-- STATE: IDLE
local function state_idle()
  log.info("🔵 STATE: IDLE")
  state = "IDLE"
  delay.delay_ms(500)
end

-- STATE: MOVING_FORWARD
local function state_moving_forward()
  log.info("🟢 STATE: MOVING_FORWARD")
  state = "MOVING_FORWARD"
  
  -- Set transition to 600ms (default natural gait) once
  send_uart("C|0|" .. speed .. "|0|600|&")
  
  while state == "MOVING_FORWARD" do
    delay.delay_ms(poll_interval_ms)
    
    -- Read distance continuously
    local distance = read_distance()
    if distance then
      last_distance = distance
      log.info("📏 Distance: " .. distance .. "mm")
      
      -- If obstacle close → investigate
      if distance < investigate_threshold then
        log.warn("⚠️ Obstacle detected! Distance: " .. distance .. "mm")
        state = "INVESTIGATING"
        break
      end
    end
    
    -- Continue forward (no transition param = use current 600ms)
    send_uart("C|0|" .. speed .. "|0|&")
  end
end

-- STATE: INVESTIGATING
local function state_investigating()
  log.info("🟡 STATE: INVESTIGATING")
  state = "INVESTIGATING"
  
  -- Stop movement first
  send_uart("C|0|0|0|&")
  delay.delay_ms(300)
  
  -- Look LEFT with slow 800ms transition
  log.info("  👀 Looking LEFT...")
  send_uart("F|20|0|0|0|0|30|800|&")
  delay.delay_ms(700)
  left_distance = read_distance()
  log.info("  📏 Left distance: " .. (left_distance or "?") .. "mm")
  
  -- Look RIGHT with current 800ms transition
  log.info("  👀 Looking RIGHT...")
  send_uart("F|-20|0|0|0|0|30|&")
  delay.delay_ms(700)
  right_distance = read_distance()
  log.info("  📏 Right distance: " .. (right_distance or "?") .. "mm")
  
  -- Decide based on distances
  local left_ok = (left_distance and left_distance > min_distance_mm)
  local right_ok = (right_distance and right_distance > min_distance_mm)
  
  if left_ok or right_ok then
    log.info("✅ Path found! Attempting to cross...")
    state = "TRY_CROSSING"
  else
    log.warn("❌ Path blocked both sides. Avoiding...")
    state = "AVOIDING"
  end
end

-- STATE: TRY_CROSSING
local function state_try_crossing()
  log.info("🟠 STATE: TRY_CROSSING")
  state = "TRY_CROSSING"
  
  -- Determine which side is better
  local go_left = false
  if left_distance and right_distance then
    go_left = (left_distance > right_distance)
  elseif left_distance then
    go_left = true
  end
  
  if go_left then
    log.info("  → Turning LEFT to cross...")
    send_uart("C|0|0|-30|600|&")  -- turn left, set transition to 600ms
  else
    log.info("  → Turning RIGHT to cross...")
    send_uart("C|0|0|30|600|&")   -- turn right, set transition to 600ms
  end
  
  delay.delay_ms(800)  -- rotate time
  
  -- Reset posture to neutral before moving
  log.info("  ↩️  Resetting posture...")
  send_uart("F|0|0|0|0|0|0|&")
  delay.delay_ms(700)
  
  -- Check if way is clear now
  local distance = read_distance()
  if distance and distance > min_distance_mm then
    log.info("✅ Successfully crossed! Returning to forward movement...")
    state = "MOVING_FORWARD"
  else
    log.warn("⚠️ Crossing failed. Falling back to avoidance...")
    state = "AVOIDING"
  end
end

-- STATE: AVOIDING
local function state_avoiding()
  log.info("🔴 STATE: AVOIDING")
  state = "AVOIDING"
  
  -- Backup with 600ms transition (natural gait)
  log.info("  ← Backing up...")
  send_uart("C|0|-30|0|600|&")
  delay.delay_ms(800)
  
  -- Turn away from obstacle (alternate left/right)
  if math.random() > 0.5 then
    log.info("  ↻ Turning LEFT...")
    send_uart("C|0|0|-50|&")
  else
    log.info("  ↺ Turning RIGHT...")
    send_uart("C|0|0|50|&")
  end
  
  delay.delay_ms(1000)
  
  -- Check distance
  local distance = read_distance()
  if distance and distance > min_distance_mm + 100 then
    log.info("✅ Space cleared! Returning to forward movement...")
    state = "MOVING_FORWARD"
  else
    log.info("⚠️ Still blocked. Trying another direction...")
    state = "AVOIDING"  -- loop avoidance
  end
end

-- STATE: STALKING (optional slow approach mode)
-- Triggered externally via MQTT "STALK" command
local function state_stalking()
  log.info("🕵️ STATE: STALKING (slow approach)")
  state = "STALKING"
  
  -- Set to super slow 1500ms transition for careful approach
  send_uart("C|0|30|0|1500|&")
  
  while state == "STALKING" do
    delay.delay_ms(poll_interval_ms)
    
    -- Read distance
    local distance = read_distance()
    if distance then
      log.info("📏 Stalk distance: " .. distance .. "mm")
      
      -- If too close, stop stalking
      if distance < 150 then
        log.info("🛑 Target reached!")
        send_uart("C|0|0|0|&")
        state = "IDLE"
        break
      end
    end
    
    -- Continue slow approach
    send_uart("C|0|30|0|&")
  end
end

-- Main state machine loop
log.info("🕷️ Starting state machine...")
state = "MOVING_FORWARD"

while true do
  if state == "IDLE" then
    state_idle()
  elseif state == "MOVING_FORWARD" then
    state_moving_forward()
  elseif state == "INVESTIGATING" then
    state_investigating()
  elseif state == "TRY_CROSSING" then
    state_try_crossing()
  elseif state == "AVOIDING" then
    state_avoiding()
  elseif state == "STALKING" then
    state_stalking()
  else
    log.warn("Unknown state: " .. state)
    state = "IDLE"
  end
  
  delay.delay_ms(100)
end

u:close()
