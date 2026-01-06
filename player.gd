extends Area2D

# =========================
# Flight
# =========================
@export var forward_speed: float = 250.0     # constant forward speed
@export var rotation_speed: float = 2.5      # radians/sec

var screen_size: Vector2

# =========================
# Shooting
# =========================
@export var bullet_scene: PackedScene = preload("res://Bullet.tscn")
@export var shoot_cooldown: float = 0.15
var can_shoot := true

# =========================
# Bombs
# =========================
@export var bomb_scene: PackedScene = preload("res://Bomb.tscn")
@export var bomb_cooldown: float = 1.0
var can_drop_bomb := true

# =========================
# Visual scale (fixed, never flipped by angle)
# =========================
@export var base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	screen_size = get_viewport_rect().size

	# ensure positive base scale (we do NOT flip it in gameplay)
	base_scale = Vector2(abs(base_scale.x), abs(base_scale.y))
	scale = base_scale

	# play animation if exists
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("FLY")
	elif has_node("AnimatedSprite"):
		$AnimatedSprite.play("FLY")

	add_to_group("player")


func _process(delta: float) -> void:
	# -------- Rotation (Dogfight style) --------
	if Input.is_action_pressed("ui_left"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("ui_right"):
		rotation += rotation_speed * delta

	# Keep scale fixed: rotation is what should visually rotate the ship.
	scale = base_scale

	# -------- Forward movement --------
	# Ship art should be drawn facing RIGHT at rotation = 0.
	var velocity := Vector2(forward_speed, 0.0).rotated(rotation)
	position += velocity * delta

	# -------- Wrap Around --------
	var margin := 50.0
	if position.x < -margin:
		position.x = screen_size.x + margin
	elif position.x > screen_size.x + margin:
		position.x = -margin

	if position.y < -margin:
		position.y = screen_size.y + margin
	elif position.y > screen_size.y + margin:
		position.y = -margin

	# -------- Shoot --------
	if Input.is_action_pressed("ui_select") and can_shoot:
		shoot()

	# -------- Drop bomb --------
	if Input.is_action_pressed("drop_bomb") and can_drop_bomb:
		drop_bomb()


func shoot() -> void:
	if bullet_scene == null:
		return

	can_shoot = false

	var bullet = bullet_scene.instantiate()

	# Prefer a dedicated GunPoint marker if you add one:
	# Player
	#  └ AnimatedSprite2D
	#      └ GunPoint (Marker2D)
	var spawn_pos: Vector2 = global_position
	if has_node("AnimatedSprite2D/GunPoint"):
		spawn_pos = $AnimatedSprite2D/GunPoint.global_position
	else:
		# fallback offset from nose (tune if needed)
		var bullet_offset := Vector2(40.0, 0.0).rotated(rotation)
		spawn_pos = global_position + bullet_offset

	bullet.global_position = spawn_pos
	bullet.rotation = rotation

	# Add to same world level as player so transforms are consistent
	get_tree().current_scene.add_child(bullet)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


func drop_bomb() -> void:
	if bomb_scene == null:
		return

	can_drop_bomb = false

	var bomb = bomb_scene.instantiate()

	# Use BombDropPoint if exists (you already have it)
	var drop_pos: Vector2 = global_position
	if has_node("AnimatedSprite2D/BombDropPoint"):
		drop_pos = $AnimatedSprite2D/BombDropPoint.global_position

	bomb.global_position = drop_pos

	# Bomb usually falls “down” in screen-space, so keep it unrotated
	bomb.rotation = 0.0

	get_tree().current_scene.add_child(bomb)

	await get_tree().create_timer(bomb_cooldown).timeout
	can_drop_bomb = true


#func _on_area_entered(area: Area2D) -> void:
	#if area.is_in_group("enemies") or area.is_in_group("ground_enemies") or area.is_in_group("enemy_bullets"):
		#var main = get_tree().root.get_node_or_null("Main")
		#if main and main.has_method("player_died"):
			#main.player_died()
		#queue_free()
