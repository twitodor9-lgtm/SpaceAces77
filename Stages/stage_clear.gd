extends Control

const CHARACTER_SELECT_SCENE: String = "res://_context/Stages/CharacterSelect.tscn"

@onready var score_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScoreLabel
@onready var continue_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContinueButton

func _ready() -> void:
	if score_label != null:
		score_label.text = "SCORE: %d" % GameState.score
		print("STAGE CLEAR SCORE:", GameState.score)

	if continue_button != null and not continue_button.pressed.is_connected(_on_next_pressed):
		continue_button.pressed.connect(_on_next_pressed)

func _on_next_pressed() -> void:
	GameState.stage_index += 1

	if not ResourceLoader.exists(CHARACTER_SELECT_SCENE):
		push_error("CharacterSelect scene not found: " + CHARACTER_SELECT_SCENE)
		return

	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
