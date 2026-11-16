# Changelog

## v7.0.0 — M0+M1 Foundation (In Development)

### Added
- Complete project structure (79 directories, modular architecture)
- Bootstrap system with audio bus initialization
- GameManager: session management, modes (Career/Free Play/Sandbox), pause/resume
- EventBus: 60+ typed signals for all game events
- ServiceRegistry: runtime service access without global singletons
- GameClock: in-game time, day/night, seasons, configurable speed
- SettingsManager: full graphics/audio/gameplay settings with ConfigFile persistence
- SceneManager: async threaded scene loading
- SaveManager: 5-minute autosave, dirty tracking, 3-backup rotation, crash recovery
- NotificationManager: queued in-game notifications
- PlayerController: CharacterBody3D, walk/run/sprint, first+third person cameras, interaction
- ChunkManager: 64m chunk streaming, circular load/unload, persistent state, deterministic IDs
- ProductManager: 36 products across 10 categories (data-driven JSON)
- InventoryManager: batched stock, expiration tracking, capacity
- PricingManager: retail prices, margins, discounts
- SupplierManager: 5 suppliers, order placement, reliability-based delivery
- CheckoutManager: full transaction workflow, receipts
- SupermarketManager: revenue, expenses, reputation, store level progression
- EconomyManager: city demand simulation, seasonal modifiers, tax collection
- NPCManager: 8 named city residents, 3-tier simulation (full/reduced/background)
- NPC AI: state machine, NavigationAgent3D, interaction support
- CustomerAI: shopping list, product evaluation, basket, checkout, departure
- QuestManager: 5 quests with prerequisites, objectives, and rewards
- PlacementSystem: grid-snapped construction, validation, rotation, cost
- ConstructionCatalog: 12 placeable objects
- WorldRoot scene: environment, procedural sky, day/night lighting
- HUD: money, time, location, interaction prompt, quest tracker, notifications, save status
- Main menu, settings menu, save selection screen
- README, architecture documentation, save system documentation
- Development log, implementation status, known issues tracking
- .gitignore

### Architecture Decisions
- GDScript only (Godot 4.7.2 Mono installed but C# not needed at this stage)
- JSON for product/district data (human-readable, easy to extend)
- Dictionary-based save format (versioned, forward-compatible)
- Autoloads for cross-cutting concerns only; gameplay logic in scene scripts
- ServiceRegistry over global singletons for testability
