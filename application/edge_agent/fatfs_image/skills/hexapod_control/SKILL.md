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

Not for walking.
prebuilt scripts for controlling SIGGE's hexapod body. You can use these scripts to make SIGGE perform various actions, such as waving, dancing, and more. You can also create your own scripts to teach SIGGE new movements or to create custom action sequences.

## Pre-built scripts (one tool call each)

| Script | Action |
|---|---|
| `/fatfs/scripts/hex_crawl.lua` | Låg grundposition (krypläge, bra på hårda golv) / återgång till normalt krypläge om du ändrat position |
| `/fatfs/scripts/hex_wave.lua` | Vinka (action 14) |
| `/fatfs/scripts/hex_cute.lua` | Agera gulligt (action 5) |
| `/fatfs/scripts/hex_rest.lua` | Vila / >följs alltid med hex_getup.lua när vilat färdigt |
| `/fatfs/scripts/hex_getup.lua` | Resa sig upp efter "Vila" |
| `/fatfs/scripts/hex_dance.lua` | Full dance sequence |
| `/fatfs/scripts/hex_reset.lua` | reset ifall något går fel / låser sig |

Example: `{"path":"/fatfs/scripts/hex_wave.lua"}` för att vinka till någon.

## Action groups(number) (preset animations) & UART-kommandon

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

# Eye Color Control

För att ändra ögonfärgen, använd **`sigge_eye_color`** skill istället. Den stödjer både namngivna färger (red, green, blue, etc.) och anpassade RGB-värden.

# Automatic avoidance function toggle
actions.avoid  |    "I|0/1&"     |  0 = av, 1= på. Aktiverar/avaktiverar Automatisk undvikning av fysiska hinder. 
# Automatic balance control toggle
actions.balance |   "J|0/1&"   |  0 = av, 1= på. Aktiverar/avaktiverar Automatisk balanskontroll för att hålla kroppen stabil under rörelse.

## Rules
- Use pre-built scripts for common actions — they are faster and reliable
- You MAY write new scripts to learn new movements or create custom action sequences — store them in /fatfs/scripts/
- `/session new` if things go wrong
