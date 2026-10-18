# A Town Worth Returning To

A finite Iron & Industry chapter connects the game's existing systems to a civic outcome. It appears prominently in Town [Y] after Town Hall restoration and becomes the field objective. Combat and beacon waves are not prerequisites.

1. **Pantry for returning families:** build at least one Lost Orchard growing bed; deliver 12 fresh produce and 16 planks to Town Hall.
2. **Light the working district:** research Foundry craft; deliver 24 wire and 12 gears; accumulate 30 simulated seconds of actual electric machine work within 12 tiles of Town Hall's origin. Idle generators, disconnected drives and stalled machines do not count. Multiple machines count a tick only once. Progress is retained through pauses and shortages.
3. **Homecoming fair:** finish all nine Greybank road loads, restore the first neighborhood through three existing housing shipments, and deliver 24 produce, 24 planks and 24 stone.

Commissioning is an explicit action at Town Hall's delivery hatch. Materials are consumed once, on success, and recorded in production metrics. Inserters and manual inventory transfers can fill the existing hatch. Chapter goods do not overlap housing-contract goods, so the two routes cannot silently consume one another's allocations. The UI provides regional/Technology links, exact buffered quantities and the first unmet requirement.

The payoff is permanent fair decorations and visitors at the restored town, a new replayable Ada conversation, milestone feedback/history, and a public fuel depot at Town Hall. Supply real coal/charcoal through the same hatch, up to 100 buffered coal. The depot moves at most one coal per second to eligible non-electric drills/furnaces within 12 tiles, targeting a small three-coal reserve. It creates no fuel or income, and a disabled Town Hall suspends it. Fuel is still consumed only by actual burner work. Decorative lamps are a commissioning milestone, not additional simulated electrical consumers.

The chapter has no repeatable currency/XP reward to farm. Its reward is a different relationship between existing systems: Orchard feeds the town, Greybank gives it a road, industry powers useful work, housing gives people somewhere to live, and the town helps supply the factory afterward. The remaining neighborhoods and voluntary defenses remain available.

Saved state contains phase, counted work ticks and the last counted simulation tick. Current-schema validation rejects invalid phases, impossible timers and missing chapter prerequisites; physical inventory and existing economy reconciliation still apply. The required chapter save field follows the project's single-current-schema development policy: older development saves without it require a new world.

Verification: homecoming_tests.gd covers real material delivery/consumption, reach, power conservation/proof, idle and multi-machine behavior, housing isolation, regional requirements, optional combat, public fuel conservation, damage suspension, exact save continuation, malformed state and menu navigation. capture_homecoming.gd checks the active project, ready phase, fair, depot and conversation at 1100×720.
