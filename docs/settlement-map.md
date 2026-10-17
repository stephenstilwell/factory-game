# Settlement chart and navigation

Press M or use Map in the top bar. The Settlement chart tab opens first; Resource survey retains the existing prospecting and tracking controls.

Drag with the left mouse button to pan, scroll to zoom, and use Center on player to return home to your current position. M or Esc closes the screen. Opening the chart blocks movement and world clicks through the existing survey overlay.

Dark land is unexplored. Walking reveals coarse 8-tile chart cells around the player. The chart shows regional terrain, the early-game river, remaining generated ore in explored cells, placed machines, nearby settlement buildings, and discovered frontier landmarks. Ore is drawn from existing terrain caches: opening or panning the map does not generate distant resources. Depleted ore disappears when the chart redraws/reopens.

Exploration lives in scripts/model/exploration.gd, independently of terrain generation. It is saved in the existing v2 world format, validated on load, and optional for older saves. Old saves begin charting from the current position; previously visited terrain cannot be reconstructed reliably.

Right-click explored land to save and track a named pin. The pin row supports rename, tracking on/off, and removal. Up to 32 pins save with the world, independently from terrain and discovery ledgers. The active pin displays a purple compass and tile distance in the world. Tracking a discovery or survey result takes precedence by clearing personal pin tracking; the saved pin remains. Production diagnostics can save a service pin for the nearest stalled machine.

A minimap, hover details, enemy overlays and reconstructing distant cached ore detail after loading remain future work. These source changes are not included in the previously published v0.8.0 release.

Verification: run Godot headless with --path . --script res://tests/verify_map.gd for chart persistence, validation, migration, and UI checks. The existing verify_factory.gd suite also checks compatibility. Add -- --capture to the map check with a native renderer to save .godot/map-preview.png.
