# Fresh Mart v7

**Fresh Mart** is an open-world supermarket simulator, city builder, business management game, and RPG built in Godot 4.

## What is Fresh Mart?

You start with an empty store in a living city and build a supermarket empire. Order stock from suppliers, manage employees, set prices, serve customers, expand your property, and explore the city to unlock new suppliers, complete quests, and grow your reputation.

The city contains eight districts with residents who have jobs, schedules, and needs. Your business decisions affect the city economy. City events affect your store.

---

## Engine & Requirements

| Item | Value |
|------|-------|
| Engine | Godot 4.3 (GDScript, Mono optional) |
| Platform | Windows 10/11 |
| Minimum RAM | 4 GB |
| Recommended RAM | 8 GB |
| GPU | Integrated graphics (AMD/Intel) supported |
| Storage | ~500 MB |

---

## Setup

1. Install [Godot 4.3 or later](https://godotengine.org/download) (Standard, not Mono, unless noted).
2. Clone or extract this project to any folder.
3. Open Godot, click **Import**, select the `project.godot` file.
4. Press **F5** or click the **Play** button to run.

No additional dependencies are required.

---

## Controls

| Key | Action |
|-----|--------|
| W A S D | Move |
| Mouse | Look |
| Shift | Sprint |
| Space | Jump |
| E | Interact |
| V | Toggle first / third person camera |
| I | Inventory |
| T | Management dashboard |
| B | Construction mode |
| F | Manual save |
| Escape | Pause menu |

---

## Graphics Settings

Open **Settings** from the main menu or pause menu.

Presets: Low (integrated GPU), Medium, High.

Individual controls: texture quality, shadow quality, view distance, anti-aliasing, ambient occlusion, VSsync, FPS limit.

Low preset targets 30 FPS on integrated AMD Radeon graphics. Medium and High target 60 FPS on dedicated GPUs.

---

## Save System

- **Autosave**: every 5 real-time minutes (300 seconds), only if something changed.
- **Manual save**: press F at any time during gameplay.
- **Save on exit**: the game saves automatically when you return to the main menu or close the window.
- **Save location**: `%APPDATA%\Godot\app_userdata\Fresh Mart\saves\`
- **Backups**: three rolling backups per slot. If a save is corrupted, the game automatically recovers from the latest valid backup.
- **Multiple slots**: supported via Load Game menu.

To change the autosave interval, open Settings → Gameplay → Autosave Interval.

---

## Implemented Systems (v7.0 M0–M1)

### Core
- Bootstrap initialization
- GameManager (session, modes, pause)
- EventBus (typed signals)
- ServiceRegistry
- GameClock (in-game time, day/night, seasons)
- SettingsManager (all settings with persistence)
- SceneManager (async scene loading)
- SaveManager (autosave, manual save, backups, dirty tracking, crash recovery)
- NotificationManager

### Player
- CharacterBody3D with walk/run/sprint/jump/gravity
- First-person camera (mouse look, FOV, sensitivity)
- Third-person camera (orbit, spring arm collision)
- Camera switching (V key, smooth)
- Universal interaction framework (E key)
- Inventory system with save persistence

### World
- ChunkManager: 64×64m chunks, circular load/unload with hysteresis
- Deterministic chunk IDs per district
- Persistent chunk state (construction survives unload)
- Eight city districts with authored chunk manifest
- Fallback procedural ground per district
- Background simulation for unloaded chunks

### Supermarket
- ProductManager: 36 products across 10 categories, data-driven
- InventoryManager: batched stock, expiration, capacity
- PricingManager: retail prices, margins, discounts
- SupplierManager: 5 suppliers, order placement, delivery simulation
- CheckoutManager: full transaction workflow, receipts
- SupermarketManager: revenue, expenses, reputation, store levels

### Economy
- EconomyManager: city-wide supply/demand, seasonal modifiers, taxes

### Characters
- NPCManager: 8 named residents with occupations, schedules, needs
- NPC AI: state machine (idle/walk/work/shop/rest), NavigationAgent3D
- Three simulation tiers (full/reduced/background)
- CustomerAI: enters store, browses, selects products, pays, leaves

### Construction
- PlacementSystem: grid snapping, validation, rotation, cost checking
- ConstructionCatalog: 12 object types (shelves, checkout, lights, decor)
- Persistent placed objects survive chunk reload

### RPG / Quests
- QuestManager: 5 quests (auto-start, prerequisites, objectives, rewards)
- Quest objective tracking connected to game events
- Reward system (money, reputation)

### UI
- Main menu (New Game, Continue, Load, Sandbox, Settings, Exit)
- Save selection screen
- Settings screen (all categories)
- HUD (money, time, location, interaction prompt, notifications, quest objective, save status)
- Notification queue system

---

## Partially Implemented Systems

| System | Status |
|--------|--------|
| Player animations (Idle/Walk/Run) | FBX assets present, AnimationPlayer connected, needs import |
| NPC mesh/textures | Placeholder geometry, real models pending |
| Customer mesh | Placeholder geometry |
| Supermarket building interior | Procedural geometry, authored scene WIP |
| Vehicle system | Not started |
| Employee management UI | Backend complete, UI not started |
| Management dashboard | Not started |
| Construction mode UI | Backend complete, UI not started |
| Weather system | Not started |
| Factory / Warehouse | Not started |
| RPG skill tree | Not started |

---

## Planned Systems (M2–M7)

- Full employee management (hire/fire/schedule/train)
- Management dashboard with charts
- Construction mode full UI
- Warehouse and factory
- Vehicle driving
- Weather and world events
- Eight fully authored city districts
- NPC schedules tied to real city locations
- Complete RPG storyline with branching quests
- Skill trees affecting gameplay
- Advanced sandbox / creative mode
- Release packaging and export

---

## Known Issues

- Player FBX models (man.fbx, Idle.fbx, Walking.fbx, Running.fbx) are present but not yet imported into the scene. Animation names must match exactly.
- NavigationRegion3D baking is required for NPC and customer pathfinding to work.
- Chunk loading works but authored district scenes are fallback procedural geometry.
- No audio assets yet — audio buses are initialized but no sound files are assigned.
- The supermarket scene spawns customers but without real NavMesh they will not pathfind correctly.

---

## Running Tests

Automated validation:

```
godot --headless --path . --script tests/unit/test_runner.gd
```

Manual tests: open the project in the editor and run individual test scenes from `tests/`.

---

## Performance Expectations

Tested on AMD Ryzen 5 5625U with integrated AMD Radeon graphics (512 MB VRAM):

| Setting | FPS (empty world) |
|---------|-------------------|
| Low | ~45–60 |
| Medium | ~30–45 |

Target: stable 30 FPS on Low with the full supermarket active.

---

## Asset Provenance

All scripts and scenes are original work created for this project.

FBX models (man.fbx, Idle.fbx, Walking.fbx, Running.fbx): provided by the project owner for use in this game.

No third-party paid assets have been used. All procedural geometry is generated at runtime.

---

## License

See LICENSE file.
