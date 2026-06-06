-- SIGGE Safe Stop: Listen to MQTT and stop everything
-- Listens on sigge/command for payload "STOP"
-- Then executes: hex_stop.lua + /stop to brain

local mqtt = require('mqtt')
local log = require('log')

log.info("🛑 SIGGE Safe Stop listener starting...")

-- Subscribe to command topic
local result = mqtt.subscribe("sigge/command", function(topic, payload)
  if payload == "STOP" then
    log.info("🛑 STOP command received! Executing safe stop sequence...")
    
    -- 1. Stop hexapod body immediately
    log.info("  → Stopping hexapod body...")
    local status, err = pcall(function()
      require('hex_stop')()
    end)
    
    if not status then
      log.warn("  → hex_stop error: " .. tostring(err))
    else
      log.info("  ✓ Hexapod stopped")
    end
    
    -- 2. Stop AI brain
    log.info("  → Stopping AI brain...")
    local brain_result = mqtt.publish("sigge/hjarna/in", "/stop")
    if brain_result then
      log.info("  ✓ Brain stop signal sent")
    else
      log.warn("  → Brain stop signal failed")
    end
    
    log.info("🛑 Safe stop complete!")
  end
end)

if result then
  log.info("✓ MQTT listener active on sigge/command")
else
  log.error("✗ Failed to subscribe to MQTT")
end

-- Keep listener alive
while true do
  os.sleep(1000)
end
