extends Node
class_name BaseLevelManager

@export var level_number: int = 1
@export var level_name: String = "Unnamed Level"
@export var next_level_scene: String = ""
@export var time_limit_3_stars: float = 120.0
@export var is_final_level: bool = false

var level_completed: bool = false
var level_start_time: float = 0.0
var current_level_time: float = 0.0

var game_manager: Node = null
var player: CharacterBody2D = null

signal level_complete(stars: int)

func _ready() -> void:
	var current_scene_root = get_tree().current_scene.name
	game_manager = get_node_or_null("/root/" + current_scene_root + "/GameManager")
	player = get_node_or_null("/root/" + current_scene_root + "/Player")
	if not game_manager:
		push_error("GameManager not found! Make sure GameManager exists in scene.")
	if not player:
		push_error("Player not found! Make sure Player exists in scene.")
	level_start_time = Time.get_ticks_msec() / 1000.0
	setup_level()

func _process(delta: float) -> void:
	if not level_completed:
		current_level_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
		update_level(delta)

func setup_level() -> void:
	pass

func update_level(_delta: float) -> void:
	pass

func calculate_stars() -> int:
	var stars := 1
	if current_level_time <= time_limit_3_stars:
		stars = 3
	elif current_level_time <= time_limit_3_stars * 1.5:
		stars = 2
	return stars

func complete_level() -> void:
	if level_completed:
		return
	level_completed = true
	disable_glitch_effect()
	var stars := calculate_stars()
	SaveManager.complete_level(level_number, stars, current_level_time)
	level_complete.emit(stars)
	show_level_complete_ui(stars)

func show_level_complete_ui(stars: int) -> void:
	if not ResourceLoader.exists("res://scenes/level_complete_ui.tscn"):
		push_error("level_complete_ui.tscn not found!")
		return
	var overlay := preload("res://scenes/level_complete_ui.tscn").instantiate()
	if not overlay:
		push_error("Failed to instantiate level_complete_ui!")
		return
	get_tree().current_scene.add_child(overlay)
	await get_tree().process_frame
	var final_next_scene := next_level_scene
	if is_final_level or next_level_scene.is_empty():
		final_next_scene = ""
	elif not ResourceLoader.exists(next_level_scene):
		final_next_scene = ""
	if overlay.has_method("setup"):
		overlay.setup(level_number, level_name, stars, current_level_time, final_next_scene)
	else:
		push_error("overlay doesn't have setup() method!")

func format_time(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%d:%02d" % [mins, secs]

func restart_level() -> void:
	get_tree().reload_current_scene()

func go_to_next_level() -> void:
	if next_level_scene.is_empty():
		go_to_level_select()
		return
	if ResourceLoader.exists(next_level_scene):
		get_tree().change_scene_to_file(next_level_scene)
	else:
		push_error("Next level scene not found: " + next_level_scene)
		go_to_level_select()

func go_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func disable_glitch_effect() -> void:
	var current_scene_root = get_tree().current_scene.name
	var glitch_overlay = get_node_or_null("/root/" + current_scene_root + "/GlitchOverlay")
	if glitch_overlay and glitch_overlay.has_method("set_enabled"):
		glitch_overlay.set_enabled(false)
