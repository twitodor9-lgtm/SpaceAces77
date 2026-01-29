extends Area2D
var _damaged_enemy_ids: Dictionary = {}



@export var speed: float = 650.0
@export var damage: int = 9999
@export var drift_x: float = 40.0
@export var despawn_margin: float = 300.0 # כמה מתחת למסך הנראה למחוק


var velocity: Vector2
var _variant_index: int = 0

@onready var variants_root: Node = $Variants

func set_variant_index(i: int) -> void:
	_variant_index = i

func _ready() -> void:
	
	# תנועה קבועה
	velocity = Vector2(0, speed)

	# מציג רק וריאציה אחת (גם Sprite וגם Collision)
	_apply_variant(_variant_index)

	# התחברות בטוחה (לא פעמיים)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta

	# ✅ מחיקה לפי "תחתית המסך הנראה" בעולם, לא לפי viewport pixels
	var bottom_y := _get_visible_world_bottom_y()
	if global_position.y > bottom_y + despawn_margin:
		queue_free()

func _get_visible_world_bottom_y() -> float:
	var vp_size: Vector2 = get_viewport_rect().size
	var inv := get_viewport().get_canvas_transform().affine_inverse()

	# נקודת תחתית-שמאל במסך -> עולם
	var world_bottom_left: Vector2 = inv * Vector2(0, vp_size.y)
	return world_bottom_left.y

func _apply_variant(i: int) -> void:
	var count := variants_root.get_child_count()
	if count <= 0:
		return

	i = clamp(i, 0, count - 1)

	for idx in range(count):
		var child := variants_root.get_child(idx)
		var active := (idx == i)
		child.visible = active
		_set_collisions_enabled(child, active)

func _set_collisions_enabled(node: Node, enabled: bool) -> void:
	for c in node.get_children():
		if c is CollisionShape2D:
			(c as CollisionShape2D).disabled = not enabled
		elif c is CollisionPolygon2D:
			(c as CollisionPolygon2D).disabled = not enabled
		_set_collisions_enabled(c, enabled)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("meteors"):
		return
	if area.is_in_group("clouds"):
		return

	var enemy := _find_enemy_root(area)
	if enemy == null:
		return
	if not enemy.has_method("take_damage"):
		return

	var id := enemy.get_instance_id()
	if _damaged_enemy_ids.has(id):
		return
	_damaged_enemy_ids[id] = true

	enemy.take_damage(damage)


	print("HIT:", area.name, " groups=", area.get_groups())

func _find_enemy_root(n: Node) -> Node:
	var cur: Node = n
	var found: Node = null
	while cur:
		if cur.is_in_group("enemies"):
			found = cur
		cur = cur.get_parent()
	return found
