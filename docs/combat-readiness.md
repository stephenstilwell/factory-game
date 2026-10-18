# C1: briefing and Nell's rearm service

Implemented 2026-10-17. This is the first playable slice of the [combat roadmap](combat-roadmap.md); later encounter, weapon, operation and finale work is still planned.

Town [Y] → Town Hall now places a defense briefing before the other building details. It shows the next enemy composition, entry pattern, first-clear reward, cancelable warning and explicit opt-in behavior. On wave one, the headline reward is Nell, the quartermaster. Current crew benefits remain in the briefing tooltip.

Live readiness lists Hall health, healthy/loaded local turrets, loaded ammunition, carried ammunition and repair kits, and the workshop reserve. Approach coverage samples one point per announced approach and checks geometric turret range. It is deliberately labeled a sample, not a navigation prediction or victory guarantee. Readiness does not add a permission gate; existing beacon rules remain authoritative.

The first real victory unlocks Nell through the existing validated first-clear relief marker. There is no separate claim transaction or repeatable specialist payout. Nell appears beside the workshop on a vacant derived tile and links to the workshop interaction. The first-arrival dialogue introduces her; an additional replayable workshop conversation explains the service. The victory is retained in Updates with a workshop shortcut.

At the workshop hatch, stock up to 100 ammunition manually, by transfer/drag or through an inserter. Nell's between-defense dispatch fills healthy turret buffers within 28 tiles of the workshop, up to each existing ten-round limit. Stable entity-ID ordering makes partial dispatch deterministic. The UI quotes rounds, number of targets, total shortage and reserve. A short reserve produces an honest partial dispatch.

Dispatch rechecks live state and requires an operational workshop, Town Hall services, interaction reach and an idle defense phase. It rejects warning, active and recovery phases. No ammunition is created, no rounds are delivered beyond range, and no undisclosed credit fee is charged. This is not continuous resupply: belts, inserters and assemblers remain useful during a battle. Oren's repair service is unchanged.

Reserve ammunition stays in the workshop's existing inventory and participates in capacity, withdrawals and normal transfer checks. Save validation permits its bounded reserve only after the saved first victory. Nell survives later failures, while breached civic services suspend her dispatch.

Verification: combat_readiness_tests.gd covers actual first-wave victory, cancellation, advisory reporting, bounded reserve loading, exact and partial transfers, stale clicks, unavailable targets, reach, combat-phase restrictions, breached services, malformed saves, NPC location and interactive stock/dispatch controls. capture_combat_readiness.gd covers the briefing, empty/stocked/dispatched workshop and visible specialist at 1100×720.
