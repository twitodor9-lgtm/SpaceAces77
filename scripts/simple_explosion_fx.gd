extends RefCounted
class_name SimpleExplosionFX

static func spawn_hit(root: Node, world_pos: Vector2, scale_mult: float = 1.0) -> void:
	_spawn(root, world_pos, {
		"pieces": 6,
		"flash": 10.0,
		"distance_min": 10.0,
		"distance_max": 28.0,
		"duration": 0.14,
		"scale_mult": scale_mult,
	})

static func spawn_death(root: Node, world_pos: Vector2, scale_mult: float = 1.0) -> void:
	_spawn(root, world_pos, {
		"pieces": 14,
		"flash": 18.0,
		"distance_min": 18.0,
		"distance_max": 52.0,
		"duration": 0.24,
		"scale_mult": scale_mult,
	})

static func _spawn(root: Node, world_pos: Vector2, cfg: Dictionary) -> void:
	if root == null:
		return

	var pieces: int = int(cfg.get("pieces", 8))
	var flash_size: float = float(cfg.get("flash", 12.0)) * float(cfg.get("scale_mult", 1.0))
	var distance_min: float = float(cfg.get("distance_min", 12.0)) * float(cfg.get("scale_mult", 1.0))
	var distance_max: float = float(cfg.get("distance_max", 36.0)) * float(cfg.get("scale_mult", 1.0))
	var duration: float = float(cfg.get("duration", 0.18))

	var burst_root := Node2D.new()
	burst_root.global_position = world_pos
	root.add_child(burst_root)

	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -flash_size),
		Vector2(flash_size * 0.75, 0.0),
		Vector2(0.0, flash_size),
		Vector2(-flash_size * 0.75, 0.0)
	])
	flash.color = Color(1.0, 0.94, 0.72, 1.0)
	burst_root.add_child(flash)

	var flash_tw := burst_root.get_tree().create_tween()
	flash_tw.set_parallel(true)
	flash_tw.tween_property(flash, "scale", Vector2(2.0, 2.0), duration * 0.55)
	flash_tw.tween_property(flash, "modulate:a", 0.0, duration * 0.55)

	for i in range(pieces):
		var shard := Polygon2D.new()
		var size := randf_range(4.0, 9.0) * float(cfg.get("scale_mult", 1.0))
		shard.polygon = PackedVector2Array([
			Vector2(-size * 0.7, -size * 0.35),
			Vector2(size * 0.9, 0.0),
			Vector2(-size * 0.7, size * 0.35)
		])
		shard.color = Color(1.0, 0.78 if randf() < 0.5 else 0.48, 0.12, 1.0)
		shard.rotation = randf_range(0.0, TAU)
		burst_root.add_child(shard)

		var dir := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var dist := randf_range(distance_min, distance_max)
		var rot_end := shard.rotation + randf_range(-2.6, 2.6)

		var shard_tw := burst_root.get_tree().create_tween()
		shard_tw.set_parallel(true)
		shard_tw.tween_property(shard, "position", dir * dist, duration)
		shard_tw.tween_property(shard, "scale", Vector2(0.15, 0.15), duration)
		shard_tw.tween_property(shard, "modulate:a", 0.0, duration)
		shard_tw.tween_property(shard, "rotation", rot_end, duration)

	var cleanup_tw := burst_root.get_tree().create_tween()
	cleanup_tw.tween_interval(duration + 0.08)
	cleanup_tw.tween_callback(Callable(burst_root, "queue_free"))
