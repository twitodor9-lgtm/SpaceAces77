extends Node2D

@export var meteor_scene: PackedScene
@export var duration: float = 2.5
@export var spawn_interval: float = 0.2
@export var spawn_x_margin: float = 50.0
@export var spawn_y: float = -80.0

var _active := false


func try_use() -> void:
	if _active:
		return

	print("☀️ STAR PUNCH ACTIVATED")
	_active = true

	_spawn_loop()

	await get_tree().create_timer(duration).timeout
	_active = false



func _spawn_loop() -> void:
	var timer := get_tree().create_timer(duration)
	while timer.time_left > 0:
		_spawn_meteor()
		await get_tree().create_timer(spawn_interval).timeout

	_active = false
	print("☀️ STAR PUNCH FINISHED")


func _spawn_meteor() -> void:
	if meteor_scene == null:
		return

	var meteor = meteor_scene.instantiate()
	get_tree().current_scene.add_child(meteor)

	var screen := get_viewport().get_visible_rect().size
	var x := randf_range(spawn_x_margin, screen.x - spawn_x_margin)

	# ✅ תמיד ספאון מעל המסך, קבוע
	var y := -50.0

	meteor.global_position = Vector2(x, y)
	print("Meteor spawn Y:", y)
