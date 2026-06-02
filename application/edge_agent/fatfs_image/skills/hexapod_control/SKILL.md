---
{
  "name": "hexapod_control",
  "description": "Control SIGGE's hexapod body via UART. actions and LED colors.",
  "metadata": {
    "cap_groups": [
      "cap_lua"
    ],
    "manage_mode": "readonly"
  }
}
---

# Hexapod Body Control

Use this skill for physical body control that isn't "movement / walking": actions, LED.

## Pre-built scripts (one tool call each)

| Script | Action |
|---|---|
| `/fatfs/scripts/hex_crawl.lua` | Stand up / default stance (only necessary to activate before doing an action unless the action defines otherwise) |
| `/fatfs/scripts/hex_wave.lua` | Wave (action 14) |
| `/fatfs/scripts/hex_cute.lua` | Act cute (action 5) |
| `/fatfs/scripts/hex_dance.lua` | Full dance sequence |

Example: `{"path":"/fatfs/scripts/hex_wave.lua"}` to wave / vinka to somebody.

## Action groups (preset animations)

IDs 0-25 fixed, 26-150 free for learning.

| ID | Description |
|---|---|
| 1 | Spin CCW | 2 | Spin CW |
| 3 | Wake up | 4 | Wake up and run |
| 5 | Act cute | 6 | Obstacle crossing |
| 7 | Combat 1 | 8 | Combat 2 |
| 9 | Left kick fwd | 10 | Left kick right |
| 11 | Right kick fwd | 12 | Right kick left |
| 13 | Push door | 14 | Wave |
| 15 | Stomp | 16 | Look up |
| 17 | "Rest" / lie down | 18 | "Get up" from rest (dont activate hex_crawl.lua before) |

## Rules
- Use pre-built scripts for common actions — they are faster and reliable
- You MAY write new scripts to learn new movements or create custom action sequences — store them in /fatfs/scripts/
- `/session new` if things go wrong
