# Reversible construction plans

Open F → Plans for the supply checklist and Undo/Redo buttons. In the world or Plans tab, Ctrl+Z undoes a ghost edit; Ctrl+Y or Ctrl+Shift+Z redoes it. These shortcuts stay out of inventory, map, story and other menus so text editing retains its usual behavior.

Placing a copied module is one edit. Single ghost placements, replacing configurations, right-click removal and Clear ghosts also enter history. Identical stamps and failed placements do not create entries or discard redo. A new edit after undo discards the old redo branch.

History holds the latest 32 edits and lasts for the current world session. Saved ghosts remain persistent; loading starts a fresh history. Building a real machine removes that cell from both stacks, so later undo or redo cannot restore its old ghost, remove the machine, refund materials or undo production. Other cells in the same module remain reversible. Occupied or externally changed cells are skipped safely.

The supply checklist keeps stable readable columns even when Nearby plans only filters out every planned building.
