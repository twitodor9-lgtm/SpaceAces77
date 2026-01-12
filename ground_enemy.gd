extends Area2D

@export var health: int = 3
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 200.0
@export var fire_interval: float = 0.6
@export var turn_speed: float = 4.0   # סיבוב חלק של הצריח
@export var trigger_distance: float = 1300.0

var _can_shoot: bool = true
var _cooldown: bool = false

@onready var turret: Sprite2D = $Turret
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	add_to_group("ground_enemies")
	shoot_timer.wait_time = fire_interval
	shoot_timer.start()
	shoot_timer.timeout.connect(_try_shoot)


func _process(delta: float) -> void:
	_rotate_turret(delta)


func _rotate_turret(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > trigger_distance:
		return

	var target_angle = (player.global_position - turret.global_position).angle()

	# סיבוב חלק (LERP)
	var current_angle = turret.rotation
	var new_angle = lerp_angle(current_angle, target_angle, delta * turn_speed)
	turret.rotation = new_angle


func _try_shoot() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	if not _can_shoot:
		return

	_shoot_bullet()


func _shoot_bullet() -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# הכדור יוצא בדיוק מהמוזל
	bullet.global_position = muzzle.global_position

	# כיוון ירי מדויק לפי סיבוב הצריח
	var dir = turret.global_transform.x.normalized()

	if bullet.has_method("setup"):
		bullet.setup(dir, bullet_speed)
func _update_turret_frame() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dir := (player.global_position - global_position).normalized()
	var angle := rad_to_deg(dir.angle())  # -180 .. 180

	# מסובבים כדי שימין = 0°, שמאל = 180
	angle = fmod(angle + 360.0, 360.0)

	# טווחים:
	# 0   - 36   → פריים 4 (ימין)
	# 36  - 108 → פריים 3 (ימין למעלה)
	# 108 - 252 → פריים 2 (למעלה)
	# 252 - 324 → פריים 1 (שמאל למעלה)
	# 324 - 360 → פריים 0 (שמאל)

	if angle < 36 or angle >= 324:
		turret.frame = 4
	elif angle < 108:
		turret.frame = 3
	elif angle < 252:
		turret.frame = 2
	elif angle < 324:
		turret.frame = 1
	else:
		turret.frame = 0
