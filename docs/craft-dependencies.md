# Dependency-aware hand-crafting

Craft 1, Craft 5 and Max now include missing hand-craftable intermediate ingredients. For example, a lumber camp with no stone axe needs eight timber and two stone: one click queues the axe, then the camp. Existing axes in the pack are used first.

The preview lists the complete pack reservation and queue order. Time and XP include the newly added intermediate jobs; existing queued work can still delay completion. Batch counts refer to the requested target recipe. The twenty-job limit includes every intermediate.

Already queued outputs can be promised to a later craft if they have not been allocated elsewhere. Surplus from a multi-output recipe can serve subsequent jobs; unused output goes to the pack. Finished components promised to another job go directly into that job's ingredient reservation, so the player need not collect or manually requeue them. The construction-plan checklist counts only queued outputs not already promised to crafts.

Only currently available hand recipes are expanded. The planner does not bypass research, primitive-age lessons or machine-only smelting. Missing raw resources or insufficient queue space reject the whole request without reserving a partial chain or spending job IDs. Previews do not mutate inventory or the queue.

## Cancellation and full packs

Canceling a prerequisite also cancels all unfinished dependent jobs, including dependencies queued by a later click. The tooltip previews that cascade and the actual refund. Canceling only a consumer leaves its prerequisite jobs available to finish normally, releasing their promised output. Cancel all refunds the actual reserved stock across the whole queue.

Completed intermediates are real goods, not reversible recipes: canceling a lumber camp after its axe finishes returns six timber and one axe. Canceling before any work finishes returns eight timber and two stone. Unmade parts are never refunded. Refunds fail atomically if the pack lacks room.

Intermediate output assigned entirely to dependents can finish with a full pack. Unclaimed surplus and final output wait until the pack has space; delivery never discards surplus to unblock a queue.

## Save contract

Stable job IDs connect earlier producers to later consumers. Each job stores currently reserved inputs and outstanding producer/item links. Validation checks exact ingredient coverage, source order, source output budgets, positive integral quantities and complete metadata. Forward links, cycles, duplicated claims and forged extra reserved inputs are rejected. Completed source links turn into real reserved inputs before the producer leaves the queue.

All queued jobs explicitly store identity, reservations and dependency links. Missing metadata is rejected. Timers, XP and ordinary production accounting continue through fixed simulation phases.
