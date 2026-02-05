extends AbilityBase

@export var mult: float = 1.8
@export var duration: float = 1.6

func try_use() -> void:
	if not can_use():
		return
	if _player == null:
		return
	if not _player.has_method("apply_turbo"):
		return

	_player.apply_turbo(mult, duration)
	show_label()
