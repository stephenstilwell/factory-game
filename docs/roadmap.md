# Factory development roadmap

The playable loop is now: learn extraction and smelting, build automated component/science lines, choose routing or metallurgy, manufacture expansion equipment, and supply Oldbridge's reconstruction.

| Layer | Implemented | Next step |
| --- | --- | --- |
| Simulation | Fixed ticks, stable IDs, item transactions, deterministic save continuation | Profile larger factories before sleeping machines or compressed transport |
| World | Finite seeded deposits, exploration, resource survey | Biomes, terrain obstacles, minimap |
| Logistics | Snapshot belts, fair merges, splitter junctions, underground pairs, filtered inserters | Priorities and filters, richer routing; lanes only with a deliberate simulation redesign |
| Production | Smelting, components, science, automated manufacture of all buildings | Electricity and meaningful new production dependencies |
| Progression | Empty start, 15 lessons, four selectable prerequisite technologies, preserved research investments | Additional science tiers tied to real systems |
| Settlement | Three repair projects, recurring post/workshop contracts, housing deliveries, three visible neighborhoods, civic buffs | Specialist services, branching projects, more reasons to spend credits |
| Engineer | Material-funded equipment, three skills to 99, automation commissioning milestones | Further equipment only when new exploration/building problems justify it |
| Building UX | Customizable hotbar, recipe picker, production rates, missing ingredients, copy/paste configuration ghosts | Undo, ghost shortages grouped by available supplies, richer production graphs |
| Defense/story | Three keepers, persistent journal, voluntary ten-wave beacon defense, recoverable breach | Broader enemy behavior and settlement-driven story events |
| Persistence | Validated v2 extensions, backups, older-world compatibility | Named slots and autosave recovery UI |

## Next substantial system: electricity

Introduce generation, consumption, and connectivity as a separate simulation system. Define fuel energy, production capacity, and work demand explicitly. Update topology on construction/removal, allocate supply before production, and present disconnected or underpowered states. Verify conservation, network splitting/merging, shortages, and saved in-progress energy. Avoid adding more percentage upgrades before this creates fresh layout choices.

Fluids and trains should follow new material and distance problems. The present game has no electricity, fluids, train network, belt lanes, construction robots, or multiplayer. See [factory expansion](factory-expansion.md) for the current routing, research, production feedback, housing, and plan contracts.
