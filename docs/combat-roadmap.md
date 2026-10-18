# Combat development plan

Status: **C1–C3 implemented; C4–C7 remain design/backlog**. Updated 2026-10-17. See [the delivered briefing and specialist service](combat-readiness.md), [authored encounters with recorded supply costs](combat-encounters.md), and [weapon handling and sidegrades](combat-weapons.md).

The current playable behavior is documented in [defense.md](defense.md): ten individually signaled waves, a 15-second cancelable warning, three construct types, three turret roles, a rifle, physical ammunition, repairs and recoverable Town Hall breaches. No wave starts automatically. The [Homecoming chapter](homecoming-chapter.md) can be completed peacefully.

## Intended role

Combat should make factory layout, dependable ammunition production, regional logistics and repair capacity matter. The player should want to defend Oldbridge because of identifiable people, useful services and visible reconstruction. Increasing enemy health alone will not achieve this.

A successful defense loop is: learn who or what is at stake, inspect the threat and reward, prepare production and buffers, commit to the operation, manage an understandable battle, recover, and see the settlement change. Success should depend mainly on preparation and supply continuity; the engineer's rifle and movement should help recover mistakes without replacing an automated defense.

These are design targets, not claims about current balance.

## Participation and pressure

Keep the present opt-in behavior until the first combat slice is playtested. Do not quietly replace it with timed raids, pollution attacks or attacks on a new game's opening shelter.

Proposed longer-term structure: the player voluntarily commits to a rescue operation. An operation can eventually contain several clearly announced attacks, with disclosed resupply intervals and a safe opportunity to stop before the next commitment. That gives the factory a sustained supply problem without surprising a player who only agreed to one wave. Starting an operation must show its duration, approach, escalation and withdrawal rules.

Decisions before implementing automatic pressure:
- Should a standard campaign eventually include periodic attacks after an explicitly accepted story milestone?
- If so, provide a peaceful setting, adjustable pressure and explicit start/stop rules. Explain whether any rewards differ; do not turn peaceful play into a progression trap.
- Determine whether attacks continue between operations. Current recommendation: no; earn the value of sustained operations first.

Those decisions remain open. Adding this plan does not change defaults or authorize a switch to unavoidable raids. Combat can be strategically important through its content and supply requirements without putting all peaceful progression behind it.

## Rewards that justify the commitment

Current credits, family counters, movement bonus and fuel coverage are useful supporting rewards, but they are insufficient as the principal motivation. Families need names and visible roles; milestones need concrete benefits shown before activation.

The first-defense specialist service is implemented. The remaining milestone schedule is proposed, subject to scope and balance validation:

| Milestone | Proposed reward | What the player should notice |
| --- | --- | --- |
| First defense | Rescue **Nell, the quartermaster** (implemented), unlocking a town rearm service | Nell appears at the restored workshop; a new service stocks nearby defenses between operations using the player's real ammunition |
| Early defenses | Bring home a small named crew and unlock civic banners, damaged-relay garden pieces and defensive layout options | New people and decorations appear in the settlement; the player chooses how to use recovered material |
| Middle defenses | Recover sidegrade patterns: for example a long-range/slow-firing rifle option, reinforced barricades or a powered defense option | More viable layouts and weapon roles, with costs and drawbacks rather than universal damage inflation |
| Late defenses | Recover components and plans for the eastern signal station | A recognizable landmark is reconstructed in visible stages |
| Final defense | Secure the eastern route and complete the beacon storyline with an authored keeper scene | A permanent restored signal station, a clear campaign conclusion, and an optional replay/challenge route later |

Nell's proposed rearm service must complement belts and inserters. Scope its first version to a bounded local radius, a stocked depot and between-operation dispatch. It transfers only actual items, shows the cost/stock quote and stops on shortages. Existing Oren maintenance crews already repair with real kits and credits; do not duplicate or silently replace that feature. Continuous combat resupply should still reward a working production line.

Do not lock ordinary inventory upgrades, the peaceful Homecoming ending or essential repair access behind combat. Reward sidegrades, new services and the combat branch's own progression. No mandatory corpse looting, randomized essential drops or repeatable first-clear credit/XP farming. First-clear rewards require saved, duplicate-safe claims; replay rewards need a separate economy decision.

Each reward needs all four parts: preview, successful claim, visible/useful outcome and a retained explanation/history shortcut. Do not consider a family counter alone a completed specialist feature.

## Encounter design

Replace repeated health-scaled compositions with authored lessons using the existing enemy roles first:

| Operation band | Lesson | Factory or battlefield decision |
| --- | --- | --- |
| Introduction | One readable approach and manageable scout pressure | Cover the lane, manufacture ammunition, retain a repair reserve |
| Flanks and demolition | Dismantlers plus clearly announced split approaches | Avoid one brittle turret cluster; place walls to buy useful firing time |
| Armored freight | Haulers mixed with scouts | Combine piercing weapons with guns; choose where scarce ammunition is spent |
| Sustained rescue | Announced reinforcements and resupply windows | Maintain throughput and buffer reserves over time, not just stock a huge opening magazine |
| Signal station finale | A distinct eastern-route objective, authored setup and meaningful final encounter | Support the recovered landmark and defend the settlement as a connected logistics problem |

The first tuning pass stays inside the existing bounded arena. New directions, outposts, escort actors, ranged enemies or a new final objective require explicit navigation, UI and save work. They are later slices, not a free extension of current wave data.

Difficulty should increase through role combinations, approach timing and supply pressure before adding more health. Give players a chance to learn each threat. Do not scale enemy health invisibly to the player's factory size or equipment.

Cap simultaneous enemies and bound pathfinding work. Preview approach changes before commitment. Do not spawn enemies inside occupied or player-built structures, conceal unavoidable turret counters, or make a single failed encounter erase the settlement.

## Factory integration

- Use the existing ammunition recipe, assembler production, belts, inserters and physical turret buffers as the first supply challenge.
- Make real consumption and production rates easy to compare with recent successful encounters. Any ammunition estimate is advisory, with assumptions, not a guaranteed win prediction.
- Let shortages, blocked outputs and empty reserves surface in the same machine diagnostics used for peaceful production.
- Use existing material-funded repair kits and Oren's maintenance service for recovery. Between-operation rearm should complement this loop.
- If powered defenses are added, give them a distinct role and explicit energy/brownout behavior. Reuse conserved district power; do not make every turret depend on electricity by default.
- Make meaningful defensive layout choices before adding ammunition tiers, multiple fuel types or a large combat research tree.
- Persistent operation or landmark damage must have an affordable, understandable recovery path. Never require a combat-only consumable to recover from losing combat.

## Briefing and battle feedback

Before starting, show:
- The named rescue/landmark objective and exact first-clear reward.
- Enemy roles, count/composition, approach markers, and any announced reinforcements.
- Town Hall health, loaded ammunition, local defense coverage and repair reserve.
- Relevant shortcomings: empty guns, damaged structures and expected power dependency if introduced.
- Whether another attack can occur automatically within this commitment, the countdown and when cancellation is possible.

Readiness is guidance, not an arbitrary score or a permission gate. The player may deliberately attempt a weak setup. Keep authoritative safety checks such as restoring the Hall and an explicit warning.

During combat, prioritize threatened structures, remaining enemies/reinforcements, ammunition shortages and obvious attack telegraphs. Distinguish armor resistance from a missed shot. Keep the map/approach view legible and respect reduced-motion preferences.

Afterward, show actual ammunition and repair costs, important shortages, first-clear rewards, rescued people and the next opportunity. A loss should explain what failed and how to recover, not simply invite the same unexplained retry. Route significant outcomes into Updates; avoid per-shot notification spam.

## Delivery backlog

C1, C2, and C3 are implemented as documented in the defense guide and [weapons guide](combat-weapons.md). C4–C7 are unimplemented.

| Order | Complete slice | Acceptance criteria |
| --- | --- | --- |
| C1 — delivered | Combat briefing and first-defense specialist reward | First-wave objective/reward preview; live stock/health/coverage guidance; named specialist appears only after victory; material-backed between-operation rearm service; save/load and duplicate-safe reward validation; clear failure/retry instructions |
| C2 — delivered baseline | Ten-wave tuning and distinct encounter bands | Authored deterministic schedules, disclosed approaches/reinforcements, mixed-defense and rifle-assisted playtests, recorded ammo/repair costs; no universal layout required |
| C3 — delivered | Weapon handling and equipment sidegrades | Readable hit/armor/miss feedback; precision rifle and reinforced barricade sidegrades; HUD/inventory weapon controls and pack switching; ammo conservation and coat/retreat tuning |
| C4 | Sustained rescue operations | Explicit multi-attack commitment, safe cancellation boundaries, between-attack resupply interval and saved continuation; no surprise change to peaceful play |
| C5 | Middle rewards and settlement integration | Named crew, obtainable cosmetic/sidegrade patterns, visible settlement placement and reward history; balanced material costs and recoverable damage |
| C6 | Eastern signal station and finale | Authored landmark stages, final objective, keeper conclusion, permanent visible payoff and validated completed state |
| C7 — decide after playtests | Campaign threat settings and optional repeatable challenges | Explicit choice about ambient/timed pressure, peaceful behavior and replay rewards; documented defaults and pressure limits |

C1, C2, and C3 are delivered. The next recommended implementation is C4: sustained rescue operations. Continue normal-campaign and efficient-layout tuning alongside it; the prepared reference benchmark is not a substitute for human playtesting. Do not add an automatic raid director before validating those encounters. No dates are implied; each slice includes model rules, usable controls, feedback, persistence and verification.

## Validation and tuning

Use the existing defense sandbox plus a normal empty-start campaign. Do not balance solely against an unlimited-stock fixture.

Record time to first defense, how many players choose to attempt it, whether they can explain the reward, production time spent on ammunition, victory/failure rates, Hall damage, ammo spent, repair-kit cost and recovery time. For subsequent operations, record whether automation choices change and whether earlier strategies remain viable.

Test:
- First attempt with a novice layout, low reserves, rifle assistance and no specialist service.
- An automated mixed-defense line through all ten first clears, with practical supply costs.
- Shortages, disconnected power where relevant, blocked routes, damaged guns, retreat and breached services.
- Reload during warning, active reinforcement schedules, attack windup, recovery and completed reward claims.
- Cancellation, duplicate reward delivery, missing stock and a full destination during rearm.
- Minimum-window readability, keyboard behavior, reduced motion and bounded frame/pathfinding costs.
- Peaceful Homecoming progression without signaling any beacon.

Promote proposed rewards and mechanics into [defense.md](defense.md) only after implementation. Update this plan's statuses and the main roadmap as each slice lands.
