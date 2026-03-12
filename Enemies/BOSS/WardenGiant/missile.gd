extends Area2D

@export var speed: float = 260.0
@export var turn_speed: float = 7.0
@export var lifetime: float = 4.0
@export var damage: int = 1

var target: Node2D
var shooter: Node2D

var vel := Vector2.RIGHT

func set_target(t: Node2D) -> void:
	target = t

func set_shooter(o: Node2D) -> void:
	shooter = o

func deflect_to(new_target: Node2D) -> void:
	# שימושי לכוח של השחקן: להפוך את הטילים נגד הבוס
	target = new_target

func _ready() -> void:
	add_to_group("enemy_projectiles")
	body_entered.connect(_on_body_entered)

	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		var desired := (target.global_position - global_position).normalized()
		vel = vel.lerp(desired, clampf(turn_speed * delta, 0.0, 1.0)).normalized()

	global_position += vel * speed * delta
	rotation = vel.angle()

func _on_body_entered(body: Node) -> void:
	# לפעמים יש collision בפריים הראשון לפני שקיבלנו set_shooter מהבוס.
	# במקרה כזה נתעלם מפגיעה בבוס כדי שהטיל לא ייעלם מיד.
	if shooter == null and body.is_in_group("boss"):
		return

	# לא לפגוע במי שירה אותך
	if shooter != null and body == shooter:
		return

	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	elif body.has_method("hurt"):
		body.call("hurt", damage)

	queue_free()
