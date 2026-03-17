extends RefCounted
class_name GameplayRuntime

static func setup_ui(host: Node, stage_index: int, score: int, next_stage_callback: Callable = Callable()) -> CanvasLayer:
	var ui_root := host.get_node_or_null("UIRoot") as CanvasLayer
	if ui_root == null:
		return null

	if next_stage_callback.is_valid() and ui_root.has_signal("next_stage_pressed"):
		var sig: Signal = ui_root.get("next_stage_pressed")
		if not sig.is_connected(next_stage_callback):
			sig.connect(next_stage_callback)

	if ui_root.has_method("set_stage"):
		ui_root.call("set_stage", stage_index)

	if ui_root.has_method("set_score"):
		ui_root.call("set_score", score)

	return ui_root

static func setup_background(host: Node) -> Node:
	var bg_node := host.get_node_or_null("Background")
	if bg_node != null and bg_node.has_method("apply_stage"):
		bg_node.call("apply_stage")
	return bg_node

static func connect_timer(host: Node, timer_name: String, callback: Callable) -> Timer:
	var timer := host.get_node_or_null(timer_name) as Timer
	if timer == null:
		return null
	if callback.is_valid() and not timer.timeout.is_connected(callback):
		timer.timeout.connect(callback)
	return timer

static func setup_monster_director(host: Node) -> MonsterDirector:
	var existing_md := host.get_node_or_null("MonsterDirector")
	if existing_md is MonsterDirector:
		return existing_md as MonsterDirector

	var md := MonsterDirector.new()
	md.name = "MonsterDirector"
	host.add_child(md)
	return md

static func set_timer_enabled(timer: Timer, enabled: bool) -> void:
	if timer == null:
		return
	if enabled:
		if timer.is_stopped():
			timer.start()
	else:
		timer.stop()

static func set_node_enabled(node: Node, enabled: bool) -> void:
	if node == null:
		return

	node.set_process(enabled)
	node.set_physics_process(enabled)

	if node is Area2D:
		(node as Area2D).monitoring = enabled
		(node as Area2D).monitorable = enabled

static func apply_stage_rules(host: Node) -> void:
	set_timer_enabled(host.get_node_or_null("EnemySpawnTimer") as Timer,
		bool(GameBalance.rule("air_spawner_enabled", true)))

	set_timer_enabled(host.get_node_or_null("GroundEnemyTimer") as Timer,
		bool(GameBalance.rule("ground_spawner_enabled", true)))

	set_node_enabled(host.get_node_or_null("CloudSpawner"),
		bool(GameBalance.rule("cloud_spawner_enabled", true)))

	set_node_enabled(host.get_node_or_null("WormSpawner"),
		bool(GameBalance.rule("worm_enabled", false)))
