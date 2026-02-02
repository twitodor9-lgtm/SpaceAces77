extends Node2D

@export var dolphin_runner_scene: PackedScene
@export var damage: int = 9999
@export var dolphins_count: int = 6
@export var cooldown: float = 6.0
@export var side_margin: float = 80.0
@export var top_margin: float = 60.0
@export var variant_anims: Array[StringName] = [ &"run_0" ]

var _active: bool = false
var _cd_left: float = 0.0

func _process(delta: float) -> void:
	_cd_left = maxf(_cd_left - delta, 0.0)

func try_use() -> void:
	if _active or _cd_left > 0.0:
		return
	_active = true
	_cd_left = cooldown

	_damage_all_enemies()
	_spawn_pod(_get_visible_world_rect())

	_active = false

func _damage_all_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(damage)

func _spawn_pod(r: Rect2) -> void:
	if dolphin_runner_scene == null:
		print("❌ DolphinWave: dolphin_runner_scene is null")
		return

	var left: float = r.position.x + side_margin
	var right: float = r.position.x + r.size.x - side_margin
	var top: float = r.position.y + top_margin
	var bottom: float = r.position.y + r.size.y - 90.0

	var count: int = maxi(dolphins_count, 1)
	var lanes: int = mini(4, count)
	var lane_step: float = (bottom - top) / float(lanes + 1)
	var water_y: float = (top + bottom) * 0.5

	print("DOLPHIN POD spawn count=", count, " rect=", r)

	for i in range(count):
		var lane := i % lanes
		var y := top + lane_step * float(lane + 1) + randf_range(-10.0, 10.0)

		# מרחקים לא אחידים (X) — זה עושה “להקה” טבעית
		var spacing := 55.0
		var jitter_x := randf_range(-45.0, 35.0)
		var start_x := left - 180.0 - float(i) * spacing + jitter_x

		var anim_name := variant_anims[i % variant_anims.size()]

		var d: Node2D = dolphin_runner_scene.instantiate()
		add_child(d)
		d.setup(right, Vector2(start_x, y), anim_name,)


		# דיליי קטן שונה — בלי לגעת בסקריפט של הדולפין
		await get_tree().create_timer(randf_range(0.02, 0.14)).timeout


func _get_visible_world_rect() -> Rect2:
	var vp: Vector2 = get_viewport_rect().size
	var inv: Transform2D = get_viewport().get_canvas_transform().affine_inverse()

	var p0: Vector2 = inv * Vector2(0, 0)
	var p1: Vector2 = inv * Vector2(vp.x, 0)
	var p2: Vector2 = inv * Vector2(0, vp.y)
	var p3: Vector2 = inv * Vector2(vp.x, vp.y)

	var minx: float = minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
	var maxx: float = maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
	var miny: float = minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
	var maxy: float = maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))

	return Rect2(Vector2(minx, miny), Vector2(maxx - minx, maxy - miny))
