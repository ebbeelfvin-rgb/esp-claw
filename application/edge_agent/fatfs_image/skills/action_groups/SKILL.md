---
{
  "name": "action_groups",
  "description": "Run pre-defined action sequences: wave, cute, dance, rest, getup via UART to SIGGE's hexapod body.",
  "metadata": {
    "cap_groups": [
      "cap_lua"
    ],
    "manage_mode": "web"
  }
}
---
the idea with action groups: 0-30 are fixed/Ebbes to alter.
the rest: 30-...150? are yours to manage. create, alter, delete! :)

# Action Groups (readonly)

Run pre-defined action sequences via UART to SIGGE's hexapod body.

Run the bundled Lua script with the Lua script execution capability.

## Available Actions

- **spin_ccw** Rotate/wiggle body counter clockwise. Action ID 1
- **spin_cw** Rotate/wiggle body clockwise. Action ID 2
- **wakeup** Scout quickly to left and right. Action ID 3
- **wakeup_and_run** Scout quickly then take a few steps forward. Action ID 4
- **cute**: Cute pose + wiggle. Action ID 5.
- **wave**: Wave paw. Action ID 14.
- **dance**: Dance routine with optional style (default, cute, combat, kick).

## Not yet added Actions by Ebbe

| ID | Description |
|---|---|
| 7 | Combat 1 
| 8 | Combat 2 
| 9 | Left kick fwd 
| 10 | Left kick right 
| 11 | Right kick fwd 
| 12 | Right kick left 
| 13 | Push door 
| 15 | Stomp 
| 16 | Look up 
- **rest**: Rest/sleep pose. Lowered stance.
- **getup**: Get up from rest. Return to crawl stance.

## Script Args Schema (readonly)

```json
{
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "description": "Action name: wave, cute, dance, rest, getup",
      "enum": ["wave", "cute", "dance", "rest", "getup"]
    },
    "style": {
      "type": "string",
      "description": "Dance style (only for action='dance'): default, cute, combat, kick",
      "enum": ["default", "cute", "combat", "kick"]
    }
  },
  "required": ["action"]
}
```

## Recommended Flow (readonly)

1. Check what action the user wants: wave, cute, dance, rest, or getup.
2. If dance, check if they specified a style (combat, cute, kick, or default).
3. Run `/fatfs/skills/action_groups/scripts/action_groups.lua` with the appropriate args.
4. Report the result to the user.

## Tool Call Examples

Wave:
```json
{"path":"/fatfs/skills/action_groups/scripts/action_groups.lua","args":{"action":"wave"}}
```

Cute pose:
```json
{"path":"/fatfs/skills/action_groups/scripts/action_groups.lua","args":{"action":"cute"}}
```

Combat dance:
```json
{"path":"/fatfs/skills/action_groups/scripts/action_groups.lua","args":{"action":"dance","style":"combat"}}
```

Rest:
```json
{"path":"/fatfs/skills/action_groups/scripts/action_groups.lua","args":{"action":"rest"}}
```

Get up:
```json
{"path":"/fatfs/skills/action_groups/scripts/action_groups.lua","args":{"action":"getup"}}
```
