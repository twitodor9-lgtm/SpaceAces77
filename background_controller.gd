@tool
extends Node2D

@export var drift_speed: float = 0.0

# זה רק לתצוגה בעורך
@export var preview_stage_index: int = 0

@onready var far_sprite: Sprite2D  = $ParallaxBackground/FarLayer/FarSprite
@onready var near_sprite: Sprite2D = $ParallaxBackground/NearLayer/NearSprite
@onready var pb: ParallaxBackground = $ParallaxBackground

func _ready() -> void:
	_apply()

func _process(delta: float) -> void:
	if drift_speed != 0.0 and pb:
		pb.scroll_offset.x += drift_speed * delta

func _notification(what):
	# כל פעם שמשהו משתנה בעורך
	if Engine.is_editor_hint():
		_apply()

func _apply() -> void:
	if not far_sprite or not near_sprite:
		return

	# בעורך: תציג לפי preview_stage_index
	if Engine.is_editor_hint():
		var i := clampi(preview_stage_index, 0, GameBalance.STAGES.size() - 1)
		var rules: Dictionary = GameBalance.STAGES[i]
		_set_textures_from_rules(rules)
		return

	# במשחק: תציג לפי השלב האמיתי
	_set_textures_from_rules(GameBalance.rules())

func _set_textures_from_rules(rules: Dictionary) -> void:
	var far_path := str(rules.get("bg_far", ""))
	var near_path := str(rules.get("bg_near", ""))

	if far_path != "":
		far_sprite.texture = load(far_path)
	if near_path != "":
		near_sprite.texture = load(near_path)
