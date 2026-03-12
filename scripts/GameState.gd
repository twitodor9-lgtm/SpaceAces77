extends Node

var selected_character_id: int = 0
var score: int = 0
var stage_index: int = 1  # 1-based (Stage01)

func stage_scene_path_for(idx: int) -> String:
	var i: int = maxi(idx, 1)

	# סדר עדיפויות: קודם _context (כי אצלך Stage01 שם),
	# אחר כך Stages (2), אחר כך Stages.
	var templates: PackedStringArray = PackedStringArray([
		"res://_context/Stages/Stage%02d.tscn",
		"res://Stages (2)/Stage%02d.tscn",
		"res://Stages/Stage%02d.tscn",
	])

	for tpl: String in templates:
		var p: String = tpl % i
		if ResourceLoader.exists(p):
			return p

	# fallback (כדי שלא יחזור ריק)
	return String(templates[0]) % i

func stage_scene_path() -> String:
	return stage_scene_path_for(stage_index)

func next_stage() -> void:
	stage_index += 1
	get_tree().change_scene_to_file(stage_scene_path())
