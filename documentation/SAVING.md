# Save System

## Autosave

Default interval: **300 seconds (5 minutes)**.

The timer is configurable in Settings → Gameplay → Autosave Interval (60–600 seconds).

The autosave only writes if the world has changed since the last save (dirty-state tracking).

## Save Location

`%APPDATA%\Godot\app_userdata\Fresh Mart\saves\`

## Backup Policy

Three rolling backups per slot:
- `save_01_backup_0.json` — most recent backup
- `save_01_backup_1.json`
- `save_01_backup_2.json`

A backup is created before every save overwrite.

## Crash Recovery

On startup:
1. The latest save file is validated (version check, metadata check).
2. If invalid, the most recent valid backup is loaded.
3. The player is notified if a backup was used.

## Save Contents

Each save includes:
- Version number
- Metadata (slot, timestamp, playtime, play mode)
- In-game clock state
- Player position, inventory, money, camera mode
- Supermarket state (revenue, expenses, reputation, level)
- Product inventory
- Supplier orders
- Quest progress
- Chunk persistent state (placed objects)
- Economy state

## What Is NOT Saved

- Static world geometry (never serialized)
- NPC positions (re-simulated on load)
- Audio state
- Rendering settings (stored in settings.cfg separately)
