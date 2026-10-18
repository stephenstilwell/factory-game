# The timber opening

Every new game starts with no items, machines or metal-working knowledge. Shelter, crossing and industrial lessons are the only progression path. Older save formats require a new world.

## The playable chain

| Chapter | Production and restoration | What becomes possible |
| --- | --- | --- |
| Timber & Hearth | Gather fallen timber and berries; collect loose stones for a stone axe; hand-cut planks; place a lumber camp, collection post and communal shelter | Eight worker-delivered timber plus shelter supplies welcome the first neighbors |
| Stone & Water | Water-powered timber processing, charcoal production and the recovered Greybank mason pattern | Rebuilding the crossing opens the first iron foundry |
| Iron & Industry | Earned charcoal fuels the first furnace; existing plate, gear, drill and logistics lessons follow | Market restoration, workshops, mechanical industry, later copper and research |

A few loose stones support primitive tools and hearth construction. Iron, copper and coal deposits remain visible natural features, but cannot be hand-mined before Iron & Industry. Furnace and mechanical recipes/buildings are also locked. Survey camp salvage and the industrial depot cannot bypass the opening with free metal goods.

## Timber and first automation

Three fallen-log piles beside spawn contain twelve timber each. Two berry patches contain eight food each. Additional finite forage sites derive from the world seed in 16x16 chunks. Hold RMB to gather. A stone axe carried in the pack halves fallen-log/berry gathering time. Gathering (the stable saved `mining` skill) gains 3 XP per forage item and 6 per felled tree; its work-speed milestones apply to these actions. Existing Mining levels and XP are preserved. Felling a real grove tree returns four timber if the entire yield fits in the pack. Building clears its tile without awarding timber.

Recipes have no metal inputs:

- Stone axe: 2 timber +2 stone.
- Hand-cut planks: 1 timber makes 2 planks.
- Lumber camp: 6 timber +1 stone axe, which becomes the crew's tool.
- Handcart collection post: 4 timber +4 planks.
- Communal shelter: 8 timber +4 planks.

A camp harvests one actual tree within four tiles in each axis every four seconds, producing four timber. Cleared trees stay cleared. A collection post collects up to four real timber from the nearest healthy camp within ten tiles every four seconds. X collects its stored timber. Each post dispatches independently; a full store cannot duplicate or discard the source stock. Exhausted groves require relocating the camp, not manually refueling it.

Worker paths are lightweight visual representations of distance-based service, rather than a general NPC pathfinding or needs simulation. There are no hidden worker inventories, hunger timers or wages. Returning settlers are shown at a supplied shelter.

## Shelter restoration

Open **Y** beside a healthy communal shelter. Once workers have delivered eight timber cumulatively, supply **12 timber, 8 planks, 4 gathered berries and 8 stone** from the pack. All costs are paid together. This welcomes the first neighbors, grants 150 Fabrication XP once and establishes Stone & Water. The first eight worker deliveries also grant one 100-XP Fabrication milestone.

## Stone and water

Build a waterwheel sawmill from 8 timber, 8 stone and 4 planks beside the marked old millrace south of spawn, near (24, 28). It uses no fuel and turns two timber into six rough planks in four seconds. A charcoal clamp costs 6 stone and 4 planks, and turns three timber into two burner-fuel units every six seconds without fuel inputs.

Collection posts within five tiles feed the two processors from their physical timber stores. Place a post between grove and millrace, or reclaim and move one. Existing inventory controls still work for manual loading and output collection. Production pauses on missing inputs, damage or full output.

The watercourse is shallow and passable. It provides a real placement requirement for the mill, but is not a fluid or flooding simulation. Scenery and forage avoid its water tiles.

Recover Greybank Quarry's mason pattern through L. Produce twelve water-sawn planks and four charcoal, then bring **30 stone, 12 planks and 4 charcoal fuel** to the shelter and complete the crossing project with Y. It restores the visible bridge, grants 250 Fabrication XP once and opens Iron & Industry. Produce some additional charcoal to fuel the first furnace.

The original furnace lessons resume here. Their ore-and-fuel objective accepts charcoal produced from timber. They still teach actual smelting, collection and building construction. No goods, automatic machines or completed research are awarded by changing ages.

## Persistence and performance

The required early section stores chapter, finite forage depletion and delivery/sawing/charcoal totals. Civic age must agree with the chapter. Industrial lessons always use charcoal-compatible goals; there is no alternate opening flag.

Loaded age state must agree with the settlement age, productive prerequisites and quarry discovery. Primitive buildings and queued recipes cannot predate their chapter; a saved watermill must remain beside its watercourse. Existing currency reconciliation includes Stone/Industrial market premiums and preserves all previous credit accounting.

Timber and industrial hotbars have separate preference files. Switching chapters keeps customized industrial slots intact. Ore generation and richness are unchanged. New scenery uses visible chunks, the existing tree-candidate cache and shared ellipse texture, with no permanent Node for each resource or worker. Ambient/reduced-motion settings suppress decorative worker animation.

Verification includes a complete empty-pack playthrough to the first iron plates using only gathered/crafted/produced resources, seed-stable opening resources, finite depletion, ore/salvage gates, automatic worker supply, physical reclamation, exact save roundtrips, invalid metadata, obsolete-format rejection and the real Town UI. Native captures use `tests/capture_timber.gd`.
