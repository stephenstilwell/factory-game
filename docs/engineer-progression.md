# Engineer progression and guidance

This pass follows the findings in [the progression audit](progression-audit.md). The published XP thresholds remain unchanged; saved XP and purchased equipment are preserved. Level 92 remains 51.3% of the XP needed for 99. This is a stronger progression foundation, not a claim that the current campaign now contains a complete 99-level endgame.

## Accurate hand-work bonuses

Hand crafting carries earned surplus work between queued jobs. Short recipes benefit from fractional skill speed instead of rounding every batch separately. Surplus cannot accrue during idle time or while output waits for pack space. Empty queues and cancellation clear it; partial jobs and cross-job surplus survive saving.

For 20 wire batches, level 10's +5% bonus now reduces work from 10 seconds to 9.6 seconds. The recipe panel shows average time per batch; individual actions still occur at fixed simulation ticks.

## More frequent, bounded skill rewards

Mining and Fabrication reward levels: 5, 10, 15, 20, 25, 35, 50, 65, 75, 85, 90, 95, 99. Total speed bonuses are respectively 2, 5, 7, 9, 10, 12, 15, 18, 20, 22, 23, 24, 25 percent.

Exploration rewards levels 5, 10, 15, 25, 35, 50, 65, 75, 85, 99, adding one percentage point each, capped at +10%. Levels 25 and 75 also expand surveys. The original 10/25/50/75/99 bonuses are retained, with useful intermediate rewards added. There are no new skill requirements for existing equipment.

Engineer [P] shows visible earning instructions, exact XP to the next reward, its resulting total bonus, and an expandable full reward ladder. Milestone level-up messages state the earned benefit.

## Productive automation commissions

Actual automated extraction and completed recipe batches count toward shared, saved per-resource/per-recipe commissions:

| Completed batches | XP reward |
| --- | ---: |
| 10 | 150 |
| 50 | 400 |
| 250 | 1,000 |
| 1,000 | 2,500 |
| 5,000 | 6,000 |

These supplement first-line commissioning. Multiple machines contribute to the same counter; rebuilding or reloading does not restart it. Blocked machines, transfers, canceled crafts, and standing idle earn none. Old saves begin these new counters at zero without retroactive payments.

Civic delivery rewards expand from shipments 1/5/10 to 25/50/100/250/500, paying 300/600/1,200/2,500/5,000 XP respectively. Housing additionally pays 500/1,000/1,500 XP when neighborhoods are restored at deliveries 3/6/9. Housing still finishes at nine deliveries; there is no unreachable required tenth-housing reward. Existing old ledger entries remain valid.

The skills view previews progress and reward for up to three active supply-line commissions.

## Equipment over a longer campaign

Seventeen purchases across six tracks replace the previous ten purchases across four tracks.

- Boots retain existing tiers and add 6.2 tiles/second at tier four.
- Mining tools retain existing tiers and add 0.3 seconds/item at tier four.
- Tier four requires all three neighborhoods and five rescued beacon arrivals; it uses steel, gears, and construction kits.
- Warden repair rig: 65, 80, then 100 health per physical repair kit. Requires Town Hall, then one neighborhood, then three rescued arrivals, alongside the usual technology requirements.
- Frontier survey instruments: +1 then +2 survey regions, stacking with Exploration. Requires Town Hall, then two neighborhoods.
- Harness and pack tiers retain existing values and costs. Starting capacity is preserved for compatibility; capacity remains a weaker early incentive than boots or reach.

Equipment cards show current-to-next stats, complete material costs, exact locked conditions, and READY when installable. Purchases remain atomic, permanent, and material-funded. Effective repair power and combined survey range are used by real world commands and shown in relevant inspectors.

## Personal goals and quiet guidance

- The first working drill introduces Engineer [P] and suggests first boots as a personal goal.
- Track a specific equipment tier or the next skill reward; one personal goal appears on the world HUD with live requirements, reward, and completion state. Click to inspect the Engineer or dismiss with the close button.
- Engineer is a top-bar button. Gold emphasis indicates newly unlocked or affordable next tiers; the tooltip explains counts. The equipment tab distinguishes NEW from READY. Looking at equipment acknowledges new tiers while affordable upgrades remain READY.
- Journal and Technology use small gold indicators. Technology's indicator represents unseen available projects after completion; inspecting Technology acknowledges them.
- Journal lists unread relevant conversations as NEW and keeps replay entries. Closing early retains unread state; reaching the final page clears it on close.
- The journal also shows the last ten messages from a saved, bounded 40-entry activity history. This retains missed milestone rewards, introductions, and factory notices.
- Engineer gets the full workspace width. All three skill summaries and tracking actions fit at 1100x720 and 1280x800.

Goals, acknowledgements, activity history, commission counters, and crafting surplus are required save sections. New games reset them. Loading validates IDs, ranks, milestone targets, credit bounds, and history timestamps. No offline rewards or repeated reminder popups are introduced.

## Validation

Regression checks cover short-craft timing at six levels, physical output conservation, cancellation and save continuation, productive versus blocked commission XP, upgrade gates and actual repair/survey effects, late-game equipment saves, goal and notice persistence, unread conversation completion, malformed metadata, and menu fit at both supported resolutions. Native captures are generated by tests/capture_progression.gd.
