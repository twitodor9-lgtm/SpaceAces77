extends AbilityBase

@export var dolphin_runner_scene: PackedScene
@export var damage: int = 9999
@export var dolphins_count: int = 6
@export var side_margin: float = 80.0
@export var top_margin: float = 60.0
@export var variant_anims: Array[StringName] = [&"run_0"]

# גיבוי: כל כמה זמן לסרוק שוב אויבים בזמן שהגל פעיל
@export var sweep_interval: float = 0.12

const KILL_META := &"dolphin_wave_killed"

var _active: bool = false
var _kill_active: bool = false
var _runners_alive: int = 0

func try_use() -> void:
	if _active:
		return
	if not can_use():
		return

	_active = true
	_start_kill_window()
	show_label()

	# הורגים את מי שכבר קיים עכשיו
	_damage_all_enemies()

	# מריצים להקה ומחכים שכולם ייצאו מהמסך
	await _spawn_pod(_get_visible_world_rect())
	await _wait_for_pod_to_finish()

	_end_kill_window()
	_active = false


func _start_kill_window() -> void:
	_kill_active = true
	var tree := get_tree()
	if tree and not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)


func _end_kill_window() -> void:
	_kill_active = false
	var tree := get_tree()
	if tree and tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.disconnect(_on_tree_node_added)


func _on_tree_node_added(n: Node) -> void:
	if not _kill_active:
		return
	# הרבה אויבים נכנסים לקבוצה ב-_ready, אז בודקים פריים אחרי
	call_deferred("_try_kill_if_enemy", n)


func _try_kill_if_enemy(n: Node) -> void:
	if not _kill_active or not is_instance_valid(n):
		return
	if n.is_in_group("enemies") and n.has_method("take_damage"):
		_kill_enemy(n)


func _kill_enemy(e: Node) -> void:
	if not is_instance_valid(e):
		return
	if e.has_meta(KILL_META):
		return
	e.set_meta(KILL_META, true)
	e.call("take_damage", damage)


func _on_runner_finished() -> void:
	_runners_alive = maxi(_runners_alive - 1, 0)


func _wait_for_pod_to_finish() -> void:
	var next_sweep_ms := 0
	while _runners_alive > 0:
		# גיבוי: “סורק” מדי פעם גם אויבים שכבר קיימים / הצטרפו באיחור
		var now := Time.get_ticks_msec()
		if now >= next_sweep_ms:
			next_sweep_ms = now + int(sweep_interval * 1000.0)
			_damage_all_enemies()
		await get_tree().process_frame


func _damage_all_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			_kill_enemy(e)


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

	for i in range(count):
		var lane := i % lanes
		var y := top + lane_step * float(lane + 1) + randf_range(-10.0, 10.0)

		# להקה טבעית: מרחקים לא אחידים ב-X
		var spacing := 55.0
		var jitter_x := randf_range(-45.0, 35.0)
		var start_x := left - 180.0 - float(i) * spacing + jitter_x

		var anim_name := variant_anims[i % maxi(variant_anims.size(), 1)]

		var d: Node2D = dolphin_runner_scene.instantiate()
		add_child(d)

		if d.has_signal("finished"):
			_runners_alive += 1
			d.finished.connect(_on_runner_finished)

		if d.has_method("setup"):
			d.setup(right, Vector2(start_x, y), anim_name)

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
