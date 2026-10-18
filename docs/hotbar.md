# Building hotbar

The bottom dock holds ten icon shortcuts per page, with keyboard badges, live pack counts, a gold selected border, and a contextual building hint. It replaces the fixed text-button toolbar.

| Action | Control |
| --- | --- |
| Select a building shortcut | Click a slot or press 1–9 / 0 |
| Change page | Tab / Shift+Tab, or the page controls |
| Assign or replace a shortcut | Right-click a slot and choose a discovered building |
| Browse all discovered buildings | Buildings button; choose a target slot above the search |
| Assign from inventory | Drag a building from the pack to a hotbar slot |
| Reorder | Drag one shortcut onto another to swap them |
| Pin the current build cursor | Alt + 1–9 / 0 |
| Clear a shortcut | Middle-click, or Clear this slot in the picker |
| Dismiss assignment | Esc or click outside the picker |
| Clear the build cursor / pick a world building | Q |

Shortcuts reference the pack; assignments do not move, reserve, duplicate, or consume items. Selecting a zero-stock building is allowed, with a craft-more hint; actual placement still requires a crafted building. Undiscovered slots remain placeholders so lesson unlocks do not shift keys. The picker respects learning, restoration, and research gates.

Layouts and active pages remain local preferences, independent of factory saves. New worlds retain customization while shortcuts remain gated by progression.

`hotbar_layout.gd` validates and persists stable building IDs. `build_hotbar.gd` owns assignment, picker, and drag validation. `hotbar_slot.gd` renders slots and forwards interactions. No inventory transactions take place in these classes. Inventory drags require a current-world token; shortcut drags carry an owner and revision to reject stale replacements. New entries in `Catalog.BUILDINGS` appear automatically when their content gates permit them.

The design draws on [Factorio's reference-based quickbar](https://wiki.factorio.com/Quickbar) and [Satisfactory's numbered building shortcuts](https://satisfactory.wiki.gg/wiki/Controls), with visible assignment controls for players learning the game.