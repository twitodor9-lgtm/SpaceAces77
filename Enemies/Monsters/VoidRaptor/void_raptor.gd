extends CharacterBody2D

const SimpleExplosionFX = preload("res://scripts/simple_explosion_fx.gd")

@export_group("Movement")
@export var speed: float = 90.0
@export var chase_speed: float = 140.0
@export var jump_velocity: float = -260.0
@export var detect_range: float = 260.0
@export var bite_range: float = 38.0
@export var spit_range: float = 220.0

@export_group("Combat")
@export var max_health: int = 35
@export var player_damage_multiplier: float = 1.0
@export var score_value: int = 400
@export var hit_fx_scale: float = 1.0
@export var death_fx_scale: float = 2.0

@export_group("AR HUD")
@export var show_in_ar_hud: bool = true
@export var ar_threat_type: String = "MONSTER"
@export var ar_threat_text: String = "VOID RAPTOR"

@export_group("Abilities")
@export var spit_cooldown: float = 2.2
@export var jump_cooldown: float = 1.4
@export var bite_damage: int = 1
@export var projectile_scene: PackedScene

var anim: AnimatedSprite2D = null
var ground_ray: RayCast2D = null
var muzzle: Marker2D = null

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: Node2D = null
var spit_timer: float = 0.0
var jump_timer: float = 0.0
var facing: int = 1
var _health: int = 0
var _dead: bool = false

func _ready() -> void:
	_health = max(1, max_health)
	if show_in_ar_hud:
		add_to_group("health_bar_target")
	player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

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

	if _has_anim("idle"):
		_play_loop("idle")

func _physics_process(delta: float) -> void:
	if _dead:
		velocity.x = 0.0
		apply_gravity(delta)
		move_and_slide()
		return

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

	if dist >= detect_range:
		velocity.x = 0.0
		if is_on_floor():
			_play_loop("idle")
		move_and_slide()
		return

	if dist <= bite_range and is_on_floor():
		velocity.x = 0.0
		play_one("bite")
		if global_position.distance_to(player.global_position) <= bite_range + 4.0 and player.has_method("take_damage"):
			player.take_damage(bite_damage)
		move_and_slide()
		return

	if dist <= spit_range and dist > bite_range and is_on_floor() and spit_timer <= 0.0 and projectile_scene != null:
		velocity.x = 0.0
		play_one("spit")
		fire_projectile()
		spit_timer = spit_cooldown
		move_and_slide()
		return

	var player_above: bool = player.global_position.y < global_position.y - 20.0
	if is_on_floor() and jump_timer <= 0.0 and player_above:
		velocity.y = jump_velocity
		jump_timer = jump_cooldown
		play_one("jump")

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
	if anim.animation != name or not anim.is_playing():
		anim.play(name)

func play_one(name: String) -> void:
	if not _has_anim(name):
		return
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

func _spawn_hit_fx() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		SimpleExplosionFX.spawn_hit(scene, global_position, hit_fx_scale)

func _spawn_death_fx() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		SimpleExplosionFX.spawn_death(scene, global_position, death_fx_scale)

func take_damage(amount: int) -> void:
	if _dead:
		return
	var final_damage := maxi(1, int(round(float(amount) * player_damage_multiplier)))
	_health -= final_damage
	_spawn_hit_fx()
	if _health <= 0:
		_dead = true
		_spawn_death_fx()
		_award_score()
		queue_free()

func _award_score() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("add_score"):
		scene.call("add_score", score_value)

func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(_health) / float(max_health)

func debug_force_anim(name: String) -> void:
	play_one(name)
