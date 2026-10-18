# Project navigation

Technology [T] is a prerequisite graph generated from Catalog.TECHNOLOGIES. Cards remain inspectable when locked or complete. Inspection changes only the selection; Start/Switch emits the existing research command. The detail panel shows purpose, unlocks, dossier progress and the first unmet prerequisite, with a navigation button. Next achievable project returns to the active project or the first available catalog project. A drafting-bench recipe link opens Crafting without spending materials.

Progress includes active and banked dossiers; opening-age and introductory lesson gates are explained before any start action is enabled. Catalog preview metadata chooses an existing item illustration. Connections use prerequisite depth rather than technology-specific coordinates, with scrolling for larger trees.

Town [Y] uses the full workspace width for its overview. Illustrated cards show restoration benefits, delivered/required materials, exact shortages, credit cost, and the authoritative repair blocker. Full materials alone do not imply readiness: Workshop prerequisites and credits still apply. Repaired buildings show services offline when destroyed or when Town Hall services are suspended. Open a building to return to the pack and delivery controls.

ProjectReports is a read-only presentation adapter. Research/repair commands, saves, reach checks and costs remain owned by the simulation. Future civic projects can reuse these reports and cards.

The HUD groups credits/machine count and research into one status row. Settlement objectives stay visible after introductory lessons; supporting lines are bounded and retain full text in tooltips. Town Hall defense status remains available between waves.

Verification: project_navigation_tests.gd covers browsing versus starting, prerequisite navigation, age gates, banked progress, recipe navigation, surplus materials, credit requirements and disabled services. capture_ui.gd includes Technology, locked Technology and the town overview. Native workspace verification checks minimum-window and fullscreen layout stability.
