# Recent updates

Click Updates beside the pack count to review the last 50 rewards and unlocks from the current play session. The control shows an unread count. Opening history acknowledges its entries; events received while it is open are already considered read. Clear history removes retained entries.

History records actual hand-craft deliveries, installed equipment, restored civic buildings and completed technologies. Rejected, canceled, intermediate-only or pack-blocked crafts do not announce rewards. Consecutive deliveries of the same hand-craft recipe combine quantities into one entry. Generic status messages are excluded.

Each entry links to its recipe, completed technology, equipment menu or civic building. Links inspect the target without purchasing, crafting or restoring anything. Escape closes history before opening the pause menu. World pointer actions, movement and firing are suppressed while it is open; simulation otherwise follows existing menu/pause behavior.

Technology completion now emits an explicit model event and displays an illustrated completion card in addition to retaining the unlock in history. Restoration is recorded on success, independently of its dialogue-deferred visual celebration, so dialogue cannot duplicate entries.

This slice deliberately retains no save data. Starting or loading a world clears the history and disconnects old world event subscriptions. Persisting the history across loads is remaining work if playtesting demonstrates a need.

Verification: notification_history_tests.gd covers actual crafting and research, aggregation, unread acknowledgement, shortcuts, Escape, bounded retention, dialogue ordering, clearing and world rebinding. Existing native layout regression remains required at minimum window size and fullscreen.
