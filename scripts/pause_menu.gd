extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/RestartButton
@onready var level_select_button: Button = $Panel/MarginContainer/VBoxContainer/LevelSelectButton
@onready var main_menu_button: Button = $Panel/MarginContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	print("✓ Pause menu initialized")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var level_complete_ui = get_tree().get_first_node_in_group("level_complete_ui")
		if level_complete_ui and level_complete_ui.visible:
			return
		toggle_pause()

func toggle_pause() -> void:
	if visible:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	get_tree().paused = true
	visible = true
	animate_in()
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager and game_manager.has_method("pause_block_deletion"):
		game_manager.pause_block_deletion()
	var glitch_overlay = get_node_or_null("/root/Game/GlitchOverlay")
	if glitch_overlay and glitch_overlay.has_method("set_enabled"):
		glitch_overlay.set_enabled(false)

func resume_game() -> void:
	visible = false
	get_tree().paused = false
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager and game_manager.has_method("resume_block_deletion"):
		game_manager.resume_block_deletion()
	var glitch_overlay = get_node_or_null("/root/Game/GlitchOverlay")
	if glitch_overlay and glitch_overlay.has_method("set_enabled"):
		glitch_overlay.set_enabled(true)

func animate_in() -> void:
	panel.scale = Vector2(0.5, 0.5)
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _on_resume_pressed() -> void:
	resume_game()

func _on_restart_pressed() -> void:
	var game_manager = get_node_or_null("/root/Game/GameManager")
	if game_manager and game_manager.has_method("restore_all_blocks"):
		game_manager.restore_all_blocks()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_level_select_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
