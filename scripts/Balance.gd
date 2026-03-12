extends Node


enum Difficulty { EASY, NORMAL, HARD }

# אפשר לשנות מכל מקום: Balance.difficulty = Balance.Difficulty.HARD
var difficulty: Difficulty = Difficulty.NORMAL

# עדכן את זה כשאתה מחליף "מסך/שלב"
var stage_index: int = 0

const DIFF := {
	Difficulty.EASY:   {"enemy_hp": 0.75, "enemy_damage": 0.8, "spawn_rate": 0.85, "player_damage_taken": 0.85},
	Difficulty.NORMAL: {"enemy_hp": 1.0,  "enemy_damage": 1.0, "spawn_rate": 1.0,  "player_damage_taken": 1.0},
	Difficulty.HARD:   {"enemy_hp": 1.25, "enemy_damage": 1.2, "spawn_rate": 1.15, "player_damage_taken": 1.15},
}

# כל מסך מחליט: תולעת? מחבוא נמוך? סיכויים? קווי גובה?
const STAGES := [
	{
		"name": "S1 - Clean",
		"worm_enabled": true,
		"low_cover_enabled": true,
		"low_line_ratio": 0.18,
	},
	{
		"name": "S2 - Worm",
		"worm_enabled": true,
		"worm_dip_chance": 0.35,
		"worm_cooldown": 2.5,
		"telegraph_time": 0.6,
		"low_cover_enabled": true,
		"low_line_ratio": 0.18,
	},
	{
		"name": "S3 - Low Cover",
		"worm_enabled": true,
		"low_cover_enabled": true,
		"low_cover_accuracy_mul": 0.2, # אויבים כמעט לא פוגעים כשאתה נמוך
		"low_line_ratio": 0.18,
	},
	{
		"name": "S4 - Risk/Reward",
		"worm_enabled": true,
		"worm_dip_chance": 0.25,
		"worm_cooldown": 3.0,
		"telegraph_time": 0.6,
		"low_cover_enabled": true,
		"low_cover_accuracy_mul": 0.35,
		"low_line_ratio": 0.20,
	},
]

func diff_mul(key: String) -> float:
	return float(DIFF[difficulty].get(key, 1.0))

func rules() -> Dictionary:
	var i := clampi(stage_index, 0, STAGES.size() - 1)
	return STAGES[i]

func rule(key: String, default_value) -> Variant:
	return rules().get(key, default_value)
