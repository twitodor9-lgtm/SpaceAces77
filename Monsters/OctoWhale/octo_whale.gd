extends Area2D

@export var drift_speed: float = 40.0
@export var bob_amp: float = 50.0
@export var bob_speed: float = 2.2
@export var sway_deg: float = 3.0

# טנטקלים
@export var tentacle_scene: PackedScene = preload("res://Monsters/OctoWhale/Tentacle.tscn")
@export var tentacle_offsets: Array[Vector2] = [Vector2(-60, 20), Vector2(60, 20)]

# התקפה (כולם ביחד)
@export var attack_interval: float = 2.2
@export var telegraph_time: float = 0.35
@export var strike_time: float = 0.18
@export var retract_time: float = 0.35

@onready var tentacles_root: Node2D = $Tentacles

var _t := 0.0
var _base_y := 0.0
var _tentacles: Array[Node] = []

func _ready() -> void:
	_base_y = global_position.y
	set_process(true)

	_start_visuals()
	_spawn_tentacles()
	call_deferred("_attack_loop") # מתחיל אחרי שהסצנה “מוכנה”

func _start_visuals() -> void:
	# מפעיל גם את הגוף (Body) וגם את האנימציה הנוספת אם קיימת
	var body := get_node_or_null("Body") as AnimatedSprite2D
	if body:
		body.play("default")

	var extra := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if extra:
		extra.play("default")

	var ap := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap and ap.has_animation("idle"):
		ap.play("idle")

func _spawn_tentacles() -> void:
	# יש כבר Tentacle בתוך OctoWhale/Tentacles בעץ הסצנה.
	# אז אנחנו מנקים כפילויות ומשאירים רק אחד.
	var holder := $Tentacles
	var keep := holder.get_node_or_null("Tentacle")

	for c in holder.get_children():
		if keep != null and c != keep:
			c.queue_free()

	# אם משום מה אין בכלל — ניצור אחד (אבל רק אחד)
	if keep == null:
		var ps: PackedScene = preload("res://Monsters/OctoWhale/Tentacle.tscn")
		keep = ps.instantiate()
		keep.name = "Tentacle"
		holder.add_child(keep)


func _attack_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(attack_interval).timeout

		# TELEGRAPH - כולם ביחד
		for t in _tentacles:
			if t and t.has_method("telegraph"):
				t.telegraph(telegraph_time)
		await get_tree().create_timer(telegraph_time).timeout

		# STRIKE - כולם ביחד
		for t in _tentacles:
			if t and t.has_method("strike"):
				t.strike(strike_time)
		await get_tree().create_timer(strike_time).timeout

		# RETRACT - כולם ביחד
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
