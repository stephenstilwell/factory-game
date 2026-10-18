# Machine inspection

The machine inspector separates production state from general instructions. MachineReport translates the simulation's reported state into a clear headline, explanation and optional remedy. It does not advance simulation, consume supplies or change recipes.

Blocked output offers collection; missing inputs name exact shortages; missing fuel explains shared fuel depots; disabled buildings offer repair; idle drafting benches link to Technology. Power failures, depleted deposits, managed forestry regrowth, watercourse placement and inserter connections have contextual guidance. Unknown or specialized statuses retain the simulation text and the building description.

Remedy buttons emit the existing supply, collection and repair signals. Reach and repair-kit availability disable the appropriate action; the authoritative model still validates every command. Technology navigation closes the inspector and opens the existing research panel.

A compact input/process/output diagram shows recipe quantities and nominal batch time, including installed electric drive speed. Specialized diagrams cover drills, drafting benches, managed forestry and district dynamos. Drills and drafting benches now expose their existing work progress, and drafting benches show an empty engineering-dossier input slot. Supplies precede optional pickup and retrofit controls in the scrolling inspector.

Use reserved vertical scrollbar width for wrapped text. No geometry animation or live world previews are used.

Verification: machine_inspection_tests.gd exercises real simulation starvation, fuel loading, resumed work, output blockage, collection, repair, disconnected electric drives, reach limits and drafting-bench navigation. It also checks that report inspection does not mutate the machine. capture_ui.gd includes a machine inspector; verify_workspace_layout.gd retains the Crafting-to-camp minimum-window/fullscreen regression.
