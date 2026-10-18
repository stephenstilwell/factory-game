# Saved games and recovery

Use Load or Esc → Load / recovery. Gameplay pauses while choosing. Four named slots each show manual, backup and optional autosave recovery copies, along with UTC modification time, chapter, simulated time, building count, seed and validity.

Select a healthy copy and confirm loading. Cancel keeps the active session. Loading validates again and changes no files. After loading a backup or autosave, Save writes to that slot's manual file.

Only the current v3 world format is supported. Older formats are rejected with a fresh-start message and are never imported or upgraded. See [development save policy](development-saves.md).

A save flushes a temporary file before committing it. A healthy previous primary becomes the backup; a damaged or incompatible primary is preserved separately without replacing a good backup. Preservation failures abort the write. The 16 MB limit, JSON checks and model validation apply before replacing the live world.

Recovery and slot tests use isolated directories and leave playtester files untouched. Named slots and optional five-minute simulation autosaves are implemented; cloud synchronization and an archive browser remain future work.
