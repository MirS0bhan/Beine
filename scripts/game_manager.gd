extends Node

var score = 0
var current_world = "heaven"
var world_switch_timer = 0.0
var world_switch_interval = 5.0
var flicker_timings = [
	{"time": 0.5, "duration": 0.1},
	{"time": 0.3, "duration": 0.08},
	{"time": 0.1, "duration": 0.06},
	{"time": 0.05, "duration": 0.04}
]
var flicker_triggered = {}
var is_flickering = false

@onready var score_label = $ScoreLabel
@onready var world_timer_label = $WorldTimerLabel
@onready var world_indicator = $WorldIndicator
@onready var transition_overlay = $TransitionOverlay
@onready var heaven_objects = get_parent().get_node("HeavenObjects")
@onready var hell_objects = get_parent().get_node("HellObjects")
@onready var labels_node = get_parent().get_node_or_null("Labels")
@onready var heaven_background = get_parent().get_node("HeavenObjects/Background")
@onready var heaven_mid = get_parent().get_node("HeavenObjects/Mid")
@onready var hell_background = get_parent().get_node("HellObjects/Background")
@onready var hell_mid = get_parent().get_node("HellObjects/Mid")
@onready var audio_stream_player = $AudioStreamPlayer

var block_deletion_system: Node
var platforms: Array = []

func _ready():
	add_to_group("game_manager")
	setup_worlds()
	start_world_switching()
	setup_block_deletion_system()
	find_platforms()
	call_deferred("restart_level_music")

func _process(delta):
	update_world_timer(delta)

func setup_worlds():
	set_world_visibility(heaven_objects, true)
	set_world_visibility(hell_objects, false)
	update_world_visuals()

func set_world_visibility(world_container: Node, visible: bool):
	for child in world_container.get_children():
		if child.has_method("set_visible"):
			child.set_visible(visible)
		elif child is CanvasItem:
			child.visible = visible
		if child.name == "Enemies":
			for enemy in child.get_children():
				# Disable enemy movement script
				if enemy.has_method("set_process"):
					enemy.set_process(visible)
				
				# Hide the enemy sprite
				if enemy is CanvasItem:
					enemy.visible = visible
				
				# Disable killzone (Area2D) collision
				var killzone = enemy.get_node_or_null("Killzone")
				if killzone and killzone is Area2D:
					killzone.monitoring = visible
					killzone.monitorable = visible
				
				# Disable enemy collision body
				if enemy.has_method("set_collision_layer"):
					enemy.set_collision_layer(1 if visible else 0)
				if enemy.has_method("set_collision_mask"):
					enemy.set_collision_mask(1 if visible else 0)
		if child.name == "Coins":
			for coin in child.get_children():
				if coin is Area2D:
					coin.monitoring = visible
					coin.monitorable = visible
		set_world_visibility(child, visible)

func start_world_switching():
	world_switch_timer = world_switch_interval

func update_world_timer(delta):
	world_switch_timer -= delta
	var time_left = max(0, world_switch_timer)
	world_timer_label.text = "World changes in: " + str(int(time_left) + 1)
	if not is_flickering:
		for flicker in flicker_timings:
			var key = str(flicker.time)
			if time_left <= flicker.time and not flicker_triggered.get(key, false):
				flicker_triggered[key] = true
				trigger_flicker(flicker.duration)
				break
	if world_switch_timer <= 0:
		switch_world()

func trigger_flicker(duration: float):
	if is_flickering:
		return
	is_flickering = true
	var destination_world = "hell" if current_world == "heaven" else "heaven"
	show_world_preview(destination_world)
	await get_tree().create_timer(duration).timeout
	show_world_preview(current_world)
	is_flickering = false

func show_world_preview(world: String):
	if world == "heaven":
		set_world_visibility(heaven_objects, true)
		set_world_visibility(hell_objects, false)
		update_platforms_to_world("heaven")
		update_label_colors(Color(0.2, 0.2, 0.2))
		world_timer_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	else:
		set_world_visibility(heaven_objects, false)
		set_world_visibility(hell_objects, true)
		update_platforms_to_world("hell")
		update_label_colors(Color(1.0, 1.0, 1.0))
		world_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func switch_world():
	world_switch_timer = world_switch_interval
	flicker_triggered.clear()
	play_transition_effect()
	if current_world == "heaven":
		current_world = "hell"
	else:
		current_world = "heaven"
	await get_tree().create_timer(0.3).timeout
	update_world_visuals()

func play_transition_effect():
	if current_world == "heaven":
		audio_stream_player.stream = preload("res://assets/sounds/explosion.wav")
	else:
		audio_stream_player.stream = preload("res://assets/sounds/power_up.wav")
	audio_stream_player.play()
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.1)
	tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.2)

func update_world_visuals():
	if current_world == "heaven":
		set_world_visibility(heaven_objects, true)
		set_world_visibility(hell_objects, false)
		heaven_mid.collision_enabled = true
		hell_mid.collision_enabled = false
		transition_overlay.color = Color(0.7, 0.9, 1.0, 0.0)
		update_platforms_visibility()
		update_label_colors(Color(0.2, 0.2, 0.2))
		world_timer_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	else:
		set_world_visibility(heaven_objects, false)
		set_world_visibility(hell_objects, true)
		heaven_mid.collision_enabled = false
		hell_mid.collision_enabled = true
		transition_overlay.color = Color(0.8, 0.1, 0.1, 0.0)
		update_platforms_visibility()
		update_label_colors(Color(1.0, 1.0, 1.0))
		world_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func add_point():
	score += 1
	var tween = create_tween()
	tween.tween_property(score_label, "modulate", Color(1.0, 1.0, 0.0), 0.2)
	tween.tween_property(score_label, "modulate", Color(1.0, 1.0, 1.0), 0.2)

func setup_block_deletion_system():
	print("🔧 GameManager: Setting up block deletion system...")
	block_deletion_system = Node.new()
	block_deletion_system.name = "BlockDeletionSystem"
	block_deletion_system.set_script(preload("res://scripts/block_deletion_system.gd"))
	add_child(block_deletion_system)
	print("✅ GameManager: Block deletion system initialized!")

func pause_block_deletion():
	if block_deletion_system and block_deletion_system.has_method("pause_deletion"):
		block_deletion_system.pause_deletion()

func resume_block_deletion():
	if block_deletion_system and block_deletion_system.has_method("resume_deletion"):
		block_deletion_system.resume_deletion()

func restore_all_blocks():
	if block_deletion_system and block_deletion_system.has_method("restore_all_tiles"):
		block_deletion_system.restore_all_tiles()

func get_block_deletion_status() -> Dictionary:
	if block_deletion_system and block_deletion_system.has_method("get_remaining_tile_count"):
		return block_deletion_system.get_remaining_tile_count()
	return {"heaven": 0, "hell": 0, "total": 0}

func restart_level_music():
	var music = get_node_or_null("/root/Music")
	if music and music.has_method("restart_music"):
		music.restart_music()

func find_platforms():
	platforms.clear()
	var platforms_node = get_parent().get_node_or_null("Platforms")
	if platforms_node:
		for child in platforms_node.get_children():
			if child.has_method("set_heaven") and child.has_method("set_hell"):
				platforms.append(child)
	search_for_platforms_in_node(heaven_objects)
	search_for_platforms_in_node(hell_objects)
	print("✓ Found %d platforms" % platforms.size())

func search_for_platforms_in_node(node: Node):
	if node.has_method("set_heaven") and node.has_method("set_hell"):
		platforms.append(node)
	for child in node.get_children():
		search_for_platforms_in_node(child)

func update_platforms_visibility():
	update_platforms_to_world(current_world)

func update_platforms_to_world(world: String):
	for platform in platforms:
		if world == "heaven":
			platform.set_heaven()
		else:
			platform.set_hell()
	print("🔄 Updated %d platforms to %s world" % [platforms.size(), world])

func update_label_colors(color: Color):
	if labels_node:
		for child in labels_node.get_children():
			if child is Label:
				child.add_theme_color_override("font_color", color)
