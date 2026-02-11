extends Node
class_name MonsterRegistry

# מפה: label -> PackedScene
var _scenes: Dictionary = {}

func _ready() -> void:
	_scenes = {
		"octo_whale": preload("res://Monsters/OctoWhale/octo_whale.tscn"),
		 #כשתעביר גם את התולעת:
		 "space_worm": preload("res://Monsters/SpaceWorm/space_worm.tscn"),
	}

func get_scene(id: String) -> PackedScene:
	return _scenes.get(id, null)

func spawn(id: String, parent: Node, pos: Vector2) -> Node:
	var ps: PackedScene = get_scene(id)
	if ps == null:
		push_warning("Unknown monster id: %s" % id)
		return null

	var inst := ps.instantiate()
	parent.add_child(inst)

	if inst is Node2D:
		(inst as Node2D).global_position = pos

	return inst
