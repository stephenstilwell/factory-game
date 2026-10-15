# Finite resources and the frontier

New games use generator 2 and a random world seed. **M / Survey** reports remaining stock in nearby patches and provides a **Track** button. Follow the teal compass marker to the selected resource. When its target tile runs out, the marker searches for another remaining source. The survey does not replenish deposits; if its bounded local search is exhausted, move farther out and survey again. The factory continues operating while the survey is open.

Starter iron, copper, coal, and stone retain their tutorial anchor locations. Their irregular outlines and finite stock vary by seed. Starter tiles hold 180–359 items, enough to learn automation without immediately exhausting a few tiles. Drills display the remaining stock beneath them.

Beyond the protected starting area, 96×96-tile regions each distribute one patch of every resource. Resource types shuffle between quadrants, centers jitter, and patch radii vary. Lobed edges avoid perfect circles and regenerate consistently across chunk boundaries. Regions near home omit patches that would overlap the protected tutorial/settlement area.

Frontier patch radii start at 6–10 tiles and increase by up to four tiles with distance. Tile stock starts at 450–629 items and rises in 256-tile distance bands, capped at 2250–2429. This rewards expansion and longer supply lines while each deposit remains exhaustible. Distant richness is capped rather than growing without limit.

The survey displays the seed and can copy it. To recreate a new world with a particular seed:

```powershell
godot --path . -- --world-seed=12345
```

This only chooses the new world created on launch. **Load** restores the saved seed and terrain rules. No starting items or machines are granted.

## Generation and save contracts

Terrain remains lazy, using 16×16 chunks. Generation uses coordinate-local RNG streams, never the global RNG or exploration order. Queries of negative coordinates use floor division. Depletion overrides are saved separately and survive chunk cache eviction.

Saves now include `terrain_generator`. Missing values select generator 1, preserving the exact terrain and exhausted tiles of older saves. New worlds use generator 2; saving and loading never silently upgrades terrain. Both versions support surveying. Existing worlds retain their original patch sizes/richness; start a new world to use the new distribution. Future changes to procedural output must introduce a new generator version.

Surveying runs only on demand or when a tracked tile exhausts. It considers patch descriptors in a bounded region around the player, then checks live tile stock. It reports one nearby nonempty patch per material, ordered by patch-center distance; it does not promise the closest individual tile among all patches. Markers and survey results are transient and clear when loading a different world.
