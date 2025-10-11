extends CanvasLayer

@onready var title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var level_name_label: Label = $Panel/MarginContainer/VBoxContainer/LevelName
@onready var stars_label: Label = $Panel/MarginContainer/VBoxContainer/Stars
@onready var time_label: Label = $Panel/MarginContainer/VBoxContainer/Stats/TimeLabel
@onready var coins_label: Label = $Panel/MarginContainer/VBoxContainer/Stats/CoinsLabel
@onready var next_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/NextButton
@onready var retry_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/RetryButton
@onready var level_select_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/LevelSelectButton
@onready var menu_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/MenuButton
@onready var panel: PanelContainer = $Panel

var next_level_scene: String = ""

func _ready() -> void:
	print("🎨 LevelCompleteUI: _ready() called")
	add_to_group("level_complete_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("  → Process mode set to ALWAYS")
	visible = true
	print("  → Visibility set")
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	print("  → Buttons connected")
	get_tree().paused = true
	print("  → Game paused")
	
	# Disable glitch effect when level complete UI is shown
	var glitch_overlay = get_node_or_null("/root/Game/GlitchOverlay")
	if glitch_overlay and glitch_overlay.has_method("set_enabled"):
		glitch_overlay.set_enabled(false)
		print("  → Glitch effect disabled")
	
	animate_entrance()
	print("  → Animation started")

func setup(level_num: int, level_name: String, stars: int, time: float, next_scene: String) -> void:
	print("🎨 LevelCompleteUI: setup() called with:")
	print("    Level: %d, Name: %s, Stars: %d, Time: %.2f" % [level_num, level_name, stars, time])
	if not is_node_ready():
		print("  → Waiting for nodes to be ready...")
		await ready
	print("  → Nodes are ready, updating UI...")
	next_level_scene = next_scene
	level_name_label.text = "Level %d: %s" % [level_num, level_name]
	time_label.text = "Time: %s" % format_time(time)
	print("  → Labels updated")
	var game_manager := get_node_or_null("/root/Game/GameManager")
	if game_manager and "score" in game_manager:
		coins_label.text = "Coins: %d" % game_manager.score
	else:
		coins_label.visible = false
	update_stars_display(stars)
	if next_level_scene.is_empty() or not ResourceLoader.exists(next_level_scene):
		next_button.visible = false
		print("  → Next button hidden (last level or scene doesn't exist)")

func update_stars_display(stars: int) -> void:
	stars_label.text = "%d/3 stars" % stars
	match stars:
		3:
			stars_label.modulate = Color(1.0, 0.88, 0.0)
		2:
			stars_label.modulate = Color(0.75, 0.75, 0.75)
		1:
			stars_label.modulate = Color(0.8, 0.5, 0.2)
		_:
			stars_label.modulate = Color.WHITE

func animate_entrance() -> void:
	panel.scale = Vector2(0.5, 0.5)
	panel.modulate.a = 0.0
	panel.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func _on_next_pressed() -> void:
	print("→ Next level button clicked")
	print("  Next scene: %s" % next_level_scene)
	get_tree().paused = false
	if next_level_scene.is_empty():
		print("  No next level, going to level select")
		_on_level_select_pressed()
		return
	if ResourceLoader.exists(next_level_scene):
		print("  Changing to next level...")
		get_tree().change_scene_to_file(next_level_scene)
	else:
		push_error("Next level scene not found: " + next_level_scene)
		_on_level_select_pressed()

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_level_select_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%d:%02d" % [mins, secs]
