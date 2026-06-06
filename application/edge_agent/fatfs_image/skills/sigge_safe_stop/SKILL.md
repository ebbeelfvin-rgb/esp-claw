---
{
  "name": "sigge_safe_stop",
  "description": "Safe stop for SIGGE: stops hexapod body + AI brain simultaneously via MQTT",
  "metadata": {
    "cap_groups": ["cap_lua"],
    "manage_mode": "readonly"
  }
}
---

# SIGGE Safe Stop

Listens for MQTT `sigge/command` with payload `STOP` and executes **dual stop sequence**:

1. **Hexapod body**: Runs `/fatfs/scripts/hex_stop.lua` immediately
2. **AI brain**: Sends `/stop` to `sigge/hjarna/in` 

This ensures ALL movement stops, not just scripts on the brain.

## Trigger
```
Topic: sigge/command
Payload: STOP
```

## Usage
Publish to MQTT:
```
mosquitto_pub -t sigge/command -m STOP
```

Or use HA automation/button to publish this message.

## Status
Ready to run as a background Lua daemon.
