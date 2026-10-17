# Saved games and recovery

Use the top-bar Load button or Esc → Load / recovery. Gameplay pauses while choosing.
The screen lists the current save and its previous-save backup, including:

- Last file modification time, explicitly in UTC.
- Timber/Stone/Iron chapter (or Industrial factory for older worlds).
- Simulated world time, building count and world seed.
- Readability/validation status for each file.

Select a valid card, then Load selected save. Loading replaces the live session;
Cancel keeps it. The selected file is read and validated again at confirmation time.
Missing or invalid files cannot be selected. If only the backup is healthy, it is selected
by default, but the player must still confirm loading.

Inspecting and loading never change either file. After loading a backup, Save game writes
the recovered session to the normal current slot. Older legacy saves remain importable
when no v2 current save exists.

## Backup safety

A normal save first writes and flushes a temporary file. A validated existing current save
becomes the previous-save backup before the new primary is committed. If the existing
primary cannot be loaded, it is copied to a uniquely named damaged-file archive instead.
The existing backup is retained. A failed preservation step aborts the commit.

The existing 16 MB load limit is checked using the open file's length before reading its
text. Invalid JSON is reported as a load error without an engine-error stack trace.
A failed load never replaces the in-memory world.

This remains a single current slot and one rolling backup. Named slots, periodic autosaves,
cloud synchronization and browsing damaged archives are future work. Damaged archives are
retained for manual recovery; they are not automatically deleted.

## Verification

tests/save_recovery_tests.gd uses a unique test-owned save directory. It checks metadata,
different primary/backup state, byte-for-byte preservation during inspection/loading,
corrupt-primary backup protection, damaged-file retention, cancellation, explicit selection,
and disabled loading when neither file is healthy. It is included in verify_factory.gd.
Native checks cover the composed Load flow and the dialog at 1100×720.
