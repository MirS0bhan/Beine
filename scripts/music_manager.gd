extends AudioStreamPlayer

const MENU_MUSIC := preload("res://assets/music/menu.mp3")
const LEVEL_MUSIC := preload("res://assets/music/glitching.mp3")

var current_track: AudioStream = null

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("update_music_for_scene")
	print("✓ Music Manager initialized")

func update_music_for_scene() -> void:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return
	var scene_name := current_scene.name
	var scene_path := current_scene.scene_file_path
	var target_track: AudioStream = null
	if scene_name == "MainMenu" or scene_name == "LevelSelect":
		target_track = MENU_MUSIC
	elif "main_menu" in scene_path or "level_select" in scene_path:
		target_track = MENU_MUSIC
	elif "level_" in scene_path or "game" in scene_path:
		target_track = LEVEL_MUSIC
	elif current_scene.get_node_or_null("GameManager") or current_scene.get_node_or_null("LevelManager"):
		target_track = LEVEL_MUSIC
	else:
		target_track = MENU_MUSIC
	if target_track != current_track:
		play_track(target_track)

func play_track(track: AudioStream) -> void:
	if track == null:
		return
	current_track = track
	stream = track
	stop()
	play()
	var track_name := "Menu" if track == MENU_MUSIC else "Level"
	print("♪ Playing music: %s" % track_name)

func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		await get_tree().process_frame
		update_music_for_scene()

func play_menu_music() -> void:
	play_track(MENU_MUSIC)

func play_level_music() -> void:
	play_track(LEVEL_MUSIC)

func stop_music() -> void:
	stop()
	current_track = null

func restart_music() -> void:
	if current_track:
		stop()
		play()
		print("♪ Music restarted")
