extends Control

@onready var score_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScoreLabel") as Label
@onready var next_button: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton") as Button

func _ready() -> void:
	if score_label != null:
		score_label.text = "SCORE: %d" % GameState.score

	if next_button != null:
		if not next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.connect(_on_next_pressed)

	print("stage_clear_label=", score_label, " next_button=", next_button)

func _on_next_pressed() -> void:
	GameState.stage_index = 1

	var char_select_path := "res://Stages/CharacterSelect.tscn"
	if not ResourceLoader.exists(char_select_path):
		char_select_path = "res://_context/Stages/CharacterSelect.tscn"

	if not ResourceLoader.exists(char_select_path):
		push_error("CharacterSelect scene not found in res://Stages or res://_context/Stages")
		return

	get_tree().change_scene_to_file(char_select_path)
