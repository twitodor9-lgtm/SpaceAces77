extends Node2D
class_name MonsterDirector

var registry: MonsterRegistry
var _spawned: Dictionary = {} # id -> Node

func _ready() -> void:
	registry = _resolve_registry()
	call_deferred("_auto_spawn_stage_monsters")

func _resolve_registry() -> MonsterRegistry:
	# אם יש Autoload בשם "Monsters" (מומלץ) נשתמש בו
	var autoload := get_node_or_null("/root/Monsters")
	if autoload is MonsterRegistry:
		return autoload as MonsterRegistry

	# אחרת: ניצור מחסן מקומי (Instance)
	var r := MonsterRegistry.new()
	add_child(r)
	return r

func spawn_once(id: String, parent: Node, pos: Vector2) -> Node:
	# אם כבר קיים וחי — לא יוצרים כפילות
	if _spawned.has(id):
		var existing: Node = _spawned[id]
		if is_instance_valid(existing):
			return existing
		_spawned.erase(id)

	if registry == null:
		push_warning("MonsterDirector: registry is null")
		return null

	var inst := registry.spawn(id, parent, pos)
	_spawned[id] = inst
	return inst

func despawn(id: String) -> void:
	if not _spawned.has(id):
		return
	var inst: Node = _spawned[id]
	_spawned.erase(id)
	if is_instance_valid(inst):
		inst.queue_free()

# ===== Auto spawn =====
func _auto_spawn_stage_monsters() -> void:
	# דורש Autoload GameState (כי הקוד שלך משתמש בו בכל המשחק)
	if get_node_or_null("/root/GameState") == null:
		return

	var stage_root: Node = get_parent()
	if stage_root == null:
		return

	var stage: int = int(GameState.stage_index)
	if stage != 2:
		return

	# אם יש Marker בשם RaptorSpawn — נשתמש בו
	var marker := stage_root.get_node_or_null("RaptorSpawn")
	if marker is Node2D:
		spawn_once("void_raptor", stage_root, (marker as Node2D).global_position)
		return

	# אחרת: נשריץ בתוך המסך, ליד הצד הימני, ובגובה GroundLine
	var r := _get_visible_world_rect()
	var x := r.position.x + r.size.x - 120.0

	var y := r.position.y + r.size.y * 0.75
	var gl := stage_root.get_node_or_null("GroundLine")
	if gl is Node2D:
		y = (gl as Node2D).global_position.y - 90.0

	spawn_once("void_raptor", stage_root, Vector2(x, y))

func _get_visible_world_rect() -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var inv := get_viewport().get_canvas_transform().affine_inverse()

	var p0 := inv * Vector2(0, 0)
	var p1 := inv * Vector2(vp.x, 0)
	var p2 := inv * Vector2(0, vp.y)
	var p3 := inv * Vector2(vp.x, vp.y)

	var minx: float = minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
	var maxx: float = maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
	var miny: float = minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
	var maxy: float = maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))

	return Rect2(Vector2(minx, miny), Vector2(maxx - minx, maxy - miny))
