extends Node
class_name MonsterRegistry

# מפה: id -> PackedScene
var _scenes: Dictionary = {}

func _ensure_loaded() -> void:
	if not _scenes.is_empty():
		return

	_scenes = {
		"octo_whale": preload("res://Enemies/Monsters/OctoWhale/octo_whale.tscn"),
		"space_worm": preload("res://Enemies/Monsters/SpaceWorm/space_worm.tscn"),
		"void_raptor": preload("res://Enemies/Monsters/VoidRaptor/void_raptor.tscn"),
	}

func _ready() -> void:
	_ensure_loaded()

func get_scene(id: String) -> PackedScene:
	_ensure_loaded()
	return _scenes.get(id, null) as PackedScene

func spawn(id: String, parent: Node, pos: Vector2) -> Node:
	var ps: PackedScene = get_scene(id)
	if ps == null:
		push_warning("Unknown monster id: %s" % id)
		return null

	var inst: Node = ps.instantiate()
	parent.add_child(inst)

	if inst is Node2D:
		(inst as Node2D).global_position = pos

	return inst