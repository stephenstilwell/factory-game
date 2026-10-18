# Regional identity: B1

Implemented 2026-10-17. This deepens the existing Lost Orchard and Greybank regions; it does not add new regions or change their gameplay rules.

- Shared presentation definitions retain established region centers, radii and music contexts. Ground color blends near borders.
- Orchard gains blossom details, garden remnants and tended scenery derived from existing growing-bed progress.
- Greybank gains fir silhouettes, slate scenery and worksite masonry, flags and lights derived from actual road deliveries.
- HUD status names the current region. Bounded ambient particles and three cached ambient sound palettes distinguish general woodland, orchard and quarry. Existing region music is retained.
- Decoration is deterministic and restricted to the visible area, capped at 32 ornaments. It yields to buildings, original ore masks, trees, landmark approaches and managed forestry. It creates no collision or resource rewards.
- Restoration presentation reads existing counters; no new save fields or migration are needed. Existing ambient/reduced-motion options remain available.

## Verification

The focused regional suite checks deterministic bounds, safe placement, collision neutrality, unchanged save encoding, transition weights, audio data and HUD/context switching. Native before/after captures cover both sites at 1100×720. Automated waveform checks establish distinct data, not a subjective listening assessment.

Full regression: 1,538 checks, zero failures (including 19 focused regional checks). Native workspace layout checks cover minimum window and 4K transitions. Performance remains bounded by visible-area sampling; no measured FPS improvement is claimed.

## Next

[B2: Reedwater Marsh](reedwater-marsh.md) now implements physical water, movement/building/navigation rules, a safe causeway and a lodge restoration/workshop loop. Dedicated marsh music, dialogue and broader landscape depth remain open; B3 Glassfields is the next major biome slice.
