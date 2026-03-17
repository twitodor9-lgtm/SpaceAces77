extends Area2D

@export var damage: int = 1
@export var health: int = 30
@export var score_value: int = 300

var _dead: bool = false

# באילו פריימים התולעת “מסוכנת” (0=פריים ראשון)
@export var hit_frame_from: int = 2
@export var hit_frame_to: int = 4

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _did_hit: bool = false
var _can_hit: bool = false
var _attack_seq: int = 0

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

	z_index = 50
	anim.play("default")

func start_attack(target_x: float, ground_y: float, telegraph_time: float, leap_height: float) -> void:
	_attack_seq += 1
	var seq := _attack_seq

	# איפוס מצב לכל הופעה חדשה
	_did_hit = false
	_can_hit = false

	var underground_y := ground_y + 90.0
	var emerge_y := ground_y - maxf(leap_height, 80.0)
	global_position = Vector2(target_x, underground_y)

	if telegraph_time > 0.0:
		await get_tree().create_timer(telegraph_time).timeout
		if _attack_seq != seq or not is_instance_valid(self):
			return

	var tween := create_tween()
	tween.tween_property(self, "global_position:y", emerge_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", ground_y, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

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

func _award_score() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("add_score"):
		scene.call("add_score", score_value)

func take_damage(amount: int) -> void:
	if _dead:
		return
	health -= amount
	if health <= 0:
		_dead = true
		_award_score()
		queue_free()

func _on_anim_finished() -> void:
	queue_free()
