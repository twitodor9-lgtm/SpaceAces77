extends AbilityBase
@export var spawn_left_path: NodePath
@export var spawn_right_path: NodePath
@export var meteor_scene: PackedScene
@export var spawn_margin_top: float = 80.0
@export var side_margin: float = 80.0
@export var meteor_half_width: float = 32.0 # אם המטאור 64x64 אז 32

var _active := false

func _ready() -> void:
	add_to_group("star_punch")

func try_use() -> void:
	# רק StarPunch "ראשי"
	var nodes := get_tree().get_nodes_in_group("star_punch")
	var min_id := 9223372036854775807
	for n in nodes:
		min_id = min(min_id, n.get_instance_id())
	if get_instance_id() != min_id:
		return

	if _active:
		return
	if not can_use():
		return

	_active = true
	call_deferred("_release_lock")

	if meteor_scene == null:
		print("❌ STAR PUNCH: meteor_scene is null")
		_active = false
		return

	var L := get_node_or_null(spawn_left_path) as Node2D
	var R := get_node_or_null(spawn_right_path) as Node2D
	if L == null or R == null:
		print("❌ STAR PUNCH: markers not set/found (check Inspector paths)")
		_active = false
		return

	# גבולות ספאון לפי מרקרים (מסודר תמיד שמאל<ימין)
	var left_raw := L.global_position.x
	var right_raw := R.global_position.x
	var left := minf(left_raw, right_raw) + meteor_half_width
	var right := maxf(left_raw, right_raw) - meteor_half_width

	var spawn_y := minf(L.global_position.y, R.global_position.y) - spawn_margin_top

	var count := _count_variants()
	print("☀️ STAR PUNCH spawn_count=", count, " left=", left, " right=", right, " spawn_y=", spawn_y)

	if right <= left:
		print("❌ STAR PUNCH: marker range too small/reversed")
		_active = false
		return

	# ספאון במרווחים שווים (מונע חפיפה)
	var step := (right - left) / float(count)
	for i in range(count):
		var x := left + step * (float(i) + 0.5)

		var meteor: Node2D = meteor_scene.instantiate()
		if meteor.has_method("set_variant_index"):
			meteor.set_variant_index(i)

		get_tree().current_scene.add_child(meteor)
		meteor.global_position = Vector2(x, spawn_y)

		print("  meteor#", i, " x=", x)

	show_label()
	_active = false

func _release_lock() -> void:
	_active = false

func _count_variants() -> int:
	if meteor_scene == null:
		return 1

	var temp: Node = meteor_scene.instantiate()
	var variants: Node = temp.get_node_or_null("Variants")

	var c := 1
	if variants:
		c = 0
		for ch in variants.get_children():
			if ch is Node2D:
				c += 1

		# ✅ הדפסה בטוחה לפני queue_free
		print("VARIANTS CHILDREN:", variants.get_children())
	else:
		print("VARIANTS CHILDREN: <none>")

	temp.queue_free()
	return max(c, 1)

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
