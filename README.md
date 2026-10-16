# Ironworks / Frontier

A Godot 4 factory-game foundation. Open `project.godot` and press **F5**. No external assets or dependencies are required.

The first art pass uses a **warm industrial frontier** style: mossy terrain, illustrated machinery, copper and patina roofs, warm restored windows, and a working engineer silhouette. Mining/repair effects, machine motion, and a stateful beacon reinforce actions. The placement grid appears while building. See [art direction](docs/art-direction.md) for visual rules and review captures.

The game starts in **borderless fullscreen**. Press **F11** or use the top-bar display button to switch to a resizable window and back. The interface scales from its 1280x800 reference resolution, with larger default text for readability. If running inside the editor's embedded game view, pop the game out into its own window to use the full monitor.

Your first regional goal is to **reopen Oldbridge's ruined trading post**, supply its neighbors, and fund the engineers' workshop. Press **Y** for town projects, or click a landmark in the world. See [docs/settlements.md](docs/settlements.md) for repair costs, contracts, delivery automation, and the first global bonus.

Press **T** for Technology and **F** for production and construction plans. Choose workshop projects that explain their purpose, cost, prerequisites, and unlocks. Assemblers can manufacture every placeable building. After Supply routes, choose routing tools or steel production; Homes for Oldbridge turns steel into housing supplies for a growing Oldbridge. See [factory expansion](docs/factory-expansion.md).

The engineer can join voluntary defenses with a **service rifle [V]**. Hold **left mouse / Space** to fire while drawn; shared ammunition comes from your pack. Three types of old-network maintenance constructs use multiple approaches. Gun turrets, piercing cannons, pulse turrets, and walls provide complementary defenses. See [combat and beacon defense](docs/defense.md) for a prepared playtest and controls.

See [the Oldbridge pacing pass](docs/oldbridge-pacing.md) for shared fuel service, resource migration, clearer projects, and arrival rewards.

The world now has seeded groves, birds and butterflies, and three recoverable landmarks. Open **Discoveries [L]** or **Journal [J]** to follow survey notes, recover orchard cuttings for a visible town garden, and solve the old depot’s loaned-conveyor puzzle. Rewards improve surveys and civic fuel service. See [the living frontier](docs/living-frontier.md).

## Play

New games start with **an empty inventory and no working factory buildings**. Three abandoned civic landmarks are waiting to be restored using your production. You appear near stone at (26, 9). The learning guide shows one objective at a time, with a direction arrow and a highlighted resource/machine where relevant. Hold **right mouse** over a nearby deposit to mine by hand.

The opening teaches **mine stone → craft/place a furnace → mine ore and coal → smelt/collect plates → craft a drill → automate storage → assemble components → make science → research**. Recipes and toolbar tools appear as their learning milestones are completed. Lessons award no free items; all materials come from mining and production. Spending materials or reclaiming a machine does not erase a completed lesson.

**Bootstrap:** Mine 5 stone, press **C**, and craft a stone furnace. Select the furnace on the hotbar and click nearby ground to place it. Mine 5 iron ore and 2 coal; walk back, select the furnace, and use **Load ingredients** to supply it. After it produces plates, **X** collects them. Repeat mining/smelting to earn the materials for your drill and logistics.

Drafting benches consume engineering dossiers for four workshop projects: Supply routes (10), Foundry craft (20), District distribution (20), and Homes for Oldbridge (25). After each completion, choose what the town needs next with **T**. Switching preserves invested dossiers. See [progression](docs/progression.md).

Press **P / Engineer tab** for permanent personal upgrades: movement speed, hand-mining speed, interaction reach, and carrying capacity. Invest factory materials after the first working drill, then unlock advanced tiers through research and workshop restoration. See [character progression](docs/character-progression.md) for stats and the planned connection to future combat.

Engineer **[P]** previews exact skill rewards, tracks a personal goal, and highlights affordable equipment. Seventeen equipment tiers include settlement-gated repair rigs, survey instruments, and final expedition tools. Journal **[J]** keeps unread conversations and recent activity. See [engineer progression and guidance](docs/engineer-progression.md).

The Engineer's **Skills** tab tracks Mining, Fabrication, and Exploration from **1 to 99**. Earn XP through successful hand mining, completed hand crafts, and discovering new areas and resource patches. Milestones grant modest speed and survey bonuses; equipment upgrades remain in their own tab. Progress and discovery history persist in saves. See [skills](docs/skills.md) for rewards and milestone rules.

After the workshop, rebuild **Oldbridge Town Hall** and prepare its eastern defenses. Craft walls, ammunition-fed turrets, and repair kits; deliberately light the beacon in **Y → Town Hall** to begin a wave with 15 seconds' warning. **H** repairs damaged structures. Victory grants 30–75 relief credits and shelters three families. Returning crews provide +5% movement; every second victory extends Supply Hearth coverage by one tile, up to 12. Spend 20 credits at the trading post for 20 coal, 10 ammunition, and 2 repair kits. Defeat preserves your progress and leaves a repairable hub; waves never begin automatically. See [the defense guide](docs/defense.md) for a first layout, costs, recovery, and save compatibility.

Construction consumes physical building items; craft them with **C**. Select a recipe to see ingredient counts and missing materials, then choose **Craft 1**, **Craft 5**, or **Max**. Queued crafting reserves materials immediately; click a queue job to cancel and refund it. **I** opens the searchable pack. Drag items to machine or town slots using the selected 1/5/All quantity; right-click moves one and Shift-click moves all that fits. See [the inventory guide](docs/inventory-ui.md). The demonstration factory exists only in test fixtures.

Nearby starting deposits: iron around **(14, 16)**, copper **(28, 23)**, coal **(9, 23)**, stone **(26, 9)**. Deposits are finite, with four times the previous stock. Loading an older save scales its remaining stock once; exhausted tiles stay empty. New games use a random seed, varied patch shapes, and larger, richer frontier deposits. Press **M / Survey** to find remaining resources and track one with a compass marker. Older saves keep their original terrain. See [world generation](docs/world-generation.md) for distribution, reproducible seeds, and save compatibility.

| Action | Control |
| --- | --- |
| Walk; camera follows | WASD / arrows |
| Zoom | Mouse wheel |
| Toggle borderless fullscreen / windowed | F11 / top-bar display button |
| Select building | 1–0 / customizable hotbar |
| Place; paint a continuous grid path | Left click / drag |
| Inspect a machine | Left click occupied tile |
| Close interface / clear build cursor / open pause menu | Esc, in that order |
| Clear build cursor / pick hovered building | Q |
| Rotate selected build direction | R / Shift+R reverses |
| Rotate an existing machine | Esc, hover machine, R |
| Mine a deposit by hand | Hold right mouse over a nearby deposit |
| Reclaim building and its contents | Hold right mouse for 0.5 seconds |
| Supply up to 5 of each accepted ingredient / coal | Ctrl+left click machine / Load ingredients button |
| Transfer a specific item | Drag between pack and machine; choose 1 / 5 / All |
| Collect finished output; retain fuel and inputs | Select machine, X |
| Change furnace / assembler recipe | Machine recipe selector |
| Open inventory & crafting / close interface | E (I remains a pack shortcut) |
| Open hand crafting | C |
| Technology / workshop projects | T / Tech button |
| Production and construction plans | F |
| Town projects | Y / Town button |
| Discoveries, landmark leads, and depot puzzle | L / Journal → Discoveries |
| Survey and track remaining resource patches | M / Survey button |
| Personal upgrades and character stats | P / Engineer tab |
| Repair hovered or inspected structure using a kit | H / Repair button |
| Inspect / supply / withdraw at a civic landmark | Click landmark; delivery button / Ctrl-click supplies; X withdraws unused goods |
| Pause menu / pause simulation | Esc / Pause key |
| Save / load | Top toolbar |

Base interaction reach is six tiles; Utility harness upgrades extend it to eight. Machines block the engineer; belts and inserters can be walked over. Amber machine indicators show waiting/blocked states; inspect for the reason. Reclaiming preserves inventories and inserter hands. Partially spent fuel energy and unfinished machine progress are not refundable.

## Logistics rules

The **Supply Hearth** unlocks alongside storage. Craft it for 10 iron plates, 4 gears, and 10 stone. Load up to 200 coal in one action or feed it with an inserter. It distributes physical coal to healthy drills and furnaces within eight tiles, keeping three coal per burner. Select it to see coverage. Returning beacon crews expand coverage; a breached Town Hall suspends the extension.

- Belts carry one item per cell. Ordinary belts attempt a move every two simulation ticks; fast belts attempt every tick. Occupied destinations cause backpressure. Movement uses a snapshot and reservations, so item updates cannot chain across multiple tiles or overwrite another item in one tick.
- Inserters pick from the adjacent tile **behind** them and drop on the tile **ahead**. Their hand holds a real item until a destination accepts it. Machine input filters follow the selected recipe; coal is accepted by burners. Inserters extract machine outputs; chests and belts expose their stored inventory.
- Drills extract the deposit beneath them and have a built-in chute that outputs onto an adjacent belt. Furnaces and assemblers require inserters for automated loading/unloading. Chests require inserters to connect to belts.
- One coal supplies 240 active work ticks (24 seconds of work). Drills need 15 ticks per item, furnaces 32 per plate, and steel needs 80. Blocked outputs preserve ingredients and stored fuel energy. Pausing freezes crafting, mining, movement, and production.
- Assemblers, inserters, and labs currently operate without an electricity network. This keeps the first automation/research loop playable while power is a future system.
- Civic landmarks accept inserter deliveries only through their marked hatch. A repaired trading post dispatches a batch of 4 iron plates + 1 gear every 30 simulated seconds while stocked; each delivered batch earns 10 trade credits. The engineers' workshop costs 60 credits plus materials and makes each new coal supply 288 active work ticks instead of 240, globally. No goods means no new shipments; repairs and civic bonuses remain permanent.

## Saving

Manual saves use `user://factory_save_v2.json` (Godot's application data directory), with the preceding successful save retained as `.bak`. A temporary file is flushed before replacing the main slot. Loading validates into a fresh world; invalid data leaves the current factory intact.

The original prototype's `factory_save.json` can be imported with **Load** if no v2 save exists. Its file is preserved. Belts/drills/furnaces retain positions; delivery hubs become storage chests; ore/plate IDs migrate; legacy credits add a capped iron-plate allowance. Old layouts need inserters added between belts and machines under the new logistics rules. **Save** writes the imported factory to the new slot. A fresh empty world opens on every launch; use **Load** to resume a saved factory.

Learning milestones and action counters are included in new saves. Older v2 saves without this data retain their existing layout/inventory and unrestricted crafting, so loading an established factory cannot trap it behind introductory lessons.

Settlement repairs, uncommitted supplies, in-transit shipments, credit balances, and earned-income totals are saved too. Saves predating settlements gain fresh ruins on vacant land; existing machines and the engineer are preserved. Shipment timers run only while the simulation runs, including when the player is elsewhere; there is no offline income.

## Development

See [docs/architecture.md](docs/architecture.md) for ownership, simulation contracts, scaling choices, and extension examples. See [docs/roadmap.md](docs/roadmap.md) for the prioritized path toward a fuller factory game.

Headless integration checks (replace `godot` with your Godot executable):

```powershell
godot --headless --path . --script res://verify_factory.gd
```

Checks cover inventory transactions, seeded/finite terrain, construction reach and collision, item conservation, congestion, inserter hands, fuel, recipes, crafting, automated research, the resource-only path from an empty start through restoration and its first civic bonus, timed contract income, currency spending, save validation, legacy import, deterministic continuation, disk backups, and scene UI. They use an isolated temporary save slot and leave player saves untouched. Godot script/runtime errors also count as a failed verification; check stderr as well as the test summary.

Optional rendered screenshots:

```powershell
godot --path . --rendering-method gl_compatibility --script res://tests/capture_preview.gd
```

Previews are stored under the ignored `.godot/verification/` directory.

## Windows builds and releases

See [the release guide](docs/releases.md) for local Windows packages, automated GitHub Actions builds, and draft prereleases.

Music and action sounds are included. Press **Esc** for Master, Music, and Sound effects volume sliders; preferences persist between sessions. See [audio](docs/audio.md) for the palette and extension points.

The bottom building hotbar has ten customizable slots and two pages. **Right-click a slot** to assign a building, drag from your pack to pin one, drag between slots to swap, and press **Tab** to change pages. **Alt + number** pins the current build cursor. Layouts persist between sessions. See [the hotbar guide](docs/hotbar.md).

Oldbridge now has a story: help Mira, Oren, and Ada bring displaced families home after the enchanted beacon chain went dark. New games begin with a skippable greeting. Click the named keepers or use a town project's **Talk** button; press **J / Journal** to replay conversations and review your next goal. Story memories persist in saves. See [the first story arc](docs/story.md).
