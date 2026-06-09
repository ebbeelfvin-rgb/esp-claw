---
{
  "name": "news_and_updates",
  "description": "Changes made, Read and update knowledge.",
  "metadata": {
    "cap_groups": [
      "cap_lua"
    ],
    "manage_mode": "readonly"
  }
}
---

## ACK — kroppen bekräftar mottagna kommandon
Kroppen skickar nu `ACK|<cmd>&` på UART2 tillbaka till hjärnan när ett nytt kommando körts (B, C, F, H, J, K, O). Skickas bara vid nytt kommando — inte varje loop-iteration. Hjärnan läser ACK i `drain_rx()` och loggar det som `last_ack`. Gör att du (och det autonoma läget) vet att kroppen faktiskt tog emot och exekverade det du skickade.

## T , 'transition' split into 2 commands/var's/arg's
- updated `/fatfs_image\skills\autonomous_behavior\SKILL.md`
- row 125 - 138
- **task**: adjust `/fatfs_image\skills\autonomous_behavior\autonomous_behavior.lua`
IF necessary

## request to add function for button
 - `fatfs_image\skills\sigge_safe_stop\SKILL.md`
 - row 26 & 36 
