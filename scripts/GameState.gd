extends Node

var selected_character_id: int = 0
var score: int = 0
var stage_index: int = 1  # 1-based (Stage01)

func stage_scene_path_for(idx: int) -> String:
	var i: int = maxi(idx, 1)
	var path := "res://Stages/Stage%02d.tscn" % i

	if ResourceLoader.exists(path):
		return path

	push_warning("Stage scene not found: %s" % path)
	return path

func stage_scene_path() -> String:
	return stage_scene_path_for(stage_index)

func next_stage() -> void:
	stage_index += 1
	get_tree().change_scene_to_file(stage_scene_path())
