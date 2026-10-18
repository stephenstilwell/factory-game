# HUD hierarchy and milestone art

The field header now gives the active objective and its short hint a separate sage-framed area. Credits, machine count and research sit below as supporting status. Town Hall damage retains its explicit health text and gains a warning color below half health. Save/load actions remain in the pause menu; window mode is available there and through F11. Gameplay navigation stays in the header.

Civic previews now use dedicated vector portraits, rather than drawing copies of the world sprites. The market has a striped stall and hanging sign; the workshop has a forge chimney and gear; Town Hall has a beacon tower. Ruined portraits have shuttered windows, damaged masonry and rubble; restored portraits have warm windows, plants and repaired trim. UI-owned preview objects remain independent from live buildings.

Restoration, equipment and technology completion cards have a bounded 0.75-second drawing accent and five seconds of reading time. Ordinary crafting keeps its existing 3.5-second feedback. Repeated milestones reuse one effect node. No minimum sizes, control positions or simulation values are animated. Reduced motion immediately clears the accent and leaves the message fully opaque; clearing/replacing a reward also clears old accents.

This pass adds no raster assets, render passes, continuous particle emitters or save data. It does not complete the broader bespoke world-art or interface-scale backlog.

Verification: hud_art_tests.gd checks the objective area, menu access, effect lifetime/replacement, reduced-motion cancellation and world/save isolation. Native layout verification remains required at minimum window size and fullscreen. capture_ui.gd covers the field HUD, restoration portraits and a technology milestone.
