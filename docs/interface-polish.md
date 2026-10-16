# Interface and atmosphere polish

Oldbridge's interface now uses layered teal panels, stronger edges and soft shadows, warm gold selection/focus outlines, themed tooltips, dropdown menus, and scrollbars. Inventory and research selections share the same visual language; selected research remains readable while its action is disabled.

Buttons receive short brightness transitions on hover and press without moving or scaling their input rectangles. Menus fade in over 140 ms and immediately block world interaction. One tween per control replaces interrupted feedback; transient controls and scene teardown release their animations.

Working furnaces and restored landmarks receive soft, additive radial light. Solid machines cast subtle ground shadows. Up to 64 world-anchored drifting motes decorate the visible area. Light lookup visits visible cells and caps furnace lights at 48; a shared radial gradient avoids one lighting node/texture per machine. This is illustrative light rather than a night cycle or occlusion simulation.

Successful placement, pickup, and major progress events create brief confirmation rings. Placement adds a small dust burst; the existing mining/repair particles remain. Pools cap at 16 rings and 96 particles. Effects expire and clear on world replacement; old worlds disconnect from their presentation listeners.

**Esc → Presentation** provides:
- **Reduced motion:** disables menu/button transitions, drifting motes, light breathing, and transient action effects. Static warm lights remain, and existing essential machine animations still communicate operation.
- **Ambient light and particles:** disables the extra lighting/motes and action effects altogether.

Preferences use the local presentation_settings.cfg in Godot's application data directory and do not affect world saves. Turning off effects clears existing particles immediately. No gameplay, construction timing, production, or resource state is changed by this pass.

Native captures cover the inventory, factory, restored settlement, research, and the pause controls at 1100×720. Automated checks cover state isolation, pool limits/lifetimes, preferences, reduced motion, transient button teardown, and world rebinding.
