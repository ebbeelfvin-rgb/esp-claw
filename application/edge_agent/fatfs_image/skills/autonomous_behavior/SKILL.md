---
{
  "name": "autonomous_behavior",
  "description": "Intelligent autonomous state machine: SIGGE navigates obstacles by investigating, attempting to cross, and avoiding with full posture control",
  "metadata": {
    "cap_groups": ["cap_lua", "cap_boards"],
    "manage_mode": "web"
  }
}
---

# SIGGE Autonomous Behavior

Complete autonomous navigation with intelligent decision-making. SIGGE moves forward with natural gait, investigates obstacles with slow pendling motion, attempts to cross small barriers, and avoids larger ones.

## State Machine Overview

```
MOVING_FORWARD (600ms transition - natural gait)
  ↓ [obstacle detected < 200mm]
INVESTIGATING (800ms transition, dual-axis scanning)
  ├─ Tittar LEFT (F|20|0|0|0|0|30|800|&)
  ├─ Tittar RIGHT (F|-20|0|0|0|0|30|&)
  ├─ Jämför avstånd från båda sidor
  ├─ Om väg fri → TRY_CROSSING
  └─ Om väg blockerad → AVOIDING

TRY_CROSSING (600ms transition)
  ├─ Sväng mot friaste sidan
  ├─ Reset postur till neutral
  ├─ Bedöm om framkommen
  ├─ Om lyckas → MOVING_FORWARD
  └─ Om misslyckas → AVOIDING

AVOIDING (600ms transition, reaktiv)
  ├─ Backa upp
  ├─ Sväng slumpmässigt
  ├─ Bedöm ny väg
  └─ Återgå till MOVING_FORWARD eller loop

STALKING (1500ms transition, super slow approach)
  ├─ Närmar sig försiktigt med C|0|30|0|1500|&
  ├─ Läser ultraljud kontinuerligt
  └─ Stannar när target är nära (< 150mm)
```

## Usage

```json
{
  "path": "/fatfs/skills/autonomous_behavior/autonomous_behavior.lua",
  "args": {}
}
```

### Args Schema
- (Finns inte för nu — alla värden är hårdkodade för optimal performance)

## Features

### 1. Natural Forward Movement
- Default transition: **600ms** (realistic gait, ben hinner stabilisera)
- Reads ultrasonic distance every 200ms
- Uses command: `C|0|50|0|&` (no transition param = use current 600ms)
- Speed: 50 (kontrollerad rörelse för försöksdrift)

### 2. Intelligent Investigation
- Detects obstacle at < 200mm
- **Dual-axis scanning** with slow 800ms transition:
  - Looks LEFT: `F|20|0|0|0|0|30|800|&`
  - Looks RIGHT: `F|-20|0|0|0|0|30|&`
- Compares both distances to decide best path
- 700ms wait between scans for posture stabilization

### 3. Crossing Attempts
- If either side is clear (> 300mm):
  - Turns toward the clearer direction
  - Resets posture to neutral (Z=0)
  - Checks distance again
  - Returns to MOVING_FORWARD if successful

### 4. Obstacle Avoidance
- If both sides blocked:
  - Backs up smoothly (600ms)
  - Turns randomly left or right
  - Re-evaluates before trying forward again

### 5. Stalking Mode (Bonus)
- Super slow approach: **1500ms transition**
- Command: `C|0|30|0|1500|&`
- Perfect för att närma sig något försiktigt
- Stoppar när target < 150mm

## Critical Transition Values

| Mode | Transition | Use Case | Command |
|------|-----------|----------|---------|
| **Normal** | 600ms | Default gait | `C\|0\|50\|0\|600\|&` |
| **Investigation** | 800ms | Slow scanning | `F\|±20\|0\|0\|0\|0\|30\|800\|&` |
| **Stalking** | 1500ms | Careful approach | `C\|0\|30\|0\|1500\|&` |
| ~~Fast~~ | ~~200ms~~ | ~~AVOID~~ | ~~DON'T USE~~ |

**⚠️ NEVER use 200ms** — it's too fast and breaks natural leg coordination!

## Sensor Integration

- **Ultraljud**: Reads distance directly from kropp via UART (`A|bat|dist&` broadcast every 1s)
- **No HA dependency**: Sensor data arrives over the same UART link used for movement commands
- **Real-time polling**: `drain_rx()` called every 200ms during MOVING_FORWARD
- **Strategic reading**: At key decision points (investigation, crossing, avoidance)

## Movement Commands (UART)

| Command | Meaning |
|---------|---------|
| `C\|0\|50\|0\|600\|&` | Forward + set transition 600ms (default) |
| `C\|0\|50\|0\|&` | Forward (use current 600ms) |
| `C\|0\|-50\|0\|600\|&` | Backward + set transition 600ms |
| `C\|0\|1\|0\|600\|&` | Turn LEFT + set transition 600ms |
| `C\|0\|2\|0\|600\|&` | Turn RIGHT + set transition 600ms |
| `C\|0\|30\|0\|1500\|&` | STALK MODE — super slow approach |
| `F\|20\|0\|0\|0\|0\|30\|800\|&` | Look LEFT, raised, slow transition |
| `F\|-20\|0\|0\|0\|0\|30\|&` | Look RIGHT, raised, current transition |
| `F\|0\|0\|0\|0\|0\|0\|&` | Reset to neutral posture / also known as "crawl state" |

## Stop & Control

- **MQTT STOP**: Publish `STOP` on `sigge/command` → triggers safe stop (both body + brain)
- The script will gracefully close UART connection

## Performance Notes

- **600ms transition** = natural, stable movement that feels organic
- **800ms for investigation** = allows time for posture settling + sensor stabilization
- **1500ms for stalking** = ultra-careful, deliberate approach (för intressanta encounters!)
- **Poll interval (200ms)** = matchar kropp:s 200ms UART-broadcast (1Hz till HA/MQTT separat)

## Personality

This state machine gives SIGGE **realistic behavior**:
- Curious when encountering obstacles (slow investigation)
- Determined when crossing small barriers
- Reactive when blocked completely
- Capable of stealth approach when needed (stalking)

🕷️ Den här är en *riktig* spindel, inte en robot! ✨

## Future Enhancements

- Learn and memorize home layout (walls, stairs, open areas)
- Adaptive speed based on terrain confidence
- Multi-sensor fusion (camera + ultrasound)
- Energy-aware navigation (battery monitoring)
- Emotional state integration (excited, cautious, playful)
