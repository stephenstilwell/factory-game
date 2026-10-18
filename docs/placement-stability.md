# Camp inspector layout stability

## Cause and fix

Opening Crafting, closing it, then inspecting a placed lumber camp could freeze the next frame and eventually crash Godot. The player's latest trace completed the inspector's script callbacks; the freeze occurred while Godot processed the resulting GUI layout work.

A native fullscreen reproduction with seed 1063638934 and camp tile (18, 9) reproduced the same boundary. Layout instrumentation recorded more than 80,000 resize/sort notifications in the machine inspector without returning to the next frame. The automatically appearing vertical scrollbar changed the available width of wrapped text, creating a repeating layout cycle. The engine eventually exhausted its deferred work queue and crashed while reporting its queued callbacks.

The workspace's shared machine, town and character scroll containers now use `SCROLL_MODE_RESERVE`. The scrollbar still appears only when needed, while its width is always reserved, so text wrapping does not alter its own available width. See [Godot's ScrollContainer documentation](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html#enum-scrollcontainer-scrollmode).

Input deferral and selecting an existing machine while a building tool is active remain useful interaction improvements, but did not fix this layout cycle. Changing the renderer and restarting the editor also did not resolve it. The project retains Compatibility rendering for its 2D drawing.

## Verification

Run the native regression from the project directory, using an external timeout of 45 seconds so a future layout loop fails the check:

    godot --path . --log-file .godot/workspace-layout-engine.log --script res://tests/verify_workspace_layout.gd

This test opens Crafting, completes the axe and camp with live queue controls, closes Crafting, places the camp, opens its inspector, verifies that resizing stops, repeats the Crafting/inspection transition, and reclaims the camp. It runs at the minimum supported window size and fullscreen, without saving gameplay or preferences. Native text/layout rendering is required.

The fixed test passed at 1100×720 and fullscreen 3840×2160. Windows mouse input also passed the previously failing sequence with normal animations enabled. The wider placement smoke test remains available:

    godot --path . --script res://tests/verify_build_placement.gd

Temporary per-frame placement tracing has been removed now that the layout cycle is reproduced and addressed. Existing player crash logs are retained locally for reference.
