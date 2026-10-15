extends RefCounted
## Bounded presentation particles, fed by successful actions. No physics Nodes.
var particles: Array = []

func burst(at: Vector2, color: Color, seed_value: int, count: int = 8) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(count):
		if particles.size() >= 96: particles.pop_front()
		var velocity := Vector2.from_angle(rng.randf_range(-PI, 0)) * rng.randf_range(18, 45)
		particles.append({"position": at, "velocity": velocity, "life": rng.randf_range(0.25, 0.55), "color": color, "size": rng.randf_range(1, 2.5)})

func step(delta: float) -> void:
	for particle in particles:
		particle.life -= delta
		particle.position += particle.velocity * delta
		particle.velocity.y += delta * 45
	particles = particles.filter(func(particle): return particle.life > 0)

func draw(canvas: Node2D) -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(1, particle.life * 4)
		canvas.draw_circle(particle.position, particle.size, color)
