extends Node2D

@onready var level_grid: GridContainer = $SelectOverlay/MarginContainer/VBoxContainer/ScrollContainer/CenterContainer/LevelGrid
@onready var back_button: Button = $SelectOverlay/MarginContainer/VBoxContainer/Header/BackButton
@onready var stats_label: Label = $SelectOverlay/MarginContainer/VBoxContainer/Header/StatsLabel

const LEVEL_SCENES := [
	"res://scenes/level_1.tscn",
	"res://scenes/level_2.tscn",
	"res://scenes/level_3.tscn",
]

const LEVEL_NAMES := [
	"First Steps",
	"Dual Path",
	"Love Shape"
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	create_level_buttons()
	update_stats_display()

func get_unlocked_levels() -> Array:
	return [1, 2, 3]

func get_completed_levels() -> Dictionary:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		return sm.completed_levels
	return {}

func create_level_buttons() -> void:
	for child in level_grid.get_children():
		child.queue_free()
	for i in range(LEVEL_SCENES.size()):
		var level_number := i + 1
		var button := create_level_button(level_number)
		level_grid.add_child(button)

func create_level_button(level_number: int) -> Control:
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(150, 150)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	container.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var number_label := Label.new()
	number_label.text = str(level_number)
	var pixel_font := load("res://assets/fonts/PixelOperator8-Bold.ttf")
	number_label.add_theme_font_override("font", pixel_font)
	number_label.add_theme_font_size_override("font_size", 48)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(number_label)
	var name_label := Label.new()
	if level_number <= LEVEL_NAMES.size():
		name_label.text = LEVEL_NAMES[level_number - 1]
	else:
		name_label.text = "Level " + str(level_number)
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	var sm = get_node("/root/SaveManager")
	var stars := 0
	if sm:
		stars = sm.get_level_stars(level_number)
	var stars_label := Label.new()
	stars_label.text = get_stars_text(stars)
	stars_label.add_theme_font_override("font", pixel_font)
	stars_label.add_theme_font_size_override("font_size", 14)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stars_label)
	var is_unlocked := true
	if is_unlocked:
		var button := Button.new()
		button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.flat = true
		button.pressed.connect(_on_level_selected.bind(level_number))
		button.mouse_entered.connect(_on_level_hover.bind(container, true))
		button.mouse_exited.connect(_on_level_hover.bind(container, false))
		container.add_child(button)
		container.modulate = Color.WHITE
		number_label.add_theme_color_override("font_color", Color(1, 0.88, 0))
		var is_completed := false
		if sm:
			is_completed = sm.is_level_completed(level_number)
		if is_completed:
			stars_label.add_theme_color_override("font_color", Color(1, 0.88, 0))
		else:
			stars_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		container.modulate = Color(0.4, 0.4, 0.4)
		number_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		var lock_label := Label.new()
		lock_label.text = "LOCKED"
		lock_label.add_theme_font_override("font", pixel_font)
		lock_label.add_theme_font_size_override("font_size", 32)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lock_label)
		stars_label.visible = false
	return container

func get_stars_text(stars: int) -> String:
	return "%d/3 stars" % stars

func update_stats_display() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var total_stars := 0
	var completed := 0
	if sm:
		total_stars = sm.get_total_stars()
		completed = sm.get_completed_level_count()
	var max_stars := LEVEL_SCENES.size() * 3
	stats_label.text = "Stars: %d/%d | Completed: %d/%d" % [total_stars, max_stars, completed, LEVEL_SCENES.size()]

func _on_level_hover(container: PanelContainer, is_hovering: bool) -> void:
	if is_hovering:
		container.modulate = Color(1.2, 1.2, 1.2)
	else:
		container.modulate = Color.WHITE

func _on_level_selected(level_number: int) -> void:
	if level_number > LEVEL_SCENES.size():
		return
	var scene_path: String = LEVEL_SCENES[level_number - 1]
	transition_to_scene(scene_path)

func _on_back_pressed() -> void:
	transition_to_scene("res://scenes/main_menu.tscn")

func transition_to_scene(scene_path: String) -> void:
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.color.a = 0.0
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$SelectOverlay.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
