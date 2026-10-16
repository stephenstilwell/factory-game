# Skills, equipment, and player guidance audit — 2026-10-16

Audited commit d8edcb8. Findings combine current implementation, scripted opening checks, a crafting timing experiment, and calculated ideal action rates. These are not measured human session times. Game balance and save formats were not changed by this audit.

## Verdict

Early XP is not obviously excessive. The system currently has an exponential mastery curve without the activities, reward density, equipment progression, or reminders needed to support it. Automation removes the main repeatable personal XP activities, while automated commissions are mostly one-time awards. The result risks encouraging hand-work grinding instead of building a better settlement.

## Curve

Current cumulative threshold: round(500 * (1.10^(level - 1) - 1)).

| Level | Total XP |
| --- | ---: |
| 10 | 679 |
| 25 | 4,425 |
| 50 | 52,859 |
| 75 | 577,634 |
| 92 | 2,921,662 |
| 99 | 5,693,968 |

Level 92 is 51.31% of level-99 XP. RuneScape's standard curve has 6,517,253 XP at 92 and 13,034,431 at 99 (approximately 50%). Our curve already has the requested general shape; matching its exact totals would not establish good pacing.

At a constant base hand-mining rate of 1.25 iron/copper items per second and 12 XP per item, level 99 requires about 105.4 hours of uninterrupted extraction. Even granting final equipment and the maximum skill bonus from the outset gives a theoretical lower bound of 42.2 hours. Real play includes travel, unlocking equipment, storing goods, and factory work.

Base wire crafting grants 720 XP/minute; base dossier crafting grants 450 XP/minute; base wall crafting grants 1,200 XP/minute; base drafting-bench crafting grants 1,500 XP/minute. Material acquisition is excluded. Complexity, resource cost, usefulness, and reward rate are not consistently aligned.

Exploration grants 20 XP per newly entered chunk and 40 per discovered patch. At four tiles/second along fresh straight terrain, chunk XP alone is about 300 XP/minute, before patch discoveries. It rewards novelty, but lacks higher-tier discovery activities and scalable rewards. Do not interpret a zero-exploration teleporting test fixture as normal walking behavior.

## Scripted opening

Instrumented the existing resource-only opening test. All 92 opening assertions passed. Travel is shortcut, fixtures are scripted, and this is one route rather than a player median.

| Checkpoint | Mining level / XP | Fabrication level / XP | Simulated minutes |
| --- | --- | --- | ---: |
| First drill crafted | 5 / 272 | 5 / 236 | 1.05 |
| Assembler crafted | 18 / 2,050 | 9 / 584 | 9.50 |
| First research completed | 18 / 2,050 | 14 / 1,302 | 11.02 |
| Workshop restored | 23 / 3,572 | 16 / 1,794 | 21.69 |

Early levels provide feedback without exhausting the progression. The fixed automation XP rewards (100 per resource, 120 per recipe, 150 at delivery milestones 1/5/10) become negligible against late thresholds. Town Hall housing stops at nine shipments, so its ten-shipment XP milestone is unreachable.

## Reward quality and timing

Mining/Fabrication milestones are 10, 25, 50, 75, and 99, each adding five percentage points of work speed. Exploration grants two percentage points per milestone and extra survey regions at 25/75. Most individual levels unlock nothing. Increasingly long gaps pay the same small reward.

Confirmed quantization issue: 20 wire batches take 10 seconds at levels 1, 10, 25, 50, and 75, despite displayed Fabrication bonuses of 0/5/10/15/20%. At 99 (+25%) they take eight seconds. Per-job rounding and discarded leftover work prevent many short recipes from benefiting. Continuous hand mining carries work between extractions, so its behavior differs.

Equipment has four tracks and ten purchases total:

| Track | Tiers | Base to maximum | Assessment |
| --- | ---: | --- | --- |
| Boots | 3 | 4.0 to 5.8 tiles/sec | Meaningful +45% base movement; stacks with skills and crews |
| Mining tools | 3 | 0.8 to 0.4 sec/item | Meaningful double base extraction rate, but less relevant after automation |
| Harness | 2 | 6 to 8 tiles reach | Strong convenience; about 78% greater theoretical circular coverage area |
| Pack | 2 | 10,000 to 15,000 items | Weak early incentive: scripted workshop route carries only 47 items at checkpoint |

First tiers require the working drill; second tiers require Supply routes; third tiers require Foundry craft and workshop restoration. There are no equipment milestones tied to Homes for Oldbridge, neighborhoods, later arrivals, or skill mastery. This is enough for an early prototype, not a 1–99 campaign.

## Communication audit

Existing: P shortcut and Engineer workspace tab; skill XP bars; current bonuses; next milestone number; source descriptions in hover tooltips; equipment costs and gating reasons; four-second XP notices; level-up messages pointing to P; one current tutorial/settlement objective; local NPC New story labels; journal replay of already-read chapters.

Missing: persistent actionable equipment reminder, first-unlock introduction, pinned personal goals, exact next-milestone reward previews and XP remaining, global unread conversation indicator, new-project badge after research completes, and a durable activity/inbox view. The journal currently lists seen chapters, not an unread inbox. The equipment tab is secondary to the default Skills tab. A single transient notice can be displaced by another event. Large pack-side layouts also reduce space for character information.

## Recommended sequence

1. Fix crafting work carry with save-compatible state and conservation/cancellation tests, so displayed bonuses affect real batches.
2. Add an equipment-unlocked introduction after the working drill, a quiet Engineer READY indicator for affordable upgrades, and exact current-to-next reward previews.
3. Add one pinned personal goal showing progress, reward, and a link to its relevant screen. Keep the main settlement objective visible separately.
4. Add Journal unread markers derived from currently relevant conversations, preserved until read. Distinguish unread NEW from actionable READY. Let players dismiss noncritical reminders; avoid recurring popups.
5. Add graduated commissions for operating useful supply lines, actual deliveries, and distinct discoveries. Preserve physical consumption and one-time milestone ledgers; avoid unlimited idle XP per machine.
6. Extend equipment through settlement and defense milestones with practical tools (construction reach, repair support, survey capability, expedition utilities), rather than merely larger numbers.
7. Plan meaningful rewards every 5–10 levels before accelerating the whole curve. Suggested bands: 1–25 first session, 25–50 core restoration, 50–75 advanced settlement/defense content, 75–99 optional mastery. These are design targets requiring human playtests, not achieved timings.
8. Revisit XP amounts using measured productive-session rates per skill, not equal XP amounts. Decide desired campaign length before choosing final late-game multipliers. Preserve earned progress when changing published thresholds.

## Guidance references

FFXIV uses a persistent Duty List with journal/map links and distinct icons for story and content-unlocking quests:
- https://na.finalfantasyxiv.com/game_manual/view/
- https://na.finalfantasyxiv.com/uiguide/know/faq-display/interface_npc_icon.html

Distinguishing passive indicators from interrupting notifications:
- https://www.nngroup.com/articles/indicators-validations-notifications/

RuneScape comparison:
- https://runescape.wiki/w/Experience/Table

Local authorities: scripts/data/skill_catalog.gd, scripts/model/skills.gd, scripts/data/character_catalog.gd, scripts/model/character_progression.gd, scripts/simulation/simulation.gd, scripts/ui/character_panel.gd, scripts/simulation/story_state.gd, scripts/ui/story_panel.gd.
