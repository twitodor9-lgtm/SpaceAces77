extends Control

func _on_character_pressed(id: int) -> void:
	GameState.selected_character_id = id
	GameState.score = 0
	GameState.stage_index = 1
	get_tree().change_scene_to_file(GameState.stage_scene_path())
