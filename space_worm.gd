extends Area2D

@export var damage: int = 1

# באילו פריימים התולעת “מסוכנת” (0=פריים ראשון)
@export var hit_frame_from: int = 2
@export var hit_frame_to: int = 4

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _did_hit: bool = false
var _can_hit: bool = false

func _ready() -> void:
	add_to_group("worms")
	monitoring = true
	monitorable = true

	_did_hit = false
	_can_hit = false

	if not anim.frame_changed.is_connected(_on_frame_changed):
		anim.frame_changed.connect(_on_frame_changed)
	if not anim.animation_finished.is_connected(_on_anim_finished):
		anim.animation_finished.connect(_on_anim_finished)

	anim.play("default")

func start_attack(target_x: float, ground_y: float, telegraph_time: float, leap_height: float) -> void:
	# ✅ אין תנועה בסקריפט: רק קובעים מיקום קבוע
	global_position = Vector2(target_x, ground_y)

	# איפוס מצב לכל הופעה חדשה
	_did_hit = false
	_can_hit = false

	# מתחילים אנימציה מהתחלה
	anim.frame = 0
	anim.play("default")

func _physics_process(_delta: float) -> void:
	# ✅ פגיעה יציבה בלי סיגנלים: סריקת חפיפה ידנית בזמן “חלון פגיעה”
	if _can_hit and not _did_hit:
		for a in get_overlapping_areas():
			var target: Node = a
			while target and not target.has_method("take_damage"):
				target = target.get_parent()
			if target:
				target.take_damage(damage)
				_did_hit = true
				break

func _on_frame_changed() -> void:
	# חלון פגיעה לפי פריימים
	_can_hit = (anim.frame >= hit_frame_from and anim.frame <= hit_frame_to)

func _on_anim_finished() -> void:
	queue_free()
