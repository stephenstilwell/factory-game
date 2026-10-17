# Greybank road restoration

Recover Greybank Quarry's mason pattern, finish the primitive crossing (if your world
uses that opening), and restore the trading post. Open Discoveries [L] and select
Greybank Quarry. Recovered Greybank now shows the road project instead of repeating its
one-time salvage reward.

## Task and payoff

Supply nine physical loads at the quarry entrance. Each load consumes 20 stone and
4 planks, then takes 60 simulated seconds to reach the roadbuilders and earns 12 credits.
Every third arrival restores another visible third of the road from the workshop toward
Greybank and awards 300 Fabrication XP once.

Restored sections grant +15% movement while within 0.75 tiles of the road centerline.
This multiplier applies alongside equipment, skill and morale bonuses; it does not speed
up travel elsewhere. The route appears in the world and on the chart. It is a travel aid,
not a collision obstacle, automatic tree remover or terrain/resource rewrite.

Full project: 180 stone, 36 planks, 108 credits earned, 900 Fabrication XP and three road
sections. The finished project stops accepting goods and does not pay further rewards.
This is an optional finite restoration goal, not infinite passive income.

## Manual and automated delivery

Stand beside the quarry's marked entrance and press Deliver up to one load. Partial
deliveries are allowed. Withdraw buffer returns uncommitted goods if your pack has room.
A departing load consumes its goods immediately; cargo already in transit cannot be
withdrawn.

The same entrance is an inserter receiver. Discoveries displays exact coordinates:
place an inserter one tile west of the hatch, facing east, with its pickup source another
tile west. Feed stone and planks using existing storage, conveyors and inserters.
The buffer holds up to three future loads and accepts only remaining project demand,
accounting for the load in transit. It will not strand extra supplies at completion.

Healthy market and Town Hall services are needed for dispatch and transit progress.
Damage that closes services pauses the timer without consuming another load or losing
already committed cargo. Pausing gameplay also freezes progress; no offline timer exists.
The project does not add enemies, force a wave, change ore generation or move old factories.

## Persistence and verification

quarry_project saves its bounded goods buffer and remaining shipment ticks. Settlements
save road_deliveries, which reconciles credit earnings. Stage milestone acknowledgements
must match delivered road sections, preventing reloads from granting XP twice. Older saves
default to an unstarted road project.

tests/quarry_project_tests.gd checks manual delivery/withdrawal, physical commitment,
funded timers, save continuation, exact finite rewards, local speed boundaries, completion
limits, old-save compatibility, inserter automation and Discoveries controls. Native
captures verify the project at 1100×720 and the visible route in the world.
