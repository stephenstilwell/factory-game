# Illustrated workbench and rewards

The workbench now separates recipe browsing from the selected product's purpose, materials, complete raw cost, automatic intermediate sequence and craft controls. The left preview reuses the game's vector machine art on a small drafting grid. Craft controls stay outside the scrolling details.

Ingredient cards use both text and color: IN PACK, IN QUEUE, AUTO-CRAFT or MISSING. Missing hand-craftable intermediates remain an optional individual action, while Craft 1 still queues the complete chain in one click. A full breakdown is available without making the default detail view a long paragraph.

The live queue names the current job, estimates its remaining work time and shows the intermediate order. Finished output blocked by pack space explicitly waits rather than claiming success. Existing stable job-ID cancellation and refund tooltips are retained.

## Reusable visual components

- showcase.gd owns a fixed-size preview, a short selection highlight and at most five material-colored flight dots after an accepted craft.
- showcase_art.gd draws UI-owned civic before/after snapshots and equipment illustrations. It never changes a live building.
- completion_card.gd presents one expiring reward card, combining repeated deliveries of the same item. Menu rewards use an inline card; crafts completed outside menus use the HUD.
- Restoration inspection places the ruined and rebuilt building beside the actual service reward. Equipment inspection pairs custom illustrations with the real before/after stat.

All effects are bounded, change drawing properties rather than control minimum sizes, and honor Reduced motion. Scroll containers retain reserved scrollbar width to avoid the previous camp-inspector layout loop.

## Completion contracts

World.hand_craft_completed(recipe_id, delivered) is emitted only after real output enters the pack. Fully consumed intermediates do not emit a delivery; surplus that actually enters the pack does. Cancellation and blocked output emit no completion.

World.equipment_upgraded(id, rank) follows a successful material-consuming purchase. World.settlement_restored(id) follows a successful authoritative landmark restoration. Existing crafting and success audio cues are reused.

Scene composition disconnects these handlers from the old world on rebinding and clears transient cards. A restoration reward waits until its conversation closes so it cannot expire behind the dialogue; deferred rewards also check the world instance before presentation. Rewards are presentation only and cannot grant materials, XP or upgrades.

No save version or balance change is needed. All presentation state is transient.

## Verification

workbench_presentation_tests.gd covers rejected requests, full-pack waits, consumed intermediates, actual delivery, stale equipment purchases, world switching, reduced motion, expiration, HUD delivery and restoration conversation ordering.

capture_ui.gd captures crafting, queue progress, completed output, restoration, equipment and the existing menus. Add --small after -- to review the minimum supported logical window size. verify_workspace_layout.gd checks repeated Crafting -> camp inspection in a native window and fullscreen.
