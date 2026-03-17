@tool
extends Node2D

@export var drift_speed: float = 0.0
@export var preview_background_id: String = ""

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

	# בעורך: אפשר לבחור preset ישירות, או לפי stage index
	if Engine.is_editor_hint():
		if preview_background_id != "":
			apply_background_id(preview_background_id)
			return
		var i := clampi(preview_stage_index, 0, GameBalance.STAGES.size() - 1)
		var rules: Dictionary = GameBalance.STAGES[i]
		_apply_rules(rules)
		return

	# במשחק: תציג לפי השלב האמיתי
	_apply_rules(GameBalance.rules())

func apply_background_id(background_id: String) -> void:
	var preset := BackgroundCatalog.get_preset(background_id)
	if preset.is_empty():
		push_warning("Unknown background preset: %s" % background_id)
		return
	_apply_preset(preset)

func _apply_rules(rules: Dictionary) -> void:
	var background_id := str(rules.get("background_id", ""))
	if background_id != "":
		apply_background_id(background_id)
		return
	_set_textures_from_rules(rules)

func _apply_preset(preset: Dictionary) -> void:
	var far_path := str(preset.get("far", ""))
	var near_path := str(preset.get("near", ""))

	if far_path != "":
		far_sprite.texture = load(far_path)
		far_sprite.visible = true
	if near_path != "":
		near_sprite.texture = load(near_path)
		near_sprite.visible = true

	far_sprite.position = preset.get("far_pos", far_sprite.position)
	near_sprite.position = preset.get("near_pos", near_sprite.position)
	far_sprite.scale = preset.get("far_scale", far_sprite.scale)
	near_sprite.scale = preset.get("near_scale", near_sprite.scale)
	drift_speed = float(preset.get("drift_speed", drift_speed))

func _set_textures_from_rules(rules: Dictionary) -> void:
	var far_path := str(rules.get("bg_far", ""))
	var near_path := str(rules.get("bg_near", ""))

	if far_path != "":
		far_sprite.texture = load(far_path)
		far_sprite.visible = true
	if near_path != "":
		near_sprite.texture = load(near_path)
		near_sprite.visible = true
