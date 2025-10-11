extends Node

const SAVE_FILE_PATH = "user://bein_save.json"
const MAX_LEVELS = 3

var unlocked_levels: Array[int] = [1]
var completed_levels: Dictionary = {}

signal level_unlocked(level_number: int)
signal level_completed(level_number: int, stars: int)
signal save_loaded()

func _ready() -> void:
	load_game()

func save_game() -> void:
	var save_data := {
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"save_date": Time.get_datetime_string_from_system()
	}
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("✓ Game saved successfully")
	else:
		push_error("Failed to save game: " + str(FileAccess.get_open_error()))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("ℹ No save file found, using default state")
		save_game()
		return
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load game: " + str(FileAccess.get_open_error()))
		return
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return
	var save_data: Dictionary = json.data
	var loaded_unlocked: Array = save_data.get("unlocked_levels", [1])
	unlocked_levels.clear()
	print("  Loading unlocked levels from save: ", loaded_unlocked)
	for level in loaded_unlocked:
		if level is int or level is float:
			unlocked_levels.append(int(level))
			print("    Added level: ", int(level))
	if unlocked_levels.is_empty():
		unlocked_levels.append(1)
		print("    No levels found, added level 1")
	print("  Final unlocked_levels: ", unlocked_levels)
	completed_levels = save_data.get("completed_levels", {})
	var cleaned := false
	for i in range(unlocked_levels.size() - 1, -1, -1):
		if unlocked_levels[i] > MAX_LEVELS:
			print("  ⚠ Removing invalid level %d (MAX_LEVELS = %d)" % [unlocked_levels[i], MAX_LEVELS])
			unlocked_levels.remove_at(i)
			cleaned = true
	if cleaned:
		save_game()
	print("✓ Game loaded successfully")
	save_loaded.emit()

func reset_progress() -> void:
	unlocked_levels = [1]
	completed_levels = {}
	save_game()
	print("✓ Progress reset")

func complete_level(level_number: int, stars: int = 1, completion_time: float = 0.0) -> void:
	print("=== SaveManager.complete_level() ===")
	print("  Level: %d" % level_number)
	print("  Stars: %d" % stars)
	print("  Time: %.2f" % completion_time)
	
	if level_number < 1 or level_number > MAX_LEVELS:
		push_error("Invalid level number: " + str(level_number))
		return
	
	var existing_data: Dictionary = completed_levels.get(str(level_number), {})
	var existing_stars: int = existing_data.get("stars", 0)
	var existing_time: float = existing_data.get("time", 999999.0)
	
	print("  Existing stars: %d" % existing_stars)
	print("  Existing time: %.2f" % existing_time)
	
	var should_update := false
	if stars > existing_stars:
		should_update = true
		print("  → Better stars! Updating...")
	elif stars == existing_stars and completion_time < existing_time:
		should_update = true
		print("  → Better time! Updating...")
	
	if should_update or str(level_number) not in completed_levels:
		completed_levels[str(level_number)] = {
			"stars": stars,
			"time": completion_time
		}
		print("  ✓ Level %d added to completed_levels" % level_number)
	else:
		print("  → No update needed (existing record is better)")
	
	print("  Current completed_levels: %s" % str(completed_levels))
	
	var next_level := level_number + 1
	if next_level <= MAX_LEVELS:
		print("  → Unlocking level %d" % next_level)
		unlock_level(next_level)
	else:
		print("  → This was the final level!")
	
	save_game()
	level_completed.emit(level_number, stars)
	print("✓ Level %d completed with %d stars" % [level_number, stars])

func unlock_level(level_number: int) -> void:
	if level_number < 1 or level_number > MAX_LEVELS:
		return
	if level_number not in unlocked_levels:
		unlocked_levels.append(level_number)
		unlocked_levels.sort()
		save_game()
		level_unlocked.emit(level_number)
		print("✓ Level %d unlocked" % level_number)

func is_level_unlocked(level_number: int) -> bool:
	return level_number in unlocked_levels

func is_level_completed(level_number: int) -> bool:
	return str(level_number) in completed_levels

func get_level_stars(level_number: int) -> int:
	var level_data: Dictionary = completed_levels.get(str(level_number), {})
	return level_data.get("stars", 0)

func get_level_time(level_number: int) -> float:
	var level_data: Dictionary = completed_levels.get(str(level_number), {})
	return level_data.get("time", 0.0)

func get_total_stars() -> int:
	var total := 0
	for level_data in completed_levels.values():
		total += level_data.get("stars", 0)
	return total

func get_completed_level_count() -> int:
	return completed_levels.size()

func get_highest_unlocked_level() -> int:
	if unlocked_levels.is_empty():
		return 1
	var highest := 1
	for level in unlocked_levels:
		if level > highest:
			highest = level
	return highest

func get_continue_level() -> int:
	var valid_levels: Array[int] = []
	for level in unlocked_levels:
		if level >= 1 and level <= MAX_LEVELS:
			valid_levels.append(level)
	valid_levels.sort()
	print("=== get_continue_level() Debug ===")
	print("  unlocked_levels: ", unlocked_levels)
	print("  valid_levels: ", valid_levels)
	print("  MAX_LEVELS: ", MAX_LEVELS)
	for level in valid_levels:
		var is_completed := is_level_completed(level)
		print("  Level %d: completed = %s" % [level, is_completed])
		if not is_completed:
			print("  → Returning incomplete level: %d" % level)
			return level
	if valid_levels.is_empty():
		print("  → No valid levels unlocked, returning 1")
		return 1
	var last_level := valid_levels[valid_levels.size() - 1]
	print("  → All levels completed, returning last level: %d" % last_level)
	return last_level
