extends RefCounted
class_name BackgroundCatalog

const PRESETS := {
	"neutral_arena": {
		"far": "res://PNGStarJets/BAרקעים/A1/1.pngA2.png",
		"near": "res://PNGStarJets/BAרקעים/A1/1.pngA.png",
		"far_scale": Vector2(0.9411765, 0.7257683),
		"near_scale": Vector2(0.9426471, 1.2228739),
		"far_pos": Vector2(0, -6.000002),
		"near_pos": Vector2(0, 301),
		"drift_speed": 0.0,
	},
	"stage01_clean": {
		"far": "res://PNGStarJets/BAרקעים/A1/1.pngA2.png",
		"near": "res://PNGStarJets/BAרקעים/A1/1.pngA.png",
		"far_scale": Vector2(0.9411765, 0.7257683),
		"near_scale": Vector2(0.9426471, 1.2228739),
		"far_pos": Vector2(0, -6.000002),
		"near_pos": Vector2(0, 301),
		"drift_speed": 0.0,
	},
	"stage02_worm": {
		"far": "res://PNGStarJets/BAרקעים/C1_lunar_1280x720.png",
		"near": "res://PNGStarJets/BAרקעים/C2_lunar_1280x720.png",
		"far_scale": Vector2.ONE,
		"near_scale": Vector2.ONE,
		"far_pos": Vector2.ZERO,
		"near_pos": Vector2.ZERO,
		"drift_speed": 0.0,
	},
	"stage03_low_cover": {
		"far": "res://PNGStarJets/BAרקעים/C2_lunar_1280x720.png",
		"near": "res://PNGStarJets/BAרקעים/C3_lunar_1280x720.png",
		"far_scale": Vector2.ONE,
		"near_scale": Vector2.ONE,
		"far_pos": Vector2.ZERO,
		"near_pos": Vector2.ZERO,
		"drift_speed": 0.0,
	},
}

static func get_preset(id: String) -> Dictionary:
	return PRESETS.get(id, {}).duplicate(true)

static func has_preset(id: String) -> bool:
	return PRESETS.has(id)

static func list_ids() -> Array:
	return PRESETS.keys()
