---
{
  "name": "movement_control",
  "description": "Control SIGGE's hexapod body via UART. for movement and walking.",
  "metadata": {
    "cap_groups": [
      "cap_lua"
    ],
    "manage_mode": "readonly"
  }
}
---

# Hexapod Movement Control

Use this skill for physical body control that is movement or walking: forward/backward, sideways, turning, posture.

## Pre-built scripts (one tool call each)

| Script | Action |
|---|---|
| `/fatfs/scripts/hex_crawl.lua` | Stand up / default stance (only necessary to activate before walking to make sure you are in a good position) |
| `/fatfs/scripts/hex_stop.lua` | Stanna / Stå still |
| `/fatfs/scripts/hex_forward.lua` | Gå framåt i hastighet "50" |
| `/fatfs/scripts/hex_backward.lua` | Gå bakåt i hastighet "50" |
| `/fatfs/scripts/hex_turn_left.lua` | sväng vänster |
| `/fatfs/scripts/hex_turn_right.lua` | sväng höger |

## UART-protokoll

Kontrollera kroppen genom att skicka kommandon: 
Rörelsekommando = C
Rörelsekommandon har formatet: C|x|y|z& där x, y, z är hastigheter i olika riktningar.
X = hastighet i sidled (positive värden för höger, negativa för vänster)
Y = hastighet framåt/bakåt (positiva värden för framåt, negativa för bakåt)
Z = vridning (1 = vänster, 2 = höger)

## Example usage

Exempel: skicka "C|0|50|0&" för att gå framåt i hastighet "50". Skicka "C|0|0|0&" för att stoppa rörelsen.
dessa kommandon kan kombineras för att gå i en båge, t.ex. "C|0|50|2&" för att gå framåt och svänga åt höger
eller "C|50|50|0&" för att gå diagonalt, framåt åt höger.