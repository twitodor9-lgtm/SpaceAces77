extends Area2D

@export var speed: float = 650.0
@export var damage: int = 9999
@export var drift_x: float = 40.0

var velocity: Vector2
var _variant_index: int = 0

@onready var variants_root: Node = $Variants

func set_variant_index(i: int) -> void:
	_variant_index = i

func _ready() -> void:
	# תנועה קבועה
	var x_drift := randf_range(-drift_x, drift_x)
	velocity = Vector2(x_drift, speed)

	# מציג רק וריאציה אחת (גם Sprite וגם Collision)
	_apply_variant(_variant_index)

	# מטאורים לא מתנגשים אחד בשני (רק אם המטאור על לייר 8 לדוגמה)
	# collision_layer = 1 << 7
	# collision_mask &= ~(1 << 7)

	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta
	if global_position.y > get_viewport_rect().size.y + 300:
		queue_free()

func _apply_variant(i: int) -> void:
	var count := variants_root.get_child_count()
	if count <= 0:
		return

	i = clamp(i, 0, count - 1)

	for idx in range(count):
		var child := variants_root.get_child(idx)
		child.visible = (idx == i)
		# אם יש שם CollisionShape2D / Area2D וכו’ זה עדיין יעבוד כי הוא בתוך אותו child

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("clouds"):
		return

	var node: Node = area
	while node:
		if node.has_method("take_damage"):
			node.take_damage(damage)
			queue_free()
			return
		node = node.get_parent()

	queue_free()
