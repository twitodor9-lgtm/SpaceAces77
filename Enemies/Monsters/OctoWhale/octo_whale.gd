extends Area2D

@export_group("Movement")
@export var drift_speed: float = 40.0
@export var bob_amp: float = 10.0
@export var bob_speed: float = 2.2
@export var sway_deg: float = 3.0

@export_group("Combat")
@export var max_health: int = 80
@export var player_damage_multiplier: float = 1.0
@export var score_value: int = 750

@export_group("AR HUD")
@export var show_in_ar_hud: bool = true
@export var ar_threat_type: String = "MONSTER"
@export var ar_threat_text: String = "OCTO WHALE"

@export_group("Tentacles")
@export var tentacle_scene: PackedScene = preload("res://Enemies/Monsters/OctoWhale/Tentacle.tscn")
@export var tentacle_offsets: Array[Vector2] = [Vector2(-60, 20), Vector2(60, 20)]

@export_group("Attack")
@export var attack_interval: float = 2.2
@export var telegraph_time: float = 0.35
@export var strike_time: float = 0.18
@export var retract_time: float = 0.35

@onready var tentacles_root: Node2D = $Tentacles

var _dead: bool = false
var health: int = 0
var _t := 0.0
var _base_y := 0.0
var _tentacles: Array[Node] = []
var _pivot_fixed := false

func _ready() -> void:
	health = max(1, max_health)
	add_to_group("health_bar_target")
	_fix_pivot()
	_base_y = global_position.y
	set_process(true)
	_start_visuals()
	_spawn_tentacles()
	call_deferred("_attack_loop")

func _fix_pivot() -> void:
	if _pivot_fixed:
		return
	var body := get_node_or_null("Body") as Node2D
	if body:
		position -= body.position
	_pivot_fixed = true

func _start_visuals() -> void:
	var body := get_node_or_null("Body") as AnimatedSprite2D
	if body:
		body.play("default")

	if tentacles_root:
		tentacles_root.z_index = -1
		if body:
			tentacles_root.visibility_layer = body.visibility_layer

	var extra := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if extra:
		extra.play("default")

	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap and ap.has_animation("idle"):
		ap.play("idle")

func _spawn_tentacles() -> void:
	_tentacles.clear()
	var holder := tentacles_root
	if holder == null:
		return

	var keep := holder.get_node_or_null("Tentacle")
	for c in holder.get_children():
		if keep != null and c != keep:
			c.queue_free()

	if keep == null:
		keep = tentacle_scene.instantiate()
		keep.name = "Tentacle"
		holder.add_child(keep)

	if keep:
		keep.visible = true
		_tentacles.append(keep)

func _attack_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(attack_interval).timeout
		for t in _tentacles:
			if t and t.has_method("telegraph"):
				t.telegraph(telegraph_time)
		await get_tree().create_timer(telegraph_time).timeout

		for t in _tentacles:
			if t and t.has_method("strike"):
				t.strike(strike_time)
		await get_tree().create_timer(strike_time).timeout

		for t in _tentacles:
			if t and t.has_method("retract"):
				t.retract(retract_time)

func _process(delta: float) -> void:
	_t += delta
	global_position.x -= drift_speed * delta
	global_position.y = _base_y + sin(_t * bob_speed) * bob_amp
	rotation = deg_to_rad(sin(_t * bob_speed) * sway_deg)

	var r := _get_visible_world_rect()
	if global_position.x < r.position.x - 200.0:
		global_position.x = r.position.x + r.size.x + 200.0
		_base_y = clamp(global_position.y, r.position.y + 60.0, r.position.y + r.size.y - 60.0)

func _die() -> void:
	if _dead:
		return
	_dead = true
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("add_score"):
		scene.call("add_score", score_value)
	queue_free()

func take_damage(amount: int) -> void:
	if _dead:
		return
	var final_damage := maxi(1, int(round(float(amount) * player_damage_multiplier)))
	health -= final_damage
	if health <= 0:
		_die()

func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(health) / float(max_health)

func _get_visible_world_rect() -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var p0 := inv * Vector2(0, 0)
	var p3 := inv * Vector2(vp.x, vp.y)
	var minx := minf(p0.x, p3.x)
	var maxx := maxf(p0.x, p3.x)
	var miny := minf(p0.y, p3.y)
	var maxy := maxf(p0.y, p3.y)
	return Rect2(Vector2(minx, miny), Vector2(maxx - minx, maxy - miny))
