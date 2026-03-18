extends Node
class_name AbilityManager

signal abilities_changed

@export var controlled_player_path: NodePath = NodePath("..")

var _player: Node = null
var _abilities: Array[Node] = []
var _action_to_ability_path: Dictionary = {
	"star_punch": NodePath("StarPunch"),
	"dolphin_wave": NodePath("DolphinWaveAbility"),
	"ability_way_jump": NodePath("WayJump"),
	"ability_turbo": NodePath("Turbo"),
	"ability_deflector_shield": NodePath("Deflector Shield"),
}

func _ready() -> void:
	_refresh_refs()
	child_entered_tree.connect(_on_abilities_tree_changed)
	child_exiting_tree.connect(_on_abilities_tree_changed)
	abilities_changed.emit()

func _process(_delta: float) -> void:
	for action_name in _action_to_ability_path.keys():
		if Input.is_action_just_pressed(action_name):
			try_activate(action_name)
	abilities_changed.emit()

func _refresh_refs() -> void:
	_player = get_node_or_null(controlled_player_path)
	_abilities.clear()
	for child in get_children():
		if child != null and child.has_method("try_use"):
			_abilities.append(child)
			if "owner_player_path" in child:
				child.set("owner_player_path", NodePath("../.."))

func _on_abilities_tree_changed(_node: Node) -> void:
	call_deferred("_refresh_and_emit")

func _refresh_and_emit() -> void:
	_refresh_refs()
	abilities_changed.emit()

func try_activate(action_name: String) -> bool:
	var ability_path: NodePath = _action_to_ability_path.get(action_name, NodePath(""))
	if ability_path == NodePath(""):
		return false
	var ability := get_node_or_null(ability_path)
	if ability == null or not ability.has_method("try_use"):
		return false
	ability.call("try_use")
	abilities_changed.emit()
	return true

func get_ability_snapshots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ability in _abilities:
		if not is_instance_valid(ability):
			continue
		var label := String(ability.get("label_text") if "label_text" in ability else ability.name)
		if label.strip_edges() == "":
			label = ability.name
		var cooldown := float(ability.get("cooldown") if "cooldown" in ability else 0.0)
		var cooldown_left := float(ability.get("cooldown_left") if "cooldown_left" in ability else 0.0)
		out.append({
			"name": ability.name,
			"label": label,
			"cooldown": cooldown,
			"cooldown_left": cooldown_left,
			"ready": cooldown_left <= 0.01,
		})
	return out

func get_player() -> Node:
	return _player
