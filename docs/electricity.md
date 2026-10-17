# District electricity

Research **Foundry craft [T]**, craft a **Charcoal dynamo** and **District power poles**, then inspect a drill, furnace, assembler or drafting bench. Install its electric drive for **2 steel + 4 wire**. Drives double work speed and replace individual burner fuel; losing power pauses work. Existing machines remain mechanical/burner machines until explicitly converted.

A dynamo costs 6 steel, 6 gears, 8 wire and 10 stone. Two poles cost 2 planks and 2 wire. Both can be made by hand or assembler and assigned to the existing hotbar.

Healthy poles link within six tiles. They serve machines and dynamos within three tiles. Machines use the nearest healthy pole, breaking ties by ID. Separate districts require their own generator or a pole connection. Pole placement and selection show service and connection ranges; visible wires and electric-drive badges explain the layout. Disabled poles disconnect their links; repair restores them.

Each coal/charcoal contains **2400 energy**. A dynamo supplies at most **8 energy per simulation tick**. A working electric drill draws 2, furnace 4, assembler 3 and drafting bench 2. A tick is 0.1 seconds. Fuel is consumed only when needed, remaining energy stays in the dynamo, and idle, ingredient-starved or output-blocked machines draw nothing. Multiple dynamos add capacity. Under shortages, consumers rotate deterministically so a fixed first machine cannot starve the others. Whole work ticks are granted; unused throughput is not stored as energy.

**F → Production** shows network count, current supplied work, demand and available generation. Inspection distinguishes disconnected machines, missing generation and shortages. The existing nearest-stall action includes power problems. Oren introduces the system through an unread workshop conversation after Foundry craft.

Electric machines retain existing fuel for withdrawal. Supply Hearth runners skip converted burners. Pickup returns the building, its stored items and the drive's two steel/four wire; completed work and spent energy are not refunded. A dynamo's unused energy is lost when picked up, just like stored burner work. Ghost modules copy machine configurations, not installed drives.

Topology is derived and rebuilt only after layout, disabled-state or retrofit changes. Integer generator reserves and drive installations persist through validated saves; old saves default to zero electrical state. There is no offline generation. The current slice intentionally has no fluids, accumulators or energy-based weapon conversion.
