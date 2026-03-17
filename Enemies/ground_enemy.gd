extends Area2D

@export_group("Combat")
@export var max_health: int = 20
@export var player_damage_multiplier: float = 1.0
@export var score_value: int = 150

@export_group("AR HUD")
@export var show_in_ar_hud: bool = true
@export var ar_threat_type: String = "TURRET"
@export var ar_threat_text: String = ""

@export_group("Shooting")
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 200.0
@export var fire_interval: float = 0.6
@export var turn_speed: float = 4.0
@export var trigger_distance: float = 1300.0

var _can_shoot: bool = true
var confused: bool = false
var confusion_time := 1.7
var _dead: bool = false
var health: int = 0

# ---------------------------------------------------
# הפניות נכונות לפי מבנה הסצנה שלך
# ---------------------------------------------------
@onready var turret_root: Node2D = $TurretRoot
@onready var turret_sprite: Sprite2D = $TurretRoot/TurretSprite
@onready var muzzle: Marker2D = $TurretRoot/TurretSprite/Muzzle
@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	print("GroundEnemy spawned!  pos=", global_position)
	print_stack()

	add_to_group("ground_enemies")
	if show_in_ar_hud:
		add_to_group("health_bar_target")
	health = max(1, max_health)

	shoot_timer.wait_time = fire_interval
	shoot_timer.timeout.connect(_try_shoot)
	shoot_timer.start()

	# דיבוג – אפשר למחוק
	print("--- INIT ---")
	print("turret_root:   ", turret_root)
	print("turret_sprite: ", turret_sprite)
	print("muzzle:        ", muzzle)

func _process(delta: float) -> void:
	_rotate_turret(delta)

# ---------------------------------------------------
# סיבוב חלק + הגבלת זווית
# ---------------------------------------------------
func _rotate_turret(delta: float) -> void:
	if confused:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > trigger_distance:
		return

	var target_angle = (player.global_position - turret_root.global_position).angle()
	var current_angle = turret_root.rotation
	var new_angle = lerp_angle(current_angle, target_angle, delta * turn_speed)

	var min_angle = deg_to_rad(-150)
	var max_angle = deg_to_rad(+130)
	new_angle = clamp(new_angle, min_angle, max_angle)

	turret_root.rotation = new_angle

# ---------------------------------------------------
# ירי
# ---------------------------------------------------
func _try_shoot() -> void:
	if confused:
		return
	if not _can_shoot:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	_shoot_bullet()
	if player.is_hidden_low:
		return

func _shoot_bullet() -> void:
	if bullet_scene == null:
		push_error("GroundEnemy: bullet_scene is NULL (set it in Inspector).")
		shoot_timer.stop()
		return

	var inst = bullet_scene.instantiate()
	if inst.is_in_group("ground_enemies") or inst.has_method("take_damage"):
		push_error("GroundEnemy: bullet_scene points to an ENEMY scene, not a BULLET. Fix Inspector (bullet_scene).")
		if inst is Node:
			(inst as Node).queue_free()
		shoot_timer.stop()
		return

	var bullet: Node = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	if bullet is Node2D:
		(bullet as Node2D).global_position = muzzle.global_position
		(bullet as Node2D).rotation = turret_root.global_rotation

	var dir := turret_root.global_transform.x.normalized()
	if bullet.has_method("setup"):
		bullet.setup(dir, bullet_speed)

# ---------------------------------------------------
# פגיעה / מוות
# ---------------------------------------------------
func _award_score() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("add_score"):
		scene.call("add_score", score_value)

func take_damage(amount: int = 1) -> void:
	if _dead:
		return
	var final_damage := maxi(1, int(round(float(amount) * player_damage_multiplier)))
	health -= final_damage
	if health <= 0:
		_dead = true
		_award_score()
		queue_free()

# ---------------------------------------------------
# תגובה ל־LOOP של השחקן (בלבול)
# ---------------------------------------------------
func on_player_loop() -> void:
	if confused:
		return

	confused = true
	_can_shoot = false
	await get_tree().create_timer(confusion_time).timeout
	confused = false
	_can_shoot = true
