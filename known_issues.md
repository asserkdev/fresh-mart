# Known Issues

## Critical

None that prevent opening the project.

## High Priority

1. **FBX import not configured** — man.fbx + animations are present but need Godot import settings. The AnimationPlayer in the player/NPC scenes will play animations once the FBX is imported and animations are named "Idle", "Walking", "Running".

2. **NavigationRegion3D not baked** — NPC and customer pathfinding requires a navigation mesh. Open the world_root scene in the editor, select the NavigationRegion3D node, and click Bake NavigationMesh.

3. **Supermarket interior is procedural** — No authored supermarket interior scene yet. The player spawns in an open world with procedural chunk terrain.

## Medium Priority

4. **No audio** — All audio buses are set up but no .wav/.ogg files are assigned anywhere.

5. **Customer meshes are placeholder capsules** — The customer and NPC scenes use Godot's default capsule collision shape with no visible mesh until FBX import.

6. **Management dashboard UI missing** — The SupermarketManager backend tracks all data correctly, but there is no in-game UI to view finance/analytics/inventory reports.

7. **Construction mode UI missing** — PlacementSystem works but requires a UI to browse catalog and confirm placement.

## Low Priority

8. **No PBR textures** — Procedural geometry uses flat StandardMaterial3D colors.

9. **Weather system not started** — Day/night cycle works. Rain/clouds/fog not implemented.

10. **No vehicles** — Vehicle driving not implemented.

11. **GitHub download page not updated** — asserkdev.github.io/fresh-mart still shows old content.

## Won't Fix (By Design)

- Random city generation: intentionally avoided. The city is fixed and authored.
- Synchronous scene loading: intentionally avoided for performance. SceneManager uses threaded loading.
