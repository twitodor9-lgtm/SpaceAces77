extends Node2D

@export var distance: float = 260.0
@export var cooldown: float = 1.25
@export var iframes: float = 0.35
@export var edge_margin: float = 48.0

var _next_ready_ms: int = 0
@onready var _player: Node2D = _resolve_player() as Node2D

func _resolve_player() -> Node:
	if get_parent() and get_parent().get_parent():
		return get_parent().get_parent()
	return get_tree().get_first_node_in_group("player")

func try_use() -> void:
	if _player == null:
		print("WayJump: player not found")
		return

	var now := Time.get_ticks_msec()
	if now < _next_ready_ms:
		return
	_next_ready_ms = now + int(cooldown * 1000.0)

	# קפיצה קדימה לפי כיוון המטוס
	var dir := Vector2(1, 0).rotated(_player.rotation)
	var target := _player.position + dir * distance
	if _player and _player.has_method("show_ability_text"):
		_player.show_ability_text("WAY JUMP!")

	# clamp לפי מסך (מתאים ל-wraparound שלך)
	var screen := _player.get_viewport_rect().size
	target.x = clampf(target.x, edge_margin, screen.x - edge_margin)
	target.y = clampf(target.y, edge_margin, screen.y - edge_margin)

	_player.position = target

	if _player.has_method("set_invulnerable"):
		_player.set_invulnerable(iframes)

	print("WayJump: DONE")
