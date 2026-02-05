extends AbilityBase

@export var iframes: float = 0.35
@export var edge_margin: float = 48.0

@export var hops: int = 3
@export var hop_step_distance: float = 420.0
@export var hop_delay: float = 0.22

@export var enter_duration: float = 0.10
@export var portal_stay_open_extra: float = 0.10
@export var exit_portal_preopen: float = 0.08
@export var exit_duration: float = 0.10

# ✅ כמה זמן לאפשר Wrap שמאל↔ימין אחרי הפעלה (חור תולעת)
@export var wrap_seconds: float = 2.0

func try_use() -> void:
	if not can_use():
		return

	var p := _player as Node2D
	if p == null:
		print("WayJump: player not found")
		return

	if p.has_method("set_invulnerable"):
		p.set_invulnerable(iframes)

	# ✅ במהלך/אחרי WayJump אפשר לצאת משמאל ולהיכנס מימין (wrap אופקי)
	if p.has_method("enable_horizontal_wrap"):
		p.enable_horizontal_wrap(wrap_seconds)

	var sprite := p.get_node_or_null("AnimatedSprite2D") as CanvasItem
	var screen := p.get_viewport_rect().size
	var dir := Vector2(1, 0).rotated(p.rotation)

	for i in range(hops):
		var target := p.position + dir * hop_step_distance
		target.x = clampf(target.x, edge_margin, screen.x - edge_margin)
		target.y = clampf(target.y, edge_margin, screen.y - edge_margin)

		_spawn_wormhole(p.global_position, true)

		if sprite:
			sprite.visible = false

		await get_tree().create_timer(enter_duration + portal_stay_open_extra).timeout

		p.position = target

		_spawn_wormhole(p.global_position, false)

		await get_tree().create_timer(exit_portal_preopen).timeout

		if sprite:
			sprite.visible = true

		await get_tree().create_timer(exit_duration).timeout

		if i < hops - 1:
			await get_tree().create_timer(hop_delay).timeout

	show_label()
	print("WayJump DONE")

func _spawn_wormhole(pos: Vector2, front: bool) -> void:
	var fx := WormholeFX.new()
	get_tree().current_scene.add_child(fx)
	fx.global_position = pos
	fx.z_index = 1000 if front else -1000
	fx.start()

class WormholeFX extends Node2D:
	var t := 0.0
	var dur := 0.5
	var r0 := 12.0
	var r1 := 70.0

	func start():
		t = 0

	func _process(delta):
		t += delta
		queue_redraw()
		if t >= dur:
			queue_free()

	func _draw():
		var u := clampf(t / dur, 0, 1)
		var r := lerpf(r0, r1, u)
		var a := lerpf(1, 0, u)

		draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(0.6, 0.8, 1, a), 3)
		draw_circle(Vector2.ZERO, r * 0.4, Color(0, 0, 0.1, a))
