# Map detail after loading

The settlement chart reconstructs deposits from the saved world's seed, generator version and resource scale in a disposable map-only cache. It requests only chunks intersecting charted exploration cells, draws only explored tiles, and applies live saved depletion overrides. Evicting the normal terrain cache or loading a save no longer removes distant known ore from the map.

Reconstruction runs in batches of four chunks per frame with at most 512 cached chunks and 512 pending requests. It never changes authoritative terrain, resource stock, exploration, or saves. At overview scales below two pixels per tile, deposit detail waits until the player zooms in, avoiding repeated work over a very large view. Hovering explored deposits shows their item, remaining stock and tile coordinates.
