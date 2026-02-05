extends Node2D
class_name AbilityBase

@export var label_text: String = ""
@export var cooldown: float = 0.0

var _next_ready_ms: int = 0
@onready var _player: Node = get_parent().get_parent()

func can_use() -> bool:
	var now := Time.get_ticks_msec()
	if now < _next_ready_ms:
		return false
	_next_ready_ms = now + int(cooldown * 1000.0)
	return true

func show_label() -> void:
	if _player and _player.has_method("show_ability_text") and label_text != "":
		_player.show_ability_text(label_text)
