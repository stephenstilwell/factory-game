# Factory expansion

The next factory goal is to manufacture its own expansion supplies, route them around obstacles, and keep Oldbridge supplied. New games still begin empty and follow the original learning guide.

## Factory workbench [F]

Research shows prerequisites and unlocks. Logistics I costs 10 science packs. Afterwards choose **Advanced routing** (20 packs, splitter junctions and underground conveyors) or **Metallurgy** (20 packs, steel). **Construction engineering** follows Metallurgy (25 packs, construction kits). A selected project is shared by all labs. Switching projects banks completed science investment; it does not refund or duplicate packs. The next available project starts automatically when one completes, and F lets you choose another.

Production shows actual made, consumed, and net item rates over up to 60 simulated seconds, including manual production, machine ingredients, fuel, science, building placement, and dispatches. Transfers do not count as consumption. History begins fresh on load and pauses with simulation time; it is not an offline estimate or a theoretical capacity graph. Machine inspection shows missing ingredient quantities and nominal recipe batches/minute. The dashboard summarizes stalled machine statuses and town demand.

## Routing and automated construction supplies

- Splitters occupy one tile, accept a single item, and alternate between the forward and clockwise/right output. If one is blocked, the other is used. R rotates both outputs. This is a junction rather than Factorio's two-lane splitter.
- Underground conveyors are separate entrances and exits, each using one building item. Select the building and press G to choose its mode; inspect an existing end to change it. Both ends face the flow direction. The nearest matching end must be an exit within six tile centers; another entrance with the same facing blocks pairing. Intervening surface belts and machines are independent. Items move directly between end inventories in one normal belt hop; there is no hidden in-flight inventory.
- Ordinary belts, splitters, and underground ends move every two ticks; fast belts every tick. Snapshot occupancy, destination reservations, and persistent receiver round-robin cursors preserve items and prevent merge starvation.
- Assemblers now produce every placeable building, including drills, furnaces, inserters, assemblers, labs, walls, turrets, and advanced belts. Use the machine's recipe picker. Existing learning, settlement, and technology gates still apply. Input quotas accommodate recipes requiring more than ten of one ingredient.

## Settlement production goals

| Restored landmark | Dispatch goods | Duration | Benefit |
| --- | --- | --- | --- |
| Trading post | 4 iron plates + 1 gear | 30 seconds | 10 credits |
| Engineers' workshop | 2 gears + 4 wire | 40 seconds | 12 credits |
| Town Hall | 2 construction kits + 4 steel + 4 copper plates | 60 seconds | Housing progress |

A construction kit is assembler-only: 2 steel + 2 gears + 4 wire, four seconds. Each three housing deliveries restores a neighborhood, adds cottage/resident details to the Hall terrace, and grants another four base coal work ticks (+5% of the original 80). Three neighborhoods provide +15%, added to the workshop's +20%. Services suspend during a Town Hall breach.

Every shipment consumes physical stock at dispatch. Missing supplies pause future growth/income, and existing restoration remains. Housing finishes after nine deliveries: dispatch and acceptance stop, and any buffered supplies can be withdrawn. Trading post and workshop contracts remain recurring. Use their marked hatches with inserters to automate deliveries; manual buttons also work. This is not a continuous population survival simulation.

First automated extraction of each resource grants 100 Mining XP; first automated completion of each recipe grants 120 Fabrication XP. Civic deliveries 1, 5, and 10 grant 150 Fabrication XP each per site. Persistent milestone keys prevent repetition through reclamation or save/load. Housing ends before its tenth-delivery milestone.

## Reusing layouts

1. Ctrl+C, then drag a rectangle around up to 256 machines (64×64 area maximum).
2. Ctrl+V, then click to stamp ghosts. R rotates the module. Esc or Q exits planning.
3. Shift+click with a building selected places one ghost without requiring the item in your pack.
4. Press B to build reachable ghosts using actual building items from your pack. Unaffordable or distant ghosts remain.
5. Right-click a ghost to remove it, or clear plans through F → Plans.

Plans copy direction, selected recipe, and tunnel mode. They do not copy inventory, fuel, health, production progress, or resources. Stamps validate atomically against landmarks, researched content, existing buildings, and resource deposits for drills. Up to 512 ghosts persist in saves; the clipboard is session-only. There are no construction robots, shared supply storage, or automatic remote building.

## Foundation

Transport routing, construction plans, production history, and research definitions are separate from presentation. Stable IDs and optional validated v2 save fields preserve older worlds. End modes, merge/splitter cursors, research investments, commission ledgers, civic deliveries, and ghosts survive save/load. Production history and editing gestures are transient.

Further work should expand production dependencies and energy before adding fluids or trains. This pass supplies layout decisions and a reason to scale production, while retaining the game's settlement identity.
