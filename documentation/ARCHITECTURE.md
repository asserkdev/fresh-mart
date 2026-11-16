# Fresh Mart v7 — Architecture

## Overview

Fresh Mart uses a layered architecture built on Godot 4's node system.

```
┌─────────────────────────────────────────┐
│              Autoloads (Singletons)      │
│  EventBus  GameManager  GameClock        │
│  SettingsManager  SaveManager            │
│  SceneManager  ServiceRegistry          │
│  NotificationManager                    │
└────────────────────┬────────────────────┘
                     │
┌────────────────────▼────────────────────┐
│          World Systems (Runtime)        │
│  ChunkManager  NPCManager               │
│  SupermarketManager  EconomyManager     │
│  QuestManager  PlacementSystem          │
└────────────────────┬────────────────────┘
                     │
┌────────────────────▼────────────────────┐
│            Scene Layer                  │
│  WorldRoot  Supermarket  Player  NPCs   │
│  HUD  Menus  Chunks                     │
└─────────────────────────────────────────┘
```

## Communication

Systems communicate via **EventBus signals** (not direct node references).

The **ServiceRegistry** provides typed access to runtime services without tight coupling.

Autoloads handle only cross-cutting concerns (settings, save, events, scene management).

Gameplay logic lives in scene scripts and runtime managers registered with the ServiceRegistry.

## Save Architecture

The DirtyStateTracker pattern:

1. EventBus signals mark dirty flags on save-relevant events.
2. SaveManager checks flags on autosave (every 300 seconds).
3. If nothing is dirty, the save is skipped.
4. SaveManager calls `get_save_data()` on each registered service.
5. The combined Dictionary is serialized to JSON.
6. The old file is backed up before overwrite.
7. The new file is verified after write.
8. Dirty flags clear only on successful write.

## Chunk Streaming

The world is a fixed grid of 64×64m chunks. The ChunkManager maintains:

- A registry of all chunks (never random generation).
- Load/unload radii with hysteresis (128m load, 160m unload).
- An async load queue sorted by proximity.
- Persistent state storage per chunk (placed objects, modified entities).

Chunks are deterministic — the same chunk ID always refers to the same authored location.

## NPC Simulation Tiers

| Distance | Simulation |
|----------|-----------|
| < 60m | Full physics, navigation, animation, decision-making |
| 60–120m | Simplified navigation, reduced decision frequency |
| > 120m | Mathematical background simulation only (no nodes) |

## Data-Driven Design

Products, buildings, NPC profiles, quests, and suppliers use Dictionary-based definitions loaded from JSON at startup.

Adding a new product requires editing `data/products/products.json` only.

No core script changes are needed for content additions.
