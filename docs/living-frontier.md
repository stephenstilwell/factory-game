# The living frontier: first playable slice

Extended with a fourth landmark, two landscape regions, and [Timber → Stone town progression](settlement-ages.md).

Implemented after the [research and design pass](living-frontier-research.md). This is an overworld exploration loop: walk out, find a place, recover something useful, and see a change back in Oldbridge.

## Controls and first excursion

Open **Discoveries [L]**, or use its button in **Journal [J]**. Three rumors offer directions and a trackable entrance. Tracking draws a world compass marker; it does not teleport the player or award discovery XP. Landmarks can also be found naturally and clicked to inspect.

Walk within nine tiles of an entrance to discover it (+75 Exploration XP once), then within normal interaction reach to recover its reward. The factory keeps running while the discovery panel and sorting table are open. Active/warning beacon defenses disable claiming and puzzle edits.

New games still start empty. The stone/furnace tutorial, ore positions, recipe costs, and first factory remain intact. Exploration supplies are earned by making the trip; no reward is required for core progression.

## Three destinations

| Landmark | Interaction and reward |
| --- | --- |
| Surveyor's Rest | Recover field notes: 200 Exploration XP, 10 coal, 4 gears, 6 wire, and a permanent +1 survey region |
| The Lost Orchard | Recover Iona's apple cutting: 250 Exploration XP and a visible community garden with a tending resident once the trading post is restored |
| Old Sorting Depot | Solve its cargo-routing table, then restore it: 500 Exploration XP and +1 Supply Hearth coverage while the trading post and regional services operate |

The note and cutting are saved discoveries, not extra inventory stacks. Salvage delivery is atomic: a full pack leaves the bundle unclaimed. Visiting, claiming, reloading, and repeated button clicks cannot repeat rewards.

The garden uses a vacant nearby plot. Existing buildings, ore, and trees take priority; a crowded market falls back to planted window boxes. The gardener is a lightweight visual resident, rather than a new dialogue or needs simulation.

Restored depot runners stack with returning beacon crews. Normal hearth coverage can therefore reach 13 tiles (8 base +4 returning crews +1 depot). Workshop and neighborhood fuel bonuses are unaffected. Damage to the post or a breached Hall suspends runners; recovery restores the derived effect without repurchasing it.

## Sorting puzzle

A loaned 7x5 table has two labeled sources (A and B), matching docks, a central wall, and fourteen conveyors.

- Left-click a tile to place an east-facing conveyor or rotate it clockwise.
- Right-click to remove it.
- Clear table resets the loaned layout.
- Test cargo routes traces both paths. Routing to the wrong dock, leaving the board, gaps, and loops fail safely.
- Restore depot becomes available only when both routes reach their matching docks.

No real player inventory, factory machine, coal, or ammunition enters this table. Puzzle progress saves; leaving is always possible. A recovered depot retains its completed layout and cannot issue another reward. This prototype establishes the engineering excursion before any separate instanced-room system.

## Landscape and ambient life

Seed-stable groves use three vegetation palettes and different densities. Trees have trunks, canopies, shadows, and restrained leaf movement. Birds and butterflies are visual creatures, bounded to at most twelve visible actors; quiet synthesized birdsong uses one spatial voice on the existing SFX bus.

Groves are passable. Hold right mouse for 0.6 seconds to clear a tree, or place a building to clear its tile automatically. Clearing is saved and gives no farmable materials/XP. Original ore masks exclude trees even after depletion, so exhausting ore does not suddenly grow a tree.

Trees avoid civic/landmark footprints and the immediate spawn clearing. Nearby canopies fade around the player and while building. Reduced motion stops foliage and wildlife movement; the ambient setting disables wildlife/birdsong. Pause freezes animation and silences ambient chirps. Volume remains controlled by SFX.

Rendering visits visible cells; there is no permanent Node per plant or a simulation of every distant animal. Ground chunks retain their existing cache/eviction behavior. Rendering cannot grant XP, change reward ownership, or mutate depletion.

## World generation and saves

The required frontier section stores landmark IDs/positions, discoveries, cleared ground, managed forestry, puzzle state and tracking. Scenery uses independent seeded hashes; the game has one ore generator.

New landmarks are deterministic for a seed. Migration anchors them relative to the existing trading post, searches bounded vacant space, and protects occupied machines, live deposits, civic land, the player, and the Hall defense approach. Existing buildings never move. Landmarks may remain unavailable if a heavily occupied save has no safe placement in the bounded search.

Current saves require all landmark and forestry state. Missing data is rejected. New games reset frontier progress; loading never inserts sites into a factory.

Validation rejects unknown IDs, overlapping occupied footprints, invalid tree coordinates, duplicate conveyor cells, out-of-board positions, invalid orientations, claimed-undiscovered sites, and a recovered depot without valid cargo routes.

## Verification

Tests cover deterministic placement across five seeds, empty starts, reserved footprints and accessible entrances, one-time XP and physical salvage, full-pack atomicity, actual survey/hearth effects, service suspension, puzzle budgets and completion, save continuation, invalid metadata, scenery clearing, incomplete-save rejection, UI input isolation, tracking, and rendering state conservation.

Native review:
```powershell
godot --path . --script res://tests/capture_frontier.gd
```

Captures in .godot/verification/frontier_*.png show the opening, all three landmarks, market garden, and empty/solved routing panels at 1280x800 and 1100x720.

New regional loop: [Reedwater Marsh](reedwater-marsh.md) adds the fifth discovery, a physical causeway and a maintenance lodge. Pre-marsh saves require a new world.
