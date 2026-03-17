extends RefCounted
class_name BackgroundCatalog

static func _resource_path_for_id(id: String) -> String:
	match id:
		"neutral_arena":
			return "res://backgrounds/neutral_arena.tres"
		"stage01_clean":
			return "res://backgrounds/stage01_clean.tres"
		"stage02_worm":
			return "res://backgrounds/stage02_worm.tres"
		"stage03_low_cover":
			return "res://backgrounds/stage03_low_cover.tres"
		_:
			return ""

static func get_preset(id: String) -> Dictionary:
	var path := _resource_path_for_id(id)
	if path == "":
		return {}

	var preset := load(path) as BackgroundPreset
	if preset == null:
		return {}

	return {
		"far": preset.far_texture.resource_path if preset.far_texture != null else "",
		"near": preset.near_texture.resource_path if preset.near_texture != null else "",
		"far_scale": preset.far_scale,
		"near_scale": preset.near_scale,
		"far_pos": preset.far_position,
		"near_pos": preset.near_position,
		"drift_speed": preset.drift_speed,
	}

static func has_preset(id: String) -> bool:
	return _resource_path_for_id(id) != ""

static func list_ids() -> Array:
	return ["neutral_arena", "stage01_clean", "stage02_worm", "stage03_low_cover"]
