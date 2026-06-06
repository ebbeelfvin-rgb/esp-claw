---
{
  "name": "board_hardware_info",
  "description": "Use this skill before operating hardware or writing Lua and board-specific code that depends on device inventory and occupied GPIOs.",
  "metadata": {
    "cap_groups": ["cap_boards"],
    "manage_mode": "readonly"
  }
}
---

# Current Board Hardware: esp32s3_cam_v10

Read this skill before operating hardware, assigning GPIOs, or writing Lua and board-specific code. **You cannot speculate or fabricate hardware information.**

## Rules
- Before operating any hardware, read this skill first.
- Before assigning a GPIO, check whether it is already occupied below.
- When writing Lua or board-specific code, use the listed device names instead of guessing hardware wiring.

## Board Summary
- Board: `esp32s3_cam_v10`
- Chip: `esp32s3`
- Version: `1`
- Manufacturer: `Hiwonder`

## Device Inventory

The following devices are known to be present on this board:

### camera
- Occupied IO:
  - `vsync` -> `GPIO6`
  - `de` -> `GPIO7`
  - `pclk` -> `GPIO13`
  - `xclk` -> `GPIO15`
  - `sda` -> `GPIO4`
  - `scl` -> `GPIO5`

### boot_button
- Occupied IO:
  - `pin` -> `GPIO0`

### status_led /useless, not visible
- Occupied IO:
  - `pin` -> `GPIO38`

### hexapod_uart
- Occupied IO:
  - `tx` -> `GPIO47`
  - `rx` -> `GPIO48`
  - `baud` -> `115200`
  - `uart_num` -> `1`
- esp32s3-board: 47 and 48 to body-board: IO18 and IO19.

## Notes
- If a device has no explicit IO mapping here, treat it as unknown instead of guessing.
- Use `uart.new(1, 47, 48, 115200)` to open the hexapod UART in Lua scripts.
