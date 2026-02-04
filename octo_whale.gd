extends Area2D

@export var health: int = 60

@export var attack_interval: float = 1.2
@export var telegraph_time: float = 0.45
@export var strike_time: float = 0.18
@export var retract_time: float = 0.25

@export var tentacles_path: NodePath = NodePath("Tentacles")
@export var tentacles_per_attack: int = 2

var _tentacles: Array = []
var _timer: float = 0.0
var _state: int = 0
var _picked: Array = []

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")

	var root := get_node_or_null(tentacles_path)
	if root:
		for c in root.get_children():
			_tentacles.append(c)

	_timer = attack_interval
	_state = 0

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

func _process(delta: float) -> void:
	if _tentacles.size() == 0:
		return

	_timer -= delta
	if _timer > 0.0:
		return

	if _state == 0:
		# TELEGRAPH
		_pick_tentacles()
		for t in _picked:
			t.telegraph(telegraph_time)
		_timer = telegraph_time
		_state = 1

	elif _state == 1:
		# STRIKE
		for t in _picked:
			t.strike(strike_time)
		_timer = strike_time
		_state = 2

	elif _state == 2:
		# RETRACT + cooldown
		for t in _picked:
			t.retract(retract_time)
		_timer = attack_interval
		_state = 0

func _pick_tentacles() -> void:
	_picked.clear()
	# בחירה פשוטה: ערבוב ואז לקחת N
	var idxs: Array = []
	for i in range(_tentacles.size()):
		idxs.append(i)
	idxs.shuffle()

	var n: int = int(min(tentacles_per_attack, _tentacles.size()))

	for j in range(n):
		_picked.append(_tentacles[idxs[j]])
