extends "res://Enemies/enemy.gd"

@export_group("Interceptor Tuning")
@export var speed_multiplier: float = 1.35
@export var tighter_turn_multiplier: float = 1.25
@export var close_engage_distance: float = 220.0

@export_group("Boost Pass")
@export var boost_speed: float = 340.0
@export var boost_duration: float = 0.45
@export var boost_cooldown: float = 1.8

var _boost_timer: float = 0.0
var _boost_cd: float = 0.0

func _ready() -> void:
	base_speed *= speed_multiplier
	min_speed *= speed_multiplier
	max_speed *= speed_multiplier
	turn_rate *= tighter_turn_multiplier
	engage_turn_rate *= tighter_turn_multiplier
	engage_distance = close_engage_distance
	fire_interval *= 0.8
	aim_spread_deg *= 0.75
	super._ready()
	add_to_group("interceptors")
	add_to_group("health_bar_target")

func _process(delta: float) -> void:
	if _boost_cd > 0.0:
		_boost_cd = maxf(_boost_cd - delta, 0.0)
	if _boost_timer > 0.0:
		_boost_timer = maxf(_boost_timer - delta, 0.0)
		_speed = maxf(_speed, boost_speed)
	else:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player != null and _boost_cd <= 0.0:
			var dist := global_position.distance_to(player.global_position)
			if dist < engage_distance * 0.9:
				_boost_timer = boost_duration
				_boost_cd = boost_cooldown
				_speed = maxf(_speed, boost_speed)
	super._process(delta)
