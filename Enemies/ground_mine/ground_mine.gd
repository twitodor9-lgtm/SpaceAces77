extends CharacterBody2D

# --- Spawn / Burrow ---
@export var burrow_depth: float = 18.0
@export var pop_delay: float = 0.10
@export var emerge_time: float = 0.12

# --- Jump attack ---
@export var jump_speed: float = 420.0
@export var jump_attack_time: float = 0.40   # זמן שבו הוא רק "קופץ" בלי רדיפה

# --- Jet chase ---
@export var chase_time: float = 2.2
@export var chase_speed: float = 260.0
@export var steer_accel: float = 1200.0      # כמה מהר הוא משנה כיוון (גבוה = יותר הומינג)
@export var jet_gravity_scale: float = 0.35  # כמה "נופל" בזמן ג'ט (0=מרחף, 1=כמו רגיל)

# --- Physics / End ---
@export var gravity: float = 1200.0
@export var explode_on_land: bool = true

@export var player_group: StringName = &"player"

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

enum State { BURROWED, EMERGING, JUMP_ATTACK, JET_CHASE, FALLING }
var state: State = State.BURROWED

var _surface_pos: Vector2
var _timer: float = 0.0
var _player: Node2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group(player_group) as Node2D

	_surface_pos = global_position
	global_position = _surface_pos + Vector2(0.0, burrow_depth)

	sprite.visible = false
	col.disabled = true

	_start_sequence()

func _start_sequence() -> void:
	await get_tree().create_timer(pop_delay).timeout

	state = State.EMERGING
	sprite.visible = true

	var tw := create_tween()
	tw.tween_property(self, "global_position", _surface_pos, emerge_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished

	col.disabled = false
	state = State.JUMP_ATTACK
	_timer = jump_attack_time
	velocity = Vector2(0.0, -jump_speed)

func _physics_process(delta: float) -> void:
	if col.disabled:
		return

	match state:
		State.JUMP_ATTACK:
			# קפיצה רגילה + גרביטציה
			velocity.y += gravity * delta
			_timer -= delta
			if _timer <= 0.0:
				state = State.JET_CHASE
				_timer = chase_time

		State.JET_CHASE:
			# רדיפת ג'ט: היגוי מוגבל (לא פונה מיד 180°)
			_timer -= delta

			var g := gravity * jet_gravity_scale
			velocity.y += g * delta

			if _player != null:
				var to_player := (_player.global_position - global_position)
				var desired := to_player.normalized() * chase_speed

				# steer: זזים בהדרגה לכיוון המהירות הרצויה
				velocity = velocity.move_toward(desired, steer_accel * delta)

			if _timer <= 0.0:
				state = State.FALLING

		State.FALLING:
			# נגמר דלק -> נופל רגיל
			velocity.y += gravity * delta

		_:
			pass

	move_and_slide()

	# סוף: אם נוחתים — נמחק/מתפוצצים
	if is_on_floor() and state != State.BURROWED and explode_on_land:
		queue_free()
