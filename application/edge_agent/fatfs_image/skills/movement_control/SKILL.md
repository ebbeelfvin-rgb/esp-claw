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

Use this skill for physical body control that is movement or walking: forward/backward, sideways or turning

## UART-protokoll

Kontrollera kroppen genom att skicka kommandon: 
Rörelsekommando = C
Rörelsekommandon har formatet: C|x|y|z& där x, y, z är hastigheter i olika riktningar.
X = hastighet i sidled (positive värden för höger, negativa för vänster)
Y = hastighet framåt/bakåt (positiva värden för framåt, negativa för bakåt)
Z = vridning (1 = vänster, 2 = höger)

## Pre-built scripts

| Script | Beskrivning |
|---|---|
| `/fatfs/scripts/hex_forward.lua` | Gå framåt |
| `/fatfs/scripts/hex_backward.lua` | Gå bakåt |
| `/fatfs/scripts/hex_turn_left.lua` | Sväng vänster |
| `/fatfs/scripts/hex_turn_right.lua` | Sväng höger |
| `/fatfs/scripts/hex_stop.lua` | Stoppa |

Alla rörelseskript tar en valfri `duration_ms`-parameter:
- `duration_ms = 0` (default): startar rörelsen och stannar inte — kräver separat hex_stop
- `duration_ms > 0`: rör sig exakt den tiden och stannar automatiskt

Exempel: `{"path":"/fatfs/scripts/hex_turn_left.lua","args":{"duration_ms":1000}}` roterar vänster i 1 sekund.

## UART-protokoll (för egenskrivna scripts)

Rörelsekommando = C, format: C|x|y|z& där x, y, z är hastigheter i olika riktningar.
X = sidled (positiv = höger), Y = framåt/bakåt (positiv = framåt), Z = vridning (1 = vänster, 2 = höger)

Exempel: 
skriv "C|0|50|0&" för att gå framåt, 
skriv "C|0|0|0&" för att stoppa/stanna, 
skriv "C|0|0|2&" för att rotera höger med kroppen,
skriv "C|50|0|0&" för att gå höger i sidled med kroppen