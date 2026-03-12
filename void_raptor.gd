extends CharacterBody2D

@export var speed: float = 90.0
@export var chase_speed: float = 140.0
@export var jump_velocity: float = -260.0

@export var detect_range: float = 260.0
@export var bite_range: float = 38.0
@export var spit_range: float = 220.0

@export var spit_cooldown: float = 2.2
@export var jump_cooldown: float = 1.4

@export var projectile_scene: PackedScene  # PlasmaProjectile.tscn

var anim: AnimatedSprite2D = null
var ground_ray: RayCast2D = null
var muzzle: Marker2D = null

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: Node2D = null
var spit_timer: float = 0.0
var jump_timer: float = 0.0
var facing: int = 1  # 1 ימינה, -1 שמאלה

func _ready() -> void:
	# Player יכול להיות בקבוצה "Player" או "player"
	player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	# למצוא את האנימציה בצורה יציבה
	anim = get_node_or_null("Anim") as AnimatedSprite2D
	if anim == null:
		anim = get_node_or_null("Anima") as AnimatedSprite2D
	if anim == null:
		for c in get_children():
			if c is AnimatedSprite2D:
				anim = c as AnimatedSprite2D
				break

	ground_ray = get_node_or_null("GroundRay") as RayCast2D
	muzzle = get_node_or_null("Muzzle") as Marker2D

	# ברירת מחדל: idle אם קיים
	if _has_anim("idle"):
		_play_loop("idle")

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		apply_gravity(delta)
		move_and_slide()
		return

	spit_timer = maxf(0.0, spit_timer - delta)
	jump_timer = maxf(0.0, jump_timer - delta)

	var dx: float = player.global_position.x - global_position.x
	var dist: float = absf(dx)

	facing = 1 if dx >= 0.0 else -1
	if anim != null:
		anim.flip_h = (facing == -1)

	apply_gravity(delta)

	# 0) רחוק מדי -> עומד במקום (כדי לראות idle)
	if dist >= detect_range:
		velocity.x = 0.0
		if is_on_floor():
			_play_loop("idle")
		move_and_slide()
		return

	# 1) אם קרוב מאוד -> נשיכה
	if dist <= bite_range and is_on_floor():
		velocity.x = 0.0
		play_one("bite")
		move_and_slide()
		return

	# 2) יריקה (רק בטווח בינוני, עם קולדאון, ורק אם על הרצפה)
	if dist <= spit_range and dist > bite_range and is_on_floor() and spit_timer <= 0.0 and projectile_scene != null:
		velocity.x = 0.0
		play_one("spit")
		fire_projectile()
		spit_timer = spit_cooldown
		move_and_slide()
		return

	# 3) קפיצה (רק אם יש אנימציה "jump")
	var player_above: bool = player.global_position.y < global_position.y - 20.0
	if is_on_floor() and jump_timer <= 0.0 and player_above:
		velocity.y = jump_velocity
		jump_timer = jump_cooldown
		play_one("jump")

	# 4) ריצה / מרדף
	velocity.x = float(facing) * chase_speed
	if is_on_floor():
		_play_loop("run")

	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _has_anim(name: String) -> bool:
	return anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation(name)

func _play_loop(name: String) -> void:
	if not _has_anim(name):
		return
	# לא לאתחל מחדש כל פריים
	if anim.animation != name or not anim.is_playing():
		anim.play(name)

func play_one(name: String) -> void:
	if not _has_anim(name):
		return
	# תמיד להתחיל מהתחלה
	anim.play(name)
	anim.frame = 0

func fire_projectile() -> void:
	if projectile_scene == null:
		return

	var p := projectile_scene.instantiate() as Node2D
	get_parent().add_child(p)

	if muzzle != null:
		p.global_position = muzzle.global_position
	else:
		p.global_position = global_position

	if p.has_method("set_dir"):
		p.call("set_dir", facing)

# אופציונלי: אפשר לקרוא מבחוץ כדי לבדוק אנימציות
func debug_force_anim(name: String) -> void:
	play_one(name)
