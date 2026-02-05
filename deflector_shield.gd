extends AbilityBase

func try_use() -> void:
	if not can_use():
		return
	# האפקט של הכוח
	show_label()
