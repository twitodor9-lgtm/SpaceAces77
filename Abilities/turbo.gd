extends Node2D

@export var mult: float = 1.8
@export var duration: float = 1.6
@export var cooldown: float = 3.5

var _next_ready_ms: int = 0
@onready var _player: Node = _resolve_player()

func _resolve_player() -> Node:
	# Turbo נמצא תחת Player/Abilities/Turbo => Player הוא parent של Abilities
	if get_parent() and get_parent().get_parent():
		return get_parent().get_parent()
	# fallback
	return get_tree().get_first_node_in_group("player")

func try_use() -> void:
	var now := Time.get_ticks_msec()
	if now < _next_ready_ms:
		return
	_next_ready_ms = now + int(cooldown * 1000.0)

	if _player == null:
		print("Turbo: player not found")
		return
	if not _player.has_method("apply_turbo"):
		print("Turbo: player has no apply_turbo()")
		return

	print("Turbo: APPLY")
	_player.apply_turbo(mult, duration)
