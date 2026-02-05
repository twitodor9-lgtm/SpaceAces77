extends Node2D

signal finished

@export var speed: float = 900.0
@export var splash_offset: Vector2 = Vector2(0, 0)

# ✅ רק שני טריגרים: "כניסה" ו"יציאה"
@export var entry_frame: int = 0
@export var exit_frame: int = 8

@export var worm_jump_distance: float = 90.0
@export var worm_hide_time: float = 0.06

# ויזואל
@export var portal_duration: float = 0.35
@export var portal_radius: float = 55.0
@export var portal_squash: float = 0.55

@onready var anim: AnimatedSprite2D = $Anim

var _right_x: float = 0.0
var _anim_to_play: StringName = &"run_0"
var _last_frame: int = -1

var _worm_jump_lock: bool = false
var _did_entry: bool = false
var _did_exit: bool = false

func setup(right_x: float, start_pos: Vector2, anim_name: StringName) -> void:
	_right_x = right_x
	global_position = start_pos
	_anim_to_play = anim_name

func _ready() -> void:
	if anim.sprite_frames == null:
		print("❌ DolphinRunner: Anim has no SpriteFrames")
		return
	if not anim.sprite_frames.has_animation(_anim_to_play):
		_anim_to_play = &"run_0"
	anim.play(_anim_to_play)

func _process(delta: float) -> void:
	global_position.x += speed * delta

	# טריגרים רק בכניסה/יציאה (פעם אחת בלבד לכל דולפין)
	if anim.frame != _last_frame:
		_last_frame = anim.frame

		if (not _did_entry) and anim.frame == entry_frame:
			_did_entry = true
			_do_wormhole_jump(global_position + splash_offset)

		elif (not _did_exit) and anim.frame == exit_frame:
			_did_exit = true
			_do_wormhole_jump(global_position + splash_offset)

	if global_position.x > _right_x + 200.0:
		finished.emit()
		queue_free()

func _do_wormhole_jump(from_pos: Vector2) -> void:
	if _worm_jump_lock:
		return
	_worm_jump_lock = true

	_spawn_wormhole(from_pos)

	# “נכנס לחור”
	if is_instance_valid(anim):
		anim.visible = false

	# קפיצה קטנה קדימה + חור יציאה
	global_position.x += worm_jump_distance
	_spawn_wormhole(global_position + splash_offset)

	await get_tree().create_timer(worm_hide_time).timeout
	if is_instance_valid(anim):
		anim.visible = true

	_worm_jump_lock = false

func _spawn_wormhole(pos: Vector2) -> void:
	var fx := WormholeFX.new()
	var parent := get_parent()
	if parent:
		parent.add_child(fx)
	else:
		add_child(fx)

	fx.global_position = pos
	fx.setup(portal_duration, portal_radius, portal_squash)
	fx.start()

class WormholeFX extends Node2D:
	var _t := 0.0
	var _dur := 0.35
	var _r0 := 10.0
	var _r1 := 55.0
	var _squash := 0.55

	func setup(dur: float, radius: float, squash: float) -> void:
		_dur = maxf(dur, 0.05)
		_r1 = maxf(radius, 10.0)
		_r0 = minf(_r1 * 0.18, 18.0)
		_squash = clampf(squash, 0.25, 1.0)

	func start() -> void:
		_t = 0.0
		set_process(true)

	func _process(delta: float) -> void:
		_t += delta
		rotation += delta * 6.0
		queue_redraw()
		if _t >= _dur:
			queue_free()

	func _draw() -> void:
		var u := clampf(_t / _dur, 0.0, 1.0)
		var r := lerpf(_r0, _r1, u)
		var a := lerpf(0.92, 0.0, u)

		# “פייק 3D” -> אליפסה + עומק קטן למטה + שפה/צל
		var depth_y := r * 0.16
		draw_set_transform(Vector2(0.0, depth_y), 0.0, Vector2(1.0, _squash))

		draw_arc(Vector2.ZERO, r * 1.02, 0.0, TAU, 88, Color(0, 0, 0, a * 0.25), 12.0)
		draw_arc(Vector2.ZERO, r, PI, TAU, 88, Color(0.85, 0.95, 1.0, a), 3.0)
		draw_arc(Vector2.ZERO, r, 0.0, PI, 88, Color(0.35, 0.45, 1.0, a * 0.85), 3.0)

		for k in range(6):
			var kk := float(k) / 5.0
			var rr := lerpf(r * 0.86, r * 0.28, kk)
			var aa := a * (1.0 - kk) * 0.75
			var ang := (u * TAU * 1.6) + float(k) * 0.55
			draw_arc(Vector2.ZERO, rr, ang, ang + TAU * 0.72, 72, Color(0.9, 0.45, 1.0, aa), 2.0)

		draw_circle(Vector2.ZERO, r * 0.33, Color(0.03, 0.0, 0.06, a * 0.95))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
