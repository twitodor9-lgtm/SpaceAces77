extends Area2D

@export var damage: int = 1
@export var telegraph_scale_y: float = 0.75
@export var strike_scale_y: float = 1.35

var _active_hit: bool = false
var _tween: Tween

func _ready() -> void:
	monitoring = true
	monitorable = true
	_active_hit = false
	scale = Vector2(1.0, 0.65)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func telegraph(duration: float) -> void:
	_active_hit = false
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.0, telegraph_scale_y), duration)

func strike(duration: float) -> void:
	_active_hit = true
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.0, strike_scale_y), duration)

func retract(duration: float) -> void:
	_active_hit = false
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.0, 0.65), duration)

func _on_area_entered(area: Area2D) -> void:
	if not _active_hit:
		return

	var target: Node = area
	while target and not target.has_method("take_damage"):
		target = target.get_parent()
	if target:
		target.take_damage(damage)

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
