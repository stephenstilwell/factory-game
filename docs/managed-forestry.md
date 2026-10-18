# Managed forestry

Lumber camps retain their four-timber / four-second output and 9 × 9 square range. Each natural tree supports six harvests (24 timber), then becomes a stump. This slows forest loss without accelerating early production.

Supplying the first communal shelter unlocks automatic replanting. Existing camp stumps are planted on the next simulation tick. Trees mature after 1,200 simulation ticks (two minutes), with visible stump, sapling and young-tree growth. Six available trees approximately sustain one continuously emptied camp; smaller or shared groves may pause. Growth continues away from the camp, but pauses with the world.

Camp placement and selection show the exact square and mature/growing/waiting counts. The inspector also reports remaining harvesting work, next maturity and the shelter unlock. Small groves display a recovery status rather than implying the machine is obsolete.

Player clearing and construction remove managed plots permanently. After the shelter, **Replant cleared grove** deliberately restores vacant seeded tree plots in range, excluding buildings, water, deposits and civic/landmark reservations. Use it only where you want forest again.

Plots are sparse frontier state, saved as cell, harvest count and maturity tick. Growth uses timestamps rather than individual actors or per-tree updates. Current saves require this state, including empty plots. Overlapping camps share the same harvest budget.

Future balancing should observe sustained timber demand, available grove density and overlapping camp competition before adding further forestry tiers.
