extends CharacterBody2D

signal lock_started(target: Node)
signal lock_ended(target: Node)
signal boss_died
@export var self_missile_hit_fx_scale: float = 1.8
@export var max_hp: int = 300
@export var move_speed: float = 120.0
@export var gravity_strength: float = 900.0
@export var clamp_to_stage_x: bool = true
@export var stage_left_x: float = 120.0
@export var stage_right_x: float = 1160.0
@export var accel: float = 140.0
@export var decel: float = 220.0
@export var score_value: int = 500
@export var sprite_faces_right: bool = true

@export var debug_attacks: bool = false
@export var bullet_speed_override: float = 0.0

@export var lock_duration: float = 0.75
@export var missiles_per_burst: int = 5
@export var missile_gap: float = 0.12
@export var overheat_duration: float = 1.25

@export var slam_range: float = 240.0
@export var slam_damage: int = 1
@export var slam_windup: float = 0.35
@export var slam_cooldown: float = 0.25

@export var self_missile_damage_scale: float = 1.0
@export var self_missile_bypass_overheat: bool = true

@export var hit_explosion_enabled: bool = true
@export var hit_explosion_pieces: int = 10
@export var hit_explosion_scale: float = 1.0
@export var hit_explosion_duration: float = 0.18

@export var show_debug_hp_label: bool = true

@export var bullet_scene: PackedScene
@export var fire_cooldown: float = 0.25
@export var missile_scene: PackedScene
@export var songbird_scene: PackedScene
@export var songbird_count: int = 14
@export var songbird_gap: float = 0.04
@export var songbird_chance: float = 0.35
@export var songbird_spread_deg: float = 38.0

@export var Player_group: StringName = &"Player"

@onready var anim: AnimatedSprite2D = get_node_or_null("Anim") as AnimatedSprite2D
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var attack_timer: Timer = $AttackTimer

enum State { IDLE, WALK, LOCK, SHOOT, SLAM, OVERHEAT, DEAD }
var state: int = -1

var hp: int
var Player: Node2D
var _fire_cd_left: float = 0.0
var busy: bool = false
var vulnerable: bool = false
var _face_left: bool = false

var _visual: CanvasItem = null
var _visual_node2d: Node2D = null
var _hp_label: Label = null

func _ready() -> void:
	hp = max_hp
	add_to_group("boss")

	_cache_visual_nodes()
	_ensure_hp_label()
	_update_hp_label()

	Player = _find_Player()

	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	_set_state(State.IDLE, true)
	_schedule_next_attack()

	if debug_attacks:
		print("[WardenGiant READY] bullet_scene=", bullet_scene,
			" missile_scene=", missile_scene,
			" songbird_scene=", songbird_scene,
			" Player_group=", Player_group,
			" fire_cd=", fire_cooldown,
			" bullet_speed_override=", bullet_speed_override,
			" anim=", anim,
			" anim_player=", anim_player,
			" sprite_2d=", sprite_2d)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _fire_cd_left > 0.0:
		_fire_cd_left -= delta

	if Player == null or not is_instance_valid(Player):
		Player = _find_Player()

	if not is_on_floor():
		velocity.y += gravity_strength * delta
	else:
		velocity.y = 0.0

	if busy or Player == null:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	else:
		var dir: float = signf(Player.global_position.x - global_position.x)
		var target_vx: float = dir * move_speed
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)

	move_and_slide()
	if clamp_to_stage_x:
		global_position.x = clampf(global_position.x, stage_left_x, stage_right_x)
	if not busy:
		if absf(velocity.x) > 1.0:
			_set_state(State.WALK)
		else:
			_set_state(State.IDLE)

	if Player != null and is_instance_valid(Player):
		var dx: float = Player.global_position.x - global_position.x
		if absf(dx) > 8.0:
			_face_left = dx < 0.0

	var want_flip_h: bool = _face_left
	if not sprite_faces_right:
		want_flip_h = not want_flip_h
	_set_visual_flip(want_flip_h)

	if anim != null:
		var speed_x: float = absf(velocity.x)
		if state == State.WALK:
			anim.speed_scale = clampf(speed_x / 120.0, 0.35, 1.1)
		else:
			anim.speed_scale = 1.0

func _cache_visual_nodes() -> void:
	if anim == null:
		anim = _find_first_animated_sprite(self)
	if sprite_2d == null:
		sprite_2d = _find_named_or_first_sprite(self)
	if anim_player == null:
		anim_player = _find_named_or_first_animation_player(self)

	if anim != null:
		_visual = anim
		_visual_node2d = anim
	elif sprite_2d != null:
		_visual = sprite_2d
		_visual_node2d = sprite_2d
	else:
		_visual = null
		_visual_node2d = null

func _ensure_hp_label() -> void:
	if not show_debug_hp_label:
		return

	var existing: Node = get_node_or_null("HPLabel")
	if existing is Label:
		_hp_label = existing as Label
	else:
		_hp_label = Label.new()
		_hp_label.name = "HPLabel"
		add_child(_hp_label)

	_hp_label.position = Vector2(-40.0, -120.0)
	_hp_label.z_index = 100
	_hp_label.visible = true
	_hp_label.modulate = Color(1.0, 0.95, 0.55, 1.0)

func _update_hp_label() -> void:
	if _hp_label == null:
		return
	_hp_label.text = "HP: %d / %d" % [hp, max_hp]
	_hp_label.visible = show_debug_hp_label

func get_health_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)

func _find_first_animated_sprite(root: Node) -> AnimatedSprite2D:
	for child in root.get_children():
		if child is AnimatedSprite2D:
			return child as AnimatedSprite2D
		var found: AnimatedSprite2D = _find_first_animated_sprite(child)
		if found != null:
			return found
	return null

func _find_named_or_first_sprite(root: Node) -> Sprite2D:
	var named: Node = root.find_child("Sprite2D", true, false)
	if named is Sprite2D:
		return named as Sprite2D

	for child in root.get_children():
		if child is Sprite2D:
			return child as Sprite2D
		var found: Sprite2D = _find_named_or_first_sprite(child)
		if found != null:
			return found
	return null

func _find_named_or_first_animation_player(root: Node) -> AnimationPlayer:
	var named: Node = root.find_child("AnimationPlayer", true, false)
	if named is AnimationPlayer:
		return named as AnimationPlayer

	for child in root.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var found: AnimationPlayer = _find_named_or_first_animation_player(child)
		if found != null:
			return found
	return null

func _set_visual_flip(flip_h: bool) -> void:
	if anim != null:
		anim.flip_h = flip_h
	if sprite_2d != null:
		sprite_2d.flip_h = flip_h

func _find_Player() -> Node2D:
	var arr: Array = get_tree().get_nodes_in_group(Player_group)
	if arr.size() > 0 and arr[0] is Node2D:
		return arr[0] as Node2D

	arr = get_tree().get_nodes_in_group(&"player")
	if arr.size() > 0 and arr[0] is Node2D:
		return arr[0] as Node2D

	var n: Node = get_tree().current_scene
	if n != null:
		var p: Node = n.find_child("Player", true, false)
		if p != null and p is Node2D:
			return p as Node2D

	return null

func _schedule_next_attack() -> void:
	if state == State.DEAD:
		return
	attack_timer.stop()
	attack_timer.wait_time = randf_range(0.9, 1.5)
	attack_timer.start()
	if debug_attacks:
		print("[ATTACK SCHEDULE] wait_time=", attack_timer.wait_time, " stopped?=", attack_timer.is_stopped())

func _on_attack_timer_timeout() -> void:
	if busy or Player == null:
		_schedule_next_attack()
		return

	var dist: float = global_position.distance_to(Player.global_position)

	if debug_attacks:
		print("[ATTACK TICK] busy=", busy,
			" player=", Player,
			" dist=", dist,
			" slam_range=", slam_range,
			" missile_scene=", missile_scene,
			" bullet_scene=", bullet_scene,
			" songbird_scene=", songbird_scene)

	if dist <= slam_range and randf() < 0.50:
		if debug_attacks:
			print("[ATTACK] SLAM")
		_do_slam()
	else:
		if songbird_scene != null and randf() < songbird_chance:
			if debug_attacks:
				print("[ATTACK] LOCK->SONGBIRDS")
			_do_lock_then_songbirds()
		else:
			if debug_attacks:
				print("[ATTACK] LOCK->MISSILES/BULLETS")
			_do_lock_then_missiles()

func _do_lock_then_songbirds() -> void:
	busy = true
	_set_state(State.LOCK, true)
	lock_started.emit(Player)

	await get_tree().create_timer(lock_duration).timeout

	_set_state(State.SHOOT, true)
	await _fire_songbirds()

	lock_ended.emit(Player)

	await _enter_overheat()
	busy = false
	_set_state(State.IDLE, true)
	_schedule_next_attack()

func _fire_songbirds() -> void:
	if songbird_scene == null or Player == null:
		return

	var base_dir: Vector2 = (Player.global_position - muzzle.global_position).normalized()
	if base_dir.length() < 0.001:
		base_dir = Vector2.RIGHT

	var spread_rad: float = deg_to_rad(songbird_spread_deg)

	for i in range(songbird_count):
		var m: Node = songbird_scene.instantiate()

		if m.has_method("set_shooter"):
			m.call("set_shooter", self)
		if m.has_method("set_target"):
			m.call("set_target", Player)

		get_tree().current_scene.add_child(m)

		if m is Node2D:
			(m as Node2D).global_position = muzzle.global_position

		var t: float = 0.0
		if songbird_count > 1:
			t = float(i) / float(songbird_count - 1)
		var ang: float = lerpf(-spread_rad * 0.5, spread_rad * 0.5, t)
		var dir: Vector2 = base_dir.rotated(ang)

		if m.has_method("set_initial_direction"):
			m.call("set_initial_direction", dir)

		if debug_attacks:
			print("[SONGBIRD] spawned #", i, " node=", m, " pos=", (m as Node2D).global_position if (m is Node2D) else "n/a")

		await get_tree().create_timer(songbird_gap).timeout

func _do_lock_then_missiles() -> void:
	busy = true
	_set_state(State.LOCK, true)
	lock_started.emit(Player)

	for i in range(missiles_per_burst):
		_fire_bullet()
		await get_tree().create_timer(missile_gap).timeout

	await get_tree().create_timer(lock_duration).timeout

	_set_state(State.SHOOT, true)
	await _fire_missiles()

	lock_ended.emit(Player)

	await _enter_overheat()
	busy = false
	_set_state(State.IDLE, true)
	_schedule_next_attack()

func _fire_missiles() -> void:
	if missile_scene == null or Player == null:
		if debug_attacks:
			print("[MISSILES] ABORT: missile_scene=", missile_scene, " Player=", Player)
		return

	if debug_attacks:
		print("[MISSILES] spawning count=", missiles_per_burst, " gap=", missile_gap)

	for i in range(missiles_per_burst):
		var m: Node = missile_scene.instantiate()

		if m.has_method("set_shooter"):
			m.call("set_shooter", self)
		if m.has_method("set_target"):
			m.call("set_target", Player)

		get_tree().current_scene.add_child(m)

		if m is Node2D:
			(m as Node2D).global_position = muzzle.global_position

		if debug_attacks:
			print("[MISSILES] spawned #", i, " node=", m, " pos=", (m as Node2D).global_position if (m is Node2D) else "n/a")

		await get_tree().create_timer(missile_gap).timeout

func _do_slam() -> void:
	busy = true
	_set_state(State.SLAM, true)

	await get_tree().create_timer(slam_windup).timeout

	if Player != null and is_instance_valid(Player):
		if global_position.distance_to(Player.global_position) <= slam_range:
			_damage_Player(Player, slam_damage)

	await get_tree().create_timer(slam_cooldown).timeout
	await _enter_overheat()

	busy = false
	_set_state(State.IDLE, true)
	_schedule_next_attack()

func _enter_overheat() -> void:
	_set_state(State.OVERHEAT, true)
	vulnerable = true
	await get_tree().create_timer(overheat_duration).timeout
	vulnerable = false
	_set_state(State.IDLE, true)

func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	if amount <= 0:
		return
	if not vulnerable:
		return

	hp -= amount
	_update_hp_label()
	_play_hit_explosion()

	if hp <= 0:
		_die()

func apply_homing_missile_hit(amount: int) -> void:
	if state == State.DEAD:
		return
	if amount <= 0:
		return
	if (not vulnerable) and (not self_missile_bypass_overheat):
		return

	var final_damage: int = maxi(1, int(round(float(amount) * self_missile_damage_scale)))
	hp -= final_damage
	_update_hp_label()
	_play_hit_explosion(self_missile_hit_fx_scale)

	if debug_attacks:
		print("[BOSS FRIENDLY FIRE] dmg=", final_damage, " hp=", hp, "/", max_hp, " vulnerable=", vulnerable)

	if hp <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	busy = true
	vulnerable = false
	_play_by_candidates(_anim_candidates_for_state(State.OVERHEAT), true)
	boss_died.emit()
	_award_score()
	queue_free()

func _play_hit_explosion(scale_mult: float = 1.0) -> void:
	if not hit_explosion_enabled:
		return

	var fx_pos: Vector2 = _get_hit_fx_position()
	_spawn_hit_explosion(fx_pos, scale_mult)
	_flash_hit_sprite()

func _get_hit_fx_position() -> Vector2:
	if _visual_node2d != null:
		return _visual_node2d.global_position + Vector2(
			randf_range(-22.0, 22.0),
			randf_range(-18.0, 18.0)
		)
	return global_position + Vector2(
		randf_range(-22.0, 22.0),
		randf_range(-18.0, 18.0)
	)

func _flash_hit_sprite() -> void:
	if _visual == null:
		return

	_visual.modulate = Color(1.0, 0.82, 0.72, 1.0)

	var tw: Tween = get_tree().create_tween()
	tw.tween_property(_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10)

func _spawn_hit_explosion(world_pos: Vector2, scale_mult: float = 1.0) -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return

	var burst_root: Node2D = Node2D.new()
	burst_root.global_position = world_pos
	root.add_child(burst_root)

	var flash: Polygon2D = Polygon2D.new()
	var flash_r: float = 12.0 * hit_explosion_scale * scale_mult
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -flash_r),
		Vector2(flash_r * 0.8, 0.0),
		Vector2(0.0, flash_r),
		Vector2(-flash_r * 0.8, 0.0)
	])
	flash.color = Color(1.0, 0.95, 0.70, 1.0)
	burst_root.add_child(flash)

	var flash_tw: Tween = get_tree().create_tween()
	flash_tw.set_parallel(true)
	flash_tw.tween_property(flash, "scale", Vector2(2.2, 2.2), hit_explosion_duration * 0.55)
	flash_tw.tween_property(flash, "modulate:a", 0.0, hit_explosion_duration * 0.55)

	for i in range(hit_explosion_pieces):
		var shard: Polygon2D = Polygon2D.new()
		var size: float = randf_range(5.0, 10.0) * hit_explosion_scale * scale_mult

		shard.polygon = PackedVector2Array([
			Vector2(-size * 0.7, -size * 0.35),
			Vector2(size * 0.85, 0.0),
			Vector2(-size * 0.7, size * 0.35)
		])

		if randf() < 0.5:
			shard.color = Color(1.0, 0.82, 0.22, 1.0)
		else:
			shard.color = Color(1.0, 0.45, 0.12, 1.0)

		shard.rotation = randf_range(0.0, TAU)
		burst_root.add_child(shard)

		var dir: Vector2 = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
		var dist: float = randf_range(16.0, 42.0) * hit_explosion_scale * scale_mult
		var rot_end: float = shard.rotation + randf_range(-2.4, 2.4)

		var shard_tw: Tween = get_tree().create_tween()
		shard_tw.set_parallel(true)
		shard_tw.tween_property(shard, "position", dir * dist, hit_explosion_duration)
		shard_tw.tween_property(shard, "scale", Vector2(0.2, 0.2), hit_explosion_duration)
		shard_tw.tween_property(shard, "modulate:a", 0.0, hit_explosion_duration)
		shard_tw.tween_property(shard, "rotation", rot_end, hit_explosion_duration)

	var cleanup_tw: Tween = get_tree().create_tween()
	cleanup_tw.tween_interval(hit_explosion_duration + 0.06)
	cleanup_tw.tween_callback(Callable(burst_root, "queue_free"))

func _damage_Player(p: Node, amount: int) -> void:
	if p.has_method("take_damage"):
		p.call("take_damage", amount)
	elif p.has_method("hurt"):
		p.call("hurt", amount)

func _anim_candidates_for_state(s: int) -> Array[String]:
	match s:
		State.IDLE:
			return ["idle", "idile", "stand", "chill"]
		State.WALK:
			return ["walk", "run", "move"]
		State.LOCK:
			return ["lock", "aim", "charge"]
		State.SHOOT:
			return ["shoot", "fire", "attack"]
		State.SLAM:
			return ["slam", "stomp", "smash", "attack"]
		State.OVERHEAT:
			return ["overheat", "over_heat", "hot", "burn", "hurt"]
		_:
			return []

func _normalize_anim_key(s: String) -> String:
	return s.to_lower().replace("_", "").replace("-", "").replace(" ", "")

func _find_matching_animation_name_in_list(names: PackedStringArray, candidates: Array[String]) -> String:
	for candidate in candidates:
		if candidate in names:
			return candidate

	for candidate in candidates:
		var want: String = _normalize_anim_key(candidate)
		for n in names:
			var n_str: String = String(n)
			if _normalize_anim_key(n_str) == want:
				return n_str

	for candidate in candidates:
		var want_contains: String = _normalize_anim_key(candidate)
		for n in names:
			var n_str_2: String = String(n)
			var norm_name: String = _normalize_anim_key(n_str_2)
			if norm_name.contains(want_contains) or want_contains.contains(norm_name):
				return n_str_2

	return ""

func _resolve_anim_name(candidates: Array[String]) -> String:
	if anim != null and anim.sprite_frames != null:
		var anim_names: PackedStringArray = anim.sprite_frames.get_animation_names()
		var found_sprite: String = _find_matching_animation_name_in_list(anim_names, candidates)
		if found_sprite != "":
			return found_sprite

	if anim_player != null:
		var player_names: PackedStringArray = anim_player.get_animation_list()
		var found_player: String = _find_matching_animation_name_in_list(player_names, candidates)
		if found_player != "":
			return found_player

	return ""

func _is_current_anim(resolved: String) -> bool:
	if resolved == "":
		return false

	if anim != null:
		return String(anim.animation) == resolved and anim.is_playing()

	if anim_player != null:
		return String(anim_player.current_animation) == resolved and anim_player.is_playing()

	return false

func _play_by_candidates(candidates: Array[String], restart: bool = false) -> void:
	var resolved: String = _resolve_anim_name(candidates)

	if resolved == "":
		if debug_attacks:
			print("Missing animation for candidates: ", candidates)
		return

	if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation(resolved):
		if restart or String(anim.animation) != resolved or not anim.is_playing():
			anim.play(resolved)
			anim.frame = 0
			anim.frame_progress = 0.0
			if debug_attacks:
				print("[ANIM PLAY] sprite resolved=", resolved)
		return

	if anim_player != null and anim_player.has_animation(resolved):
		if restart or String(anim_player.current_animation) != resolved or not anim_player.is_playing():
			anim_player.stop()
			anim_player.play(resolved)
			if debug_attacks:
				print("[ANIM PLAY] player resolved=", resolved)
		return

func _set_state(s: State, force_restart: bool = false) -> void:
	if state == State.DEAD and s != State.DEAD:
		return

	var changed: bool = state != s
	state = s

	var candidates: Array[String] = _anim_candidates_for_state(s)
	if candidates.is_empty():
		return

	if changed or force_restart:
		_play_by_candidates(candidates, true)
	elif not _is_current_anim(_resolve_anim_name(candidates)):
		_play_by_candidates(candidates, false)

func _fire_bullet() -> void:
	if Player == null or not is_instance_valid(Player):
		if debug_attacks:
			print("[BULLET] ABORT: no Player")
		return
	if _fire_cd_left > 0.0:
		if debug_attacks:
			print("[BULLET] ABORT: cooldown=", _fire_cd_left)
		return

	var root: Node = get_tree().current_scene
	if root == null:
		if debug_attacks:
			print("[BULLET] ABORT: no current_scene")
		return

	var proj: Node = null
	var use_missile_fallback: bool = false

	if bullet_scene == null:
		use_missile_fallback = true
	else:
		proj = bullet_scene.instantiate()
		if not (proj.has_method("setup")
			or proj.has_method("set_direction")
			or proj.has_method("set_velocity")
			or proj.has_method("set_dir")
			or proj.has_method("set_target")
			or proj.has_method("start")):
			use_missile_fallback = true

	if use_missile_fallback:
		if missile_scene == null:
			if debug_attacks:
				print("[BULLET] ABORT: no bullet_scene + no missile_scene fallback")
			return
		proj = missile_scene.instantiate()

	if proj.has_method("set_shooter"):
		proj.call("set_shooter", self)
	if proj.has_method("set_target"):
		proj.call("set_target", Player)

	root.add_child(proj)

	if proj is Node2D:
		(proj as Node2D).global_position = muzzle.global_position

	var dir: Vector2 = (Player.global_position - muzzle.global_position).normalized()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT

	if proj.has_method("setup"):
		var spd: float = bullet_speed_override if bullet_speed_override > 0.0 else 420.0
		proj.call("setup", dir, spd)
		if debug_attacks:
			print("[BULLET] setup dir=", dir, " spd=", spd, " proj=", proj)
	else:
		if proj.has_method("set_direction"):
			proj.call("set_direction", dir)
		elif proj.has_method("set_dir"):
			proj.call("set_dir", dir)
		elif proj.has_method("set_initial_direction"):
			proj.call("set_initial_direction", dir)

		if debug_attacks:
			print("[BULLET] dir-set dir=", dir, " proj=", proj)

	if proj.has_method("start"):
		proj.call("start")

	_fire_cd_left = fire_cooldown
func _award_score() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("add_score"):
		scene.call("add_score", score_value)
