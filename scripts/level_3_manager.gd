extends BaseLevelManager

func setup_level() -> void:
	level_number = 3
	level_name = "Heaven's Gate"
	next_level_scene = ""
	is_final_level = true
	time_limit_3_stars = 60.0
	var current_scene_root = get_tree().current_scene.name
	var goal := get_node_or_null("/root/" + current_scene_root + "/Goal")
	if goal and goal.has_signal("player_reached_goal"):
		goal.player_reached_goal.connect(_on_goal_reached)
	else:
		push_error("Goal node not found or doesn't have player_reached_goal signal!")

func _on_goal_reached() -> void:
	complete_level()

func calculate_stars() -> int:
	var stars := 1
	if game_manager:
		var score: int = game_manager.score
		if current_level_time <= time_limit_3_stars * 1.5:
			stars = 2
		if current_level_time <= time_limit_3_stars and score >= 5:
			stars = 3
	return stars
