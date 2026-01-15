extends Area2D

@export var health: int = 3
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 200.0
@export var fire_interval: float = 0.6
@export var turn_speed: float = 4.0
@export var trigger_distance: float = 1300.0

var _can_shoot: bool = true
var confused: bool = false
var confusion_time := 1.7

# ---------------------------------------------------
# הפניות נכונות לפי מבנה הסצנה שלך
# ---------------------------------------------------
@onready var turret_root: Node2D = $TurretRoot
@onready var turret_sprite: Sprite2D = $TurretRoot/TurretSprite
@onready var muzzle: Marker2D = $TurretRoot/TurretSprite/Muzzle
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	add_to_group("ground_enemies")

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
	if confused:   # כשהאויב מבולבל הוא לא מסתובב
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > trigger_distance:
		return

	# זווית המטרה
	var target_angle = (player.global_position - turret_root.global_position).angle()
	var current_angle = turret_root.rotation

	var new_angle = lerp_angle(current_angle, target_angle, delta * turn_speed)

	# הגבלת סיבוב
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


func _shoot_bullet() -> void:
	if bullet_scene == null:
		return
	if muzzle == null:
		push_error("ERROR: muzzle node is NULL! Check node paths.")
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# יציאה מדויקת מהמוזל
	bullet.global_position = muzzle.global_position

	# כיוון הירי לפי הצריח — לא הספרייט!
	var dir := turret_root.global_transform.x.normalized()

	if bullet.has_method("setup"):
		bullet.setup(dir, bullet_speed)


# ---------------------------------------------------
# פגיעה / מוות
# ---------------------------------------------------
func take_damage(amount: int = 1) -> void:
	health -= amount
	if health <= 0:
		queue_free()



# ---------------------------------------------------
# תגובה ל־LOOP של השחקן (בלבול)
# ---------------------------------------------------
func on_player_loop() -> void:
	if confused:
		return

	confused = true
	_can_shoot = false

	# בעתיד אפשר להוסיף אפקט ויזואלי כמו "סחרחורת"
	await get_tree().create_timer(confusion_time).timeout

	confused = false
	_can_shoot = true
