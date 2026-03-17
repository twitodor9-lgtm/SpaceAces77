extends RefCounted
class_name BackgroundCatalog

const PRESETS := {
	"neutral_arena": _from_resource("res://backgrounds/neutral_arena.tres"),
	"stage01_clean": _from_resource("res://backgrounds/stage01_clean.tres"),
	"stage02_worm": _from_resource("res://backgrounds/stage02_worm.tres"),
	"stage03_low_cover": _from_resource("res://backgrounds/stage03_low_cover.tres"),
}

static func _from_resource(path: String) -> Dictionary:
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

static func get_preset(id: String) -> Dictionary:
	return PRESETS.get(id, {}).duplicate(true)

static func has_preset(id: String) -> bool:
	return PRESETS.has(id)

static func list_ids() -> Array:
	return PRESETS.keys()
