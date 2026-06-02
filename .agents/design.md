# Design Constraints

These rules govern architectural decisions in ESP-Claw. When adding a feature or fixing a bug, prefer paths that respect these boundaries.

## Keep the agent loop small

`claw_core` is the critical runtime path: it builds iteration context, calls the LLM backend, executes capabilities, persists context, handles interrupts, and emits responses. Changes under `components/claw_modules/claw_core/` should be narrow and justified.

If a behavior can live in a capability group, Lua module, skill, router rule, board overlay, or context provider, keep it out of the core loop.

## Extend through capabilities and skills

Capabilities live under `components/claw_capabilities/` and are registered through `components/common/app_claw/app_capabilities.c`. Each capability group should keep its setup, credentials, storage paths, and registration local to that group.

Skills are user-facing instructions and assets. Built-in skill sources live under component `skills/` directories and are synced into the FATFS image at build time. Prefer skills for model know-how and workflows; prefer capabilities for callable firmware functions.

## Keep Lua modules modular

Lua drivers and modules live under `components/lua_modules/` and are registered through `components/common/app_claw/app_lua_modules.c`. Hardware-specific modules should stay guarded by the existing Kconfig and board capability checks.

Do not add board-specific assumptions to generic Lua modules. Put board-specific setup in the board directory or in the board manager data.

## Respect FATFS layering

Shared build-time FATFS defaults live in `application/edge_agent/fatfs_image/`. During build, CMake stages that directory into `build/fatfs_image/`, then overlays the selected board's `fatfs_image/` if present. Skills and built-in Lua scripts/docs are then synced into the staged image.

Edit source FATFS content or board overlays, not generated staged output.