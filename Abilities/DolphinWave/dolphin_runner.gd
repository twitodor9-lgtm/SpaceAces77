extends Node2D

@export var speed: float = 900.0
@export var splash_frames: Array[int] = [0, 8] # שנה לפי השיט שלך
@export var splash_offset: Vector2 = Vector2(0, 0) # אם צריך להזיז קצת את נקודת האדווה

@onready var anim: AnimatedSprite2D = $Anim

var _right_x: float = 0.0
var _anim_to_play: StringName = &"run_0"
var _last_frame: int = -1

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

	# אדוות רק בפריימי "ספלאש" (כניסה/יציאה)
	if anim.frame != _last_frame:
		_last_frame = anim.frame
		if splash_frames.has(_last_frame):
			_spawn_ripple(global_position + splash_offset)

	if global_position.x > _right_x + 200.0:
		queue_free()

func _spawn_ripple(pos: Vector2) -> void:
	var ripple := RippleFX.new()
	get_parent().add_child(ripple)
	ripple.global_position = pos
	ripple.start()

class RippleFX extends Node2D:
	var _t := 0.0
	var _dur := 0.45
	var _r0 := 8.0
	var _r1 := 90.0

	func start() -> void:
		_t = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t >= _dur:
			queue_free()

	func _draw() -> void:
		var u := clampf(_t / _dur, 0.0, 1.0)
		var r := lerpf(_r0, _r1, u)
		var a := lerpf(0.55, 0.0, u)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.8, 0.95, 1.0, a), 2.0)
		draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 48, Color(0.8, 0.95, 1.0, a * 0.7), 1.0)
