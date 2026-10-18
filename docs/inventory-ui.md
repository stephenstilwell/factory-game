# Inventory and crafting

The crafting view now uses the full workspace with eight recipe columns and extra height. All current hand recipes fit at 1100x720; category, search, and ready filters remain. Machine and town views retain the pack alongside their transfer slots.

Press **E** for inventory and crafting (**I** opens pack details, **C** opens crafting), or click a machine to open the shared workspace. Search and category filters help find materials and recipes. The factory keeps running unless paused with the Pause key or Escape menu; the workspace blocks movement and world clicks. E or Escape closes an interface. Q clears the build cursor, or picks a hovered building when empty. Escape clears the build cursor before opening the pause menu; closing the menu restores the previous pause state.

Item tiles group matching items. Capacity still counts individual items rather than physical slots. Select a tile for its description; double-click a building to equip it. Empty ingredient tiles show what a machine or project accepts.

Choose **1**, **5**, or **All**, then drag goods between the pack and a machine or town project. Right-click a tile to move one; Shift-click moves all that fits into the visible destination. Filled machine tiles withdraw items; empty ingredient tiles load from the pack. Transfers respect reach, recipe filters, stock quotas, and available space. Output slots only allow withdrawals. Dragging reserves nothing: the model validates again when dropped, including after loading or reclaiming a machine.

**Ctrl+left click** on a machine (or its Load ingredients button) loads accepted ingredients and fuel. On chests it stacks only item types already stored there; drag in a new type explicitly. **X** collects finished production while leaving machine inputs and fuel in place. Chest contents and inserter hands can also be collected. The machine recipe selector names each available recipe. Changing recipes returns obsolete ingredients if the pack has room and preserves coal and stored fuel energy.

Crafting shows available recipes, ingredient counts, missing materials, output, and duration. Select a recipe, then choose **Craft 1**, **Craft 5**, or **Max**. Counts represent recipe batches. Missing hand-craftable intermediates are automatically planned and queued first. The preview shows the full pack reservation, queue order, new work time and XP. Already queued, unclaimed outputs can supply a dependency. Separate Make-only buttons remain available when you want just a component. Research gates and machine-only production still apply. Search, categories, and Ready only filter the list. Canceling a prerequisite also cancels its unfinished dependents, as shown in the queue-chip tooltip. Cancel all refunds the whole queue. Only actual reserved goods are refunded: completed intermediates remain real items, and unmade parts are never created. Refunds require sufficient pack capacity.

## Implementation contracts

- `inventory_transfers.gd` resolves player, input, output, hand, and civic stock descriptors and owns transfer validation. UI callbacks emit intent through the controller; they never mutate inventory directly.
- `crafting.gd` owns read-only dependency planning, atomic raw-input reservation, direct intermediate delivery and dependency-aware cancellation. Monotonic job IDs prevent an outdated cancel action from canceling a different job after the queue advances. Old saves receive IDs during loading.
- `item_tile.gd`, `inventory_grid.gd`, and `ui_style.gd` provide shared presentation. The workspace composes crafting, machine, and town panels around the same pack. New item definitions automatically appear in grids and filters.
- Model and UI integration checks cover partial transfers, invalid/stale targets, output protection, batch limits, refunds, recipe changes, search, and workspace input blocking. Normal new games still start empty; populated previews use test fixtures only.

Machine inspection includes a **Pick up building** button. It returns the building and all stored items; it shows any reach, pack-space, or damage requirement directly. You can also close inspection and hold right mouse over a building for half a second.
