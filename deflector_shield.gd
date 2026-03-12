extends AbilityBase

@export var duration: float = 2.5

func try_use() -> void:
	if not can_use():
		return
	if _player == null:
		return

	# מפעיל מגן + ריקושטים
	if _player.has_method("enable_deflector_shield"):
		_player.enable_deflector_shield(duration)

	# הגנה מוחלטת גם מפגיעות אחרות
	if _player.has_method("set_invulnerable"):
		_player.set_invulnerable(duration)

	show_label()
