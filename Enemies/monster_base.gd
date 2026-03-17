extends Node
class_name MonsterBase

@export_group("Combat")
@export var max_health: int = 1
@export var player_damage_multiplier: float = 1.0
@export var score_value: int = 0

@export_group("AR HUD")
@export var show_in_ar_hud: bool = true
@export var ar_threat_type: String = "MONSTER"
@export var ar_threat_text: String = ""

func get_health_ratio() -> float:
	if not ("health" in self) and not ("_health" in self):
		return 0.0
	var current := 0.0
	if "health" in self:
		current = float(self.health)
	elif "_health" in self:
		current = float(self._health)
	if max_health <= 0:
		return 0.0
	return current / float(max_health)

func get_ar_display_name() -> String:
	if ar_threat_text.strip_edges() != "":
		return ar_threat_text
	return String(name).replace("_", " ").to_upper()
