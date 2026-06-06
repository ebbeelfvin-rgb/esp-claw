---
{
  "name": "posture_control",
  "description": "Control SIGGE's hexapod body via UART. for posture adjustment.",
  "metadata": {
    "cap_groups": [
      "cap_lua"
    ],
    "manage_mode": "readonly"
  }
}
---

# Hexapod Posture Control

Use this skill for adjusting the posture (attitude) of SIGGE's hexapod body via UART. Posture control can be used for different purposes, such as lowering the body for crawling, raising it for better obstacle clearance, tilting the body for dynamic balance, or adjusting the center of gravity for different movement types.

## Pre-built scripts (one tool call each)

| Script | Action |
|---|---|
| `/fatfs/scripts/hex_crawl.lua` | Låg grundposition (krypläge, bra på hårda golv) |
| `/fatfs/scripts/hex_rest.lua` | Vila/Vilopositionen - preparerar kroppen för vila |
| `/fatfs/scripts/hex_getup.lua` | Resa sig upp från vilotillståndet |
| `/fatfs/scripts/hex_cute.lua` | Söt/liten pose |
| `/fatfs/scripts/hex_reset.lua` | Återställ till neutral position |

## UART-protokoll

Kontrollera kroppens attityd genom att skicka kommandon:
Attitydkommando = F
Attitydkommandon har formatet: F|Yaw|Roll|Pitch|X|Y|Z& där:
- Yaw = rotation omkring Z-axeln (rotation horisontalt)
- Roll = rotation omkring X-axeln (rotation sida-till-sida)
- Pitch = rotation omkring Y-axeln (rotation fram-bak)
- X = sidled förflyttning av tyngdpunkt (positiva värden för höger, negativa för vänster)
- Y = fram/bak förflyttning av tyngdpunkt (positiva värden för framåt, negativa för bakåt)
- Z = vertikal höjd av tyngdpunkt (kontrollerar kroppsöjden)

## Example usage

Exempel: skicka "F|0|0|0|0|50|0&" för att flytta tyngdpunkten framåt. Skicka "F|0|0|0|0|0|30&" för att höja kroppen. Dessa kommandon kan kombineras för att justera kroppens attityd i flera dimensioner samtidigt.
