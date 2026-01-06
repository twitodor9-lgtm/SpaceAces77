extends Area2D

@export var health: int = 3
@export var bullet_scene: PackedScene
@export var clip_size: int = 10
@export var reload_time: float = 2.0
@export var bullet_speed: float = 200.0
@export var fire_interval: float = 0.55

var _current_ammo: int = 0
var _is_reloading: bool = false

@onready var turret: AnimatedSprite2D = $Turret
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	add_to_group("ground_enemies")
	_current_ammo = clip_size

	if shoot_timer != null:
		shoot_timer.wait_time = fire_interval
		shoot_timer.one_shot = false
		if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
			shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		shoot_timer.start()
	else:
		push_error("ShootTimer missing in GroundEnemy!")


func _process(_delta: float) -> void:
	_update_turret_frame()


# ------------------------------------------------
#     שליטה בטיימר וירי
# ------------------------------------------------
func _on_shoot_timer_timeout() -> void:
	if _is_reloading:
		return

	# ⭐ פשטתי - אם התותח עוקב אחרי השחקן, הוא תמיד מכוון אליו
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	if _current_ammo <= 0:
		_start_reload()
		return

	_shoot_bullet()
	_current_ammo -= 1


# ------------------------------------------------
#     ירי מדויק מהקנה (מוזל)
# ------------------------------------------------
func _shoot_bullet() -> void:
	if bullet_scene == null:
		return

	var muzzle: Node2D = _get_current_muzzle()
	if muzzle == null:
		return

	var bullet: Node2D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var spawn: Vector2 = muzzle.global_position
	bullet.global_position = spawn

	# הכיוון האמיתי של הקנה
	var dir: Vector2 = muzzle.global_transform.x.normalized()

	if bullet.has_method("setup"):
		bullet.setup(dir, bullet_speed)


# ------------------------------------------------
#     טעינה מחדש
# ------------------------------------------------
func _start_reload() -> void:
	_is_reloading = true
	await get_tree().create_timer(reload_time).timeout
	_current_ammo = clip_size
	_is_reloading = false


# ------------------------------------------------
#     בחירת המוזל המתאים לפי פריים
# ------------------------------------------------
func _get_current_muzzle() -> Node2D:
	var frame: int = clamp(turret.frame, 0, 4)
	var node_name: String = "Muzzle" + str(frame)

	if $Turret.has_node(node_name):
		return $Turret.get_node(node_name) as Node2D

	push_error("Missing muzzle: " + node_name)
	return null


# ------------------------------------------------
#     שינוי פריים של התותח לפי השחקן (⭐ תוקן!)
# ------------------------------------------------
func _update_turret_frame() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dir: Vector2 = (player.global_position - global_position).normalized()
	var a: float = rad_to_deg(dir.angle())

	# חלוקה ל-5 אזורים של 72 מעלות כל אחד
	# frame 0: שמאל       (-180 עד -108)
	# frame 1: שמאל-למעלה (-108 עד -36)
	# frame 2: למעלה      (-36 עד 36)
	# frame 3: ימין-למעלה (36 עד 108)
	# frame 4: ימין       (108 עד 180)
	
	if a >= -180 and a < -108:
		turret.frame = 0
	elif a >= -108 and a < -36:
		turret.frame = 1
	elif a >= -36 and a < 36:
		turret.frame = 2
	elif a >= 36 and a < 108:
		turret.frame = 3
	else:  # 108 עד 180
		turret.frame = 4


# ------------------------------------------------
#     פגיעה בטנק
# ------------------------------------------------
func take_damage() -> void:
	health -= 1
	if health <= 0:
		var main := get_tree().root.get_node_or_null("Main")
		if main and main.has_method("add_score"):
			main.add_score(50)
		queue_free()
