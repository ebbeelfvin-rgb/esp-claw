---
{
  "name": "sigge_eye_color",
  "description": "Change SIGGE's eye color by specifying RGB values or a named color like red, green, blue, yellow, white, or off.",
  "metadata": {
    "cap_groups": [
      "cap_lua"
    ],
    "manage_mode": "readonly"
  }
}
---

# SIGGE Eye Color

Use this skill when the user wants to change SIGGE's eye color. You can use RGB values or named colors.

Run the bundled Lua script with the Lua script execution capability.

If script execution returns an error, report that error directly to the user.

## Script Args Schema

```json
{
  "type": "object",
  "properties": {
    "r": {
      "type": "integer",
      "description": "Red value (0-255), optional if using color name",
      "minimum": 0,
      "maximum": 255
    },
    "g": {
      "type": "integer",
      "description": "Green value (0-255), optional if using color name",
      "minimum": 0,
      "maximum": 255
    },
    "b": {
      "type": "integer",
      "description": "Blue value (0-255), optional if using color name",
      "minimum": 0,
      "maximum": 255
    },
    "color": {
      "type": "string",
      "description": "Named color: 'red', 'green', 'blue', 'yellow', 'cyan', 'magenta', 'white', 'off'",
      "enum": ["red", "green", "blue", "yellow", "cyan", "magenta", "white", "off"]
    }
  }
}
```

## Recommended Flow

1. Check if the user provided a named color (red, green, blue, etc.) or RGB values.
2. If named color, use that directly.
3. If RGB values, validate they are 0-255.
4. Run `/fatfs/skills/sigge_eye_color/scripts/set_eye_color.lua` with the appropriate args.
5. Report the result to the user.

## Tool Call Examples

Change eyes to red:
```json
{"path":"/fatfs/skills/sigge_eye_color/scripts/set_eye_color.lua","args":{"color":"red"}}
```

Change eyes to custom RGB (e.g., purple = red+blue):
```json
{"path":"/fatfs/skills/sigge_eye_color/scripts/set_eye_color.lua","args":{"r":200,"g":0,"b":200}}
```

Turn eyes off:
```json
{"path":"/fatfs/skills/sigge_eye_color/scripts/set_eye_color.lua","args":{"color":"off"}}
```
