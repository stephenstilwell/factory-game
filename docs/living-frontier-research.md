# A living frontier for Oldbridge

Research and design recommendation, 2026-10-16. This document proposes future work; it does not describe implemented trees, collectibles, expedition rooms, or ecological simulation.

## Current diagnosis

Oldbridge already has seeded finite ore, surveys, Exploration XP for new chunks and resource patches, restored civic landmarks, authored keepers, porch residents, neighborhoods, voluntary beacon defenses, and a journal with personal goals. The code review found decorative grass, flowers, stones, roads, and ambient effects, but no substantial tree layer, regional ecology, collectible catalog, exploration landmark system, or expedition interiors.

This leaves three distinct gaps:
1. The view lacks large natural silhouettes, regional variation, small creatures, and everyday human activity.
2. Exploration rarely reveals a new kind of opportunity; its primary practical destination is more ore.
3. Few discoveries visibly change Oldbridge or the wider region.

More scenery can address the first gap immediately. Meaningful destinations and persistent consequences must address the others.

## Research and lessons

| Reference | Documented approach | Application to Oldbridge (our design inference) |
| --- | --- | --- |
| Satisfactory | Expeditions, wildlife, traversal equipment, and artifacts that affect production | Discoveries should return practical capabilities to the factory; silhouettes and sounds should invite detours |
| Core Keeper | Distinct ecosystems, relics, inhabitants, bosses, farming, and automated production | Give regions different activities and discoveries; support quieter excursions as well as optional danger |
| Techtonica | Abandoned facilities, hidden caves, recoverable technologies, and a factory-linked mystery | Ruined infrastructure can teach engineering and explain what happened to the old network |
| Spiritfarer | Exploration and resource production support relationships with memorable people | A person coming home can be a stronger reward than another anonymous material stack |
| Wildmender | Collect plants, cultivate a home, and visibly restore a damaged environment | Let exploration bring color and life back to Oldbridge and reclaimed routes |

These are design references, not a proposal to reproduce their content or add all their systems.

Sources, accessed 2026-10-16:
- Satisfactory developer description: https://store.steampowered.com/app/526870/Satisfactory/?l=english
- Satisfactory artifact reference: https://satisfactory.wiki.gg/wiki/Somersloop
- Core Keeper developer description: https://store.steampowered.com/app/1621690/Core_Keeper/?l=english
- Techtonica developer description: https://store.steampowered.com/app/1457320/Techtonica/?l=english
- Spiritfarer developer description: https://thunderlotusgames.com/games/spiritfarer/
- Wildmender developer description: https://www.wildmender.com/
- Factorio's account of making Fulgora's ruins support distinct gameplay rather than repeating familiar resource processing: https://www.factorio.com/blog/post/fff-399

## Recommended identity

A factory and settlement restoration game where expeditions reconnect a scattered community.

The loop: notice a landmark or a clue, explore it, solve a small problem, bring something or someone home, then use production to make that change permanent. Repaired sites should become inhabited or useful destinations rather than disappear into an opened-chest marker.

## Layer one: a place that looks and sounds alive

Start with tree groves, shrubs, reeds or dry grasses, orchard remnants, fallen trunks, and stronger ground palettes. Keep woodland, open meadow, abandoned orchard, and old industrial ground visually distinct. Add bounded ambient birds and butterflies, local birdsong and insects, and gentle leaf motion. Respect pause and reduced-motion/ambient preferences.

Keep the opening build area open and resource silhouettes readable. Small vegetation can yield to building placement. Larger trees should be clearly removable before they block construction. Do not add mandatory chopping to the existing stone/furnace opening. Timber production should wait until there are useful optional construction or restoration recipes for it.

Restored neighborhoods should show more activity: garden work, laundry, residents walking short routes, and a cart animation tied to an actual completed shipment. These can be lightweight visual schedules rather than a full needs/pathfinding simulation.

## Layer two: discoveries with different rewards

Use a small catalog of authored site patterns, distributed by the world seed. Ordinary finds can repeat in appearance; named story sites and unique unlocks should be authored and trackable.

| Proposed destination | Interaction | Proposed lasting reward |
| --- | --- | --- |
| Lost orchard | Recover a cutting and its caretaker's note | Orchard/garden restoration project; fruit trees and a returning gardener |
| Surveyor's camp | Follow field notes to a marked viewpoint | Exploration XP, a useful regional resource lead, and an optional survey improvement |
| Collapsed waystation | Supply repair materials and reopen the route | A visible traveler stop and new trade opportunity |
| Ruined sorting depot | Repair a small cargo-routing arrangement | A factory-related optional design or civic logistics improvement |
| Silent relay | Investigate records; choose when to reactivate a guarded section | Beacon-chain story progress and a new restoration objective |
| Family keepsake | Recover a named object and return it | A conversation, a named home display, or a settlement decoration |

Small salvage caches can contain limited ordinary components and supplies. They should supplement production, not replace the first factory or create an endlessly farmable shortcut.

Collection categories should have clear purposes:
- Plant cuttings unlock visible garden varieties.
- Field notes reveal useful leads and optional techniques.
- Keepsakes restore named pieces of town history.
- Specialist recoveries unlock a new capability or restoration project.

Keep major rewards predictable and previewed. Avoid a large random-junk inventory, generic rarity ladders, or requiring every collectible to progress through core research. First-time landmark XP should be distinct from repeat walking XP and recorded once.

## Layer three: optional engineering expeditions

Instanced areas fit as abandoned municipal works: sorting rooms, pump houses, workshops, and relay chambers. The proposed first challenge is an old sorting depot: route a small amount of cargo to labeled destinations using a supplied selection of existing conveyors, junctions, and inserters.

Aim for a short authored encounter rather than a full dungeon campaign. A later chamber can include dormant old-network constructs, awakened only by a clearly signposted activation. This preserves the existing voluntary-risk theme and gives the enemies a reason to be there.

Implementation requirements before true interiors:
- Always permit leaving and preserve puzzle progress.
- Keep loaned puzzle items separate from the player's real inventory.
- Award the completion reward once across retries and reloads.
- Define factory time explicitly; recommend that the overworld continues operating while exploring.
- Prevent entering a room during an active/warning beacon defense, rather than surprising an absent player with an unattended breach.
- Give puzzle completion a visible overworld consequence, such as a reopened depot or returning specialist.

Prototype one overworld puzzle first. It can validate whether engineering excursions are enjoyable before adding scene transitions, separate room state, and travel/save complexity.

## First playable slice

Deliver a small coherent loop before expanding the content count:
1. Seed-stable groves and regional vegetation, plus ambient birds.
2. Three nearby discoveries: a survey camp, an orchard, and a sorting-depot ruin.
3. Small one-time Exploration/salvage rewards and one visible town gardening reward.
4. A discovery journal with known leads, claimed rewards, and one compass target, using existing journal/guidance patterns.
5. One short depot-routing puzzle that unlocks a useful civic improvement.

Suggested playtest: a ten-minute excursion should include a recognizable landscape change, one useful discovery, one decision, and something visible to bring home. That is a design target, not a measured optimal density. Tune walking intervals and sightlines using real movement speed and human playtests.

## Foundation and compatibility

Separate decorative scenery from authoritative interactive landmarks. Cache seeded scenery by chunk and bound wildlife to visible regions. Avoid one permanent Node per plant.

Landmarks need stable region/slot/content-version IDs and saved states for discovery, claimed supplies, puzzle progress, restoration, and reward ownership. Keep one-time item/reward delivery atomic when the pack is full.

Use a separate scenery/site generator version. Do not regenerate ore or move existing factories. Protect the tutorial, civic footprints, player spawn, occupied buildings, and existing resource access when adding sites to old saves. Imported worlds may need conservative site placement or unoccupied frontier-only landmarks.

Keep future collectible IDs and content definitions separate from rendering. Restoration effects should derive from saved site state, so repeated loads and visits cannot stack them. Avoid marking every destination on the map before discovery; silhouettes, paths, sounds, and NPC leads should do some of the work.

## Priorities

First: vegetation, ambient life, and worthwhile overworld destinations.
Next: discoveries that visibly restore the settlement or a remote site.
Then: one engineering puzzle and, if it succeeds, a small interior system.
Later: deeper ecological recovery, specialist residents, and occasional optional combat expeditions.

The immediate goal is to make an ordinary walk interesting and make returning home feel different.
