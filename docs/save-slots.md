# Factory slots and autosaves

Use **Esc → Save as / factory slots** to select one of four fixed destinations and give it a name. The original main slot retains its existing path. Names are labels and never become paths. Saving to an occupied slot preserves its previous save as a backup. Quick Save then writes to the active slot.

**Load / recovery** selects a factory, then explicitly chooses its current manual save, previous manual save, autosave or previous autosave. Metadata includes chapter, world time, buildings and seed. Invalid copies cannot be selected. Loading replaces the session but never writes to the source. Subsequent Save writes to that factory's manual slot. Legacy imports keep their original file untouched.

The pause menu offers **Autosave every 5 simulated minutes**. It is off by default and remembered separately for each factory slot. Paused time does not count. Switching or loading worlds resets the interval. Autosaves write to a separate file and rotate their own backup; they never replace the manual save or its backup. Save errors appear in the normal notice area and retry at the next scheduled interval.

All destinations use the existing validated save service, including damaged-primary preservation and backup protection. Slot labels and autosave preferences live in a separate config file. There is no deletion UI, cloud synchronization or automatic saving on exit.
