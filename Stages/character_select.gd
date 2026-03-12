extends Control

@export var max_stage: int = 4

@onready var selected_label: Label = $SelectedLabel
@onready var stage_option: OptionButton = $VBoxContainer/StageOption
@onready var start_button: Button = $START
@onready var exit_button: Button = $ExitButton

var _selected_id: int = -1      # 0..5
var _selected_stage: int = 1    # 1..N (אמיתי, לפי scenes קיימים)

func _ready() -> void:
	# בדיקות כדי שלא יקרוס
	if selected_label == null or stage_option == null or start_button == null or exit_button == null:
		push_error("CharacterSelect: Missing UI nodes. Expected: $SelectedLabel, $VBoxContainer/StageOption, $START, $ExitButton")
		return

	# כפתורים כלליים
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# כפתורי דמויות (CharButton1..CharButton6) – בכל מקום שהם נמצאים בעץ
	var char_buttons: Array[Button] = _find_char_buttons()
	if char_buttons.size() == 0:
		push_error("CharacterSelect: No CharButton buttons found. Names must be CharButton1..CharButton6.")
		return

	for b: Button in char_buttons:
		var name_str: String = String(b.name)                 # "CharButton1"
		var n: int = int(name_str.replace("CharButton", ""))  # 1..6
		var id: int = clampi(n - 1, 0, 5)                     # 0..5
		b.pressed.connect(_on_char_pressed.bind(id))

	# רשימת שלבים (רק כאלה שקיימים באמת)
	_fill_stage_option()

	# ברירת מחדל לפי GameState
	if stage_option.item_count > 0:
		_selected_stage = clampi(GameState.stage_index, 1, stage_option.item_count)
		stage_option.select(_selected_stage - 1)
	else:
		_selected_stage = 1

	stage_option.item_selected.connect(_on_stage_selected)

	_update_ui()

func _fill_stage_option() -> void:
	stage_option.clear()

	for s: int in range(1, max_stage + 1):
		var path := GameState.stage_scene_path_for(s)
		if ResourceLoader.exists(path):
			stage_option.add_item("Stage %d" % s, s)
		else:
			# אם Stage03 לא קיים, לא נציג גם Stage04 וכו' (רציף)
			break

	print("CharacterSelect: StageOption items:", stage_option.item_count)

func _find_char_buttons() -> Array[Button]:
	var out: Array[Button] = []
	var stack: Array[Node] = [self]

	while stack.size() > 0:
		var n: Node = stack.pop_back()

		if n is Button:
			var b: Button = n as Button
			if String(b.name).begins_with("CharButton"):
				out.append(b)

		for c: Node in n.get_children():
			stack.append(c)

	return out

func _on_char_pressed(id: int) -> void:
	_selected_id = id
	_update_ui()

func _on_stage_selected(idx: int) -> void:
	# idx הוא אינדקס; אנחנו רוצים את ה-ID ששמרנו (מספר השלב)
	_selected_stage = stage_option.get_item_id(idx)
	GameState.stage_index = _selected_stage
	print("CharacterSelect: Selected stage:", _selected_stage)
	# חשוב: לא משנים סצנה כאן. רק START מעביר לשלב.

func _update_ui() -> void:
	if _selected_id < 0:
		selected_label.text = "Selected: none"
	else:
		selected_label.text = "Selected: Hero %d" % (_selected_id + 1)

func _on_start_pressed() -> void:
	if _selected_id < 0:
		return

	GameState.selected_character_id = _selected_id
	GameState.score = 0
	GameState.stage_index = _selected_stage

	var path: String = GameState.stage_scene_path()
	print("CharacterSelect: START -> loading:", path)

	if not ResourceLoader.exists(path):
		push_error("Stage scene not found: " + path)
		return

	get_tree().change_scene_to_file(path)

func _on_exit_pressed() -> void:
	get_tree().quit()
