# Oldbridge: a place to come home to

The first story arc gives the existing factory progression a human purpose: rebuild the crossing so families displaced by the failed beacon network can return. The old infrastructure depended on enchanted beacons; ordinary furnaces, gears, trade, and maintainable machinery now provide a dependable start.

## Playing the story

New games open with a three-page, skippable greeting from Mira. **Enter / Space** advances; **Esc / Close** dismisses. The introduction gives no items and does not change the empty-world start.

Click **Mira**, **Oren**, or **Ada** beside their buildings to talk, or use **Talk to…** in a nearby town project's panel. Conversations require normal interaction reach. An amber dot identifies an unheard current conversation. Keepers follow landmark positions, including relocated landmarks in old saves, and avoid existing machines when choosing where to stand.

Restoring each building opens its short after-conversation. The first successful beacon defense opens Ada's homecoming scene. A breached hall gives Ada a recovery conversation. All existing material costs, technology requirements, contracts, and defense opt-in behavior remain authoritative. Dialogue is never an unlock gate.

Press **J** or click **Journal [J]** on the bottom dock to see the current human goal and replay heard conversations. Oren's restored workshop reveals a relay plate bearing the warning, *Cut the chain before it answers.* The journal records this unresolved clue.

Conversations and the journal pause the simulation, including defense warnings and enemies. Closing them restores the previous pause state. Loading another world dismisses the old panel and disconnects its story event listener.

## First arc

| Project | Person | Why it matters | Visible consequence |
| --- | --- | --- | --- |
| Trading post | Mira, trader | Reconnect supply wagons and honor her promise to displaced families | Travelers return to the reopened market |
| Workshop | Oren, engineer | Bring back the repair crew and build infrastructure the town can maintain | A working bench, tools, crew, and the existing burner improvement |
| Town Hall | Ada, warden | Provide dry shelter before inviting people down the eastern road | Bedding beneath warm windows; families after the first defended signal |

The residents are visual consequences of settlement progress. This pass does not add autonomous schedules, housing capacity, population upkeep, or additional economic rewards.

## Ownership and saves

- `scripts/data/story_catalog.gd`: stable chapter/NPC IDs, dialogue, roles, and chapter goals.
- `scripts/simulation/story_state.gd`: read memories, chapter availability, current goal, and derived NPC positions.
- `World.talk_to_site` / `request_story`: validated interaction and milestone presentation events.
- `scripts/ui/story_panel.gd`: dialogue pages and replayable journal.
- `scripts/view/npc_art.gd` / `npc_portrait.gd`: shared vector characters, portraits, and homecoming details.

The required story section stores known, unique conversation IDs and validates their prerequisites before replacing the live world. Missing older story data is rejected.

New story chapters should use stable IDs and explicit availability rules. New exploration clues can extend the journal without making dialogue responsible for inventories, research, or progression rewards. The question of why the beacon chain failed remains open; no final-world choice or additional relay exploration system is implemented in this first arc.