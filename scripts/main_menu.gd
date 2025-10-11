extends Node2D

@onready var play_button: Button = $MenuOverlay/CenterContainer/VBoxContainer/MenuButtons/PlayButton
@onready var levels_button: Button = $MenuOverlay/CenterContainer/VBoxContainer/MenuButtons/LevelsButton
@onready var quit_button: Button = $MenuOverlay/CenterContainer/VBoxContainer/MenuButtons/QuitButton
@onready var title: Label = $MenuOverlay/CenterContainer/VBoxContainer/TitleContainer/Title

func _ready() -> void:
	get_tree().paused = false
	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	SaveManager.load_game()
	update_play_button_text()
	animate_entrance()
	print("✓ Main menu ready")

func update_play_button_text() -> void:
	var continue_level := SaveManager.get_continue_level()
	if continue_level == 1 and not SaveManager.is_level_completed(1):
		play_button.text = "PLAY"
	else:
		play_button.text = "CONTINUE"

func animate_entrance() -> void:
	var buttons := [play_button, levels_button, quit_button]
	for button in buttons:
		button.modulate.a = 1.0

func _on_play_pressed() -> void:
	print("Starting game...")
	var continue_level := SaveManager.get_continue_level()
	var level_scene := "res://scenes/level_%d.tscn" % continue_level
	print("  → Continuing from Level %d" % continue_level)
	print("  → Loading: %s" % level_scene)
	if ResourceLoader.exists(level_scene):
		transition_to_scene(level_scene)
	else:
		print("  ⚠ Level %d scene not found, starting from Level 1" % continue_level)
		transition_to_scene("res://scenes/level_1.tscn")

func _on_levels_pressed() -> void:
	print("Opening level select...")
	transition_to_scene("res://scenes/level_select.tscn")

func _on_quit_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()

func transition_to_scene(scene_path: String) -> void:
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.color.a = 0.0
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$MenuOverlay.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
