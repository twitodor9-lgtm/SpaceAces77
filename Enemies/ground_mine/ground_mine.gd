extends CharacterBody2D

# --- Phase timing (seconds) ---
@export var idle_time: float = 0.80
@export var run_time: float = 1.00
@export var jet_time: float = 0.50
@export var bite_time: float = 0.90

# --- Movement ---
@export var run_speed: float = 85.0
@export var jet_speed: float = 260.0
@export var bite_speed: float = 220.0
@export var steer_accel: float = 1200.0
@export var gravity: float = 1200.0
@export var jet_gravity_scale: float = 0.35
@export var bite_distance_threshold: float = 120.0
@export var contact_radius: float = 18.0
@export var explode_on_bite_timeout: bool = true

# --- Small hop on run -> jet transition ---
@export var jet_hop_up_speed: float = 120.0

# --- Visual flight facing ---
# אם הארט שלך מצויר "פונה ימינה" השאר 0
# אם הארט מצויר "פונה למעלה/שמאלה" תוכל לקזז כאן
@export var sprite_forward_angle_deg: float = 0.0
@export var flight_turn_speed_deg: float = 720.0

@export var player_group: StringName = &"player"

# --- Anim names (shown in Inspector) ---
@export var anim_idle: StringName = &"idle"
@export var anim_run: StringName = &"run"
@export var anim_jet: StringName = &"JET"
@export var anim_bite: StringName = &"bite"
@export var anim_death: StringName = &"death"
@export var debug_anim: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D
@onready var hit_area: Area2D = $HitArea
@onready var anim: AnimationPlayer = get_node_or_null(^"AnimationPlayer")

enum State { IDLE, RUN, JET, BITE, DEAD }
var state: State = State.IDLE

var _timer: float = 0.0
var _player: Node2D = null
var _dying: bool = false


func _ready() -> void:
	_player = _find_player()

	sprite.visible = true
	col.disabled = false

	if hit_area != null and not hit_area.area_entered.is_connected(_on_hit_area_area_entered):
		hit_area.area_entered.connect(_on_hit_area_area_entered)

	if debug_anim and anim != null:
		print("[GroundMine] animations: ", anim.get_animation_list())

	_set_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if _dying:
		return

	if _player == null or not is_instance_valid(_player):
		_player = _find_player()

	_timer = maxf(_timer - delta, -1.0)

	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, steer_accel * delta)
			velocity.y += gravity * delta

			if _timer <= 0.0:
				_set_state(State.RUN)

		State.RUN:
			velocity.y += gravity * delta
			_move_horizontally_toward_player(run_speed, delta)

			if _timer <= 0.0:
				if _should_bite_first():
					_set_state(State.BITE)
				else:
					_set_state(State.JET)

		State.JET:
			velocity.y += gravity * jet_gravity_scale * delta
			_home_toward_player(jet_speed, delta)

			if _timer <= 0.0:
				_set_state(State.BITE)

		State.BITE:
			_home_toward_player(bite_speed, delta)

			if explode_on_bite_timeout and _timer <= 0.0:
				_explode_and_free()
				return

		State.DEAD:
			return

	_update_sprite_visuals(delta)
	move_and_slide()

	# גיבוי: גם אם Area לא תפסה בזמן, מגע קרוב עם השחקן עדיין יפוצץ
	if not _dying and _touching_player_by_distance():
		_explode_and_free()


func _find_player() -> Node2D:
	var p: Node2D = get_tree().get_first_node_in_group(player_group) as Node2D
	if p != null:
		return p

	p = get_tree().get_first_node_in_group(&"Player") as Node2D
	if p != null:
		return p

	p = get_tree().get_first_node_in_group(&"player") as Node2D
	return p


func _play_anim(name: StringName, restart: bool = false) -> void:
	if anim == null:
		return
	if name == StringName():
		return

	var anim_name: String = String(name)
	if not anim.has_animation(anim_name):
		if debug_anim:
			push_warning("GroundMine: missing animation '%s' (existing=%s)" % [anim_name, str(anim.get_animation_list())])
		return

	if restart:
		anim.play(anim_name)
		anim.seek(0.0, true)
		if debug_anim:
			print("[GroundMine] play anim: ", anim_name)
		return

	if anim.current_animation != anim_name:
		anim.play(anim_name)
		if debug_anim:
			print("[GroundMine] play anim: ", anim_name)


func _set_state(new_state: State) -> void:
	if _dying and new_state != State.DEAD:
		return

	var prev_state: State = state
	state = new_state

	match state:
		State.IDLE:
			_timer = idle_time
			_play_anim(anim_idle, true)

		State.RUN:
			_timer = run_time
			_play_anim(anim_run, true)

		State.JET:
			_timer = jet_time

			# קפיצה קטנה ברגע המעבר מריצה לג'ט
			if prev_state == State.RUN:
				velocity.y = -absf(jet_hop_up_speed)

			_play_anim(anim_jet, true)

		State.BITE:
			_timer = bite_time
			_play_anim(anim_bite, true)

		State.DEAD:
			_timer = 0.0
			_play_anim(anim_death, true)


func _move_horizontally_toward_player(speed_value: float, delta: float) -> void:
	if _player == null:
		velocity.x = move_toward(velocity.x, 0.0, steer_accel * delta)
		return

	var dx: float = _player.global_position.x - global_position.x
	var dir: float = signf(dx)

	if absf(dx) < 4.0:
		dir = 0.0

	velocity.x = move_toward(velocity.x, dir * speed_value, steer_accel * delta)


func _home_toward_player(speed_value: float, delta: float) -> void:
	var desired_dir: Vector2 = Vector2.RIGHT

	if _player != null and is_instance_valid(_player):
		desired_dir = (_player.global_position - global_position).normalized()

	if desired_dir.length() < 0.001:
		desired_dir = Vector2.RIGHT

	var desired_velocity: Vector2 = desired_dir * speed_value
	velocity = velocity.move_toward(desired_velocity, steer_accel * delta)


func _update_sprite_visuals(delta: float) -> void:
	if sprite == null:
		return

	var turn_weight: float = clampf(deg_to_rad(flight_turn_speed_deg) * delta, 0.0, 1.0)
	var base_angle: float = deg_to_rad(sprite_forward_angle_deg)

	# בזמן ג'ט/בייט הספרייט מסתובב באמת לזווית התנועה/המטרה
	if state == State.JET or state == State.BITE:
		var face_dir: Vector2 = velocity

		if face_dir.length() < 0.001 and _player != null and is_instance_valid(_player):
			face_dir = _player.global_position - global_position

		if face_dir.length() > 0.001:
			sprite.flip_h = false
			var target_angle: float = face_dir.angle() + base_angle
			sprite.rotation = lerp_angle(sprite.rotation, target_angle, turn_weight)
		return

	# על הקרקע נשארים ישרים, ורק מסתובבים ימינה/שמאלה
	sprite.rotation = lerp_angle(sprite.rotation, base_angle, turn_weight)

	if _player != null and is_instance_valid(_player):
		var dx: float = _player.global_position.x - global_position.x
		if absf(dx) > 0.01:
			sprite.flip_h = dx < 0.0


func _should_bite_first() -> bool:
	if _player == null or not is_instance_valid(_player):
		return true

	var dist: float = global_position.distance_to(_player.global_position)
	return dist <= bite_distance_threshold


func _touching_player_by_distance() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false

	var dist: float = global_position.distance_to(_player.global_position)
	return dist <= contact_radius


func _is_player_node(n: Node) -> bool:
	if n == null:
		return false

	return n.is_in_group(&"Player") or n.is_in_group(&"player") or n.name == "Player"


func _on_hit_area_area_entered(area: Area2D) -> void:
	if _dying:
		return

	if _is_player_node(area):
		_explode_and_free()


func _explode_and_free() -> void:
	if _dying:
		return

	_dying = true
	state = State.DEAD
	velocity = Vector2.ZERO

	col.disabled = true

	if hit_area != null:
		hit_area.monitoring = false
		var hit_col: CollisionShape2D = hit_area.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
		if hit_col != null:
			hit_col.disabled = true

	set_physics_process(false)

	if anim_death != StringName() and anim != null and anim.has_animation(String(anim_death)):
		_play_anim(anim_death, true)
		await anim.animation_finished

	queue_free()
