# Development save policy

Only the current save format is supported. The current world schema is v3, stored in `user://factory_save_v3.json` with the existing named-slot and autosave suffixes. Old files remain on disk but are not imported or converted.

Incompatible changes to world generation, recipes, IDs or persistent rules should bump the save version and require a new world. Loading a selected older file reports that requirement. Complete current sections, civic sites, entity fields and craft reservations must be present; the loader rejects incomplete state.

Transactional writes, type/range/quantity validation, backups, damaged-file preservation, named slots and optional autosaves remain. These protect current playtests independently of backward compatibility.

There is one playable opening: empty pack → timber and shelter → stone and water → crossing → industry. Test fixtures prepare later chapters solely for focused tests. There is no legacy industrial start or post-Town-Hall age project.

Replant cleared grove remains a deliberate landscaping command, independent of save migration.
