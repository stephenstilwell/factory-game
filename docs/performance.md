# Frontier rendering performance

The living-frontier renderer now uses one shared antialiased ellipse texture for terrain details, foliage, wildlife, and shadows. This replaces GDScript vertex construction and repeated polygon triangulation while retaining caller transforms, tint, transparency, and draw order.

Tree candidates are cached in 16x16 chunks by the world view. Only candidates undergo live occupancy/removal checks each frame. Camera travel evicts distant candidate chunks, and binding a world clears the cache. No scenery cache enters saves; mining, placement, and cleared trees remain authoritative model queries.

Run a native rendering benchmark with:

```powershell
godot --path . --script res://tests/benchmark_frontier.gd
```

It warms up for 60 frames, samples 180 frames, and reports median and p95 engine process time with a zoomed-out view. Run comparisons with the same renderer, hardware, window state and no concurrent test/build processes. These timings include engine/render scheduling and are not a guarantee of FPS in large factories.

Regression coverage compares cached candidates with direct generation across negative coordinates and distant travel, checks cache eviction and world rebinding, and retains save/render conservation tests. Native captures review foliage, ground details, NPC transforms, and the discovery UI.
