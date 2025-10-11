extends Node

@export var deletion_interval: float = 1
@export var max_deletions_per_cycle: int = 1

var deletion_timer: float = 0.0
var heaven_mid_tileset: TileMapLayer
var hell_mid_tileset: TileMapLayer
var original_heaven_tiles: Array[Vector2i] = []
var original_hell_tiles: Array[Vector2i] = []
var deleted_heaven_tiles: Array[Vector2i] = []
var deleted_hell_tiles: Array[Vector2i] = []
var protected_atlas_coords: Array[Vector2i] = [
	Vector2i(5, 2),
	Vector2i(6, 2),
	Vector2i(7, 2),
	Vector2i(5, 1),
	Vector2i(6, 1),
	Vector2i(7, 1),
	Vector2i(5, 0),
	Vector2i(6, 0),
	Vector2i(7, 0),
]

func _ready():
	print("🔧 Block Deletion System: Initializing...")
	heaven_mid_tileset = get_node_or_null("/root/Game/HeavenObjects/Mid")
	hell_mid_tileset = get_node_or_null("/root/Game/HellObjects/Mid")
	if not heaven_mid_tileset:
		push_error("❌ Block Deletion System: Heaven mid tileset not found!")
		return
	if not hell_mid_tileset:
		push_error("❌ Block Deletion System: Hell mid tileset not found!")
		return
	store_original_tiles()
	print("✅ Block Deletion System: Ready!")
	print("  → Heaven tiles: ", original_heaven_tiles.size())
	print("  → Hell tiles: ", original_hell_tiles.size())
	print("  → Will delete ", max_deletions_per_cycle, " blocks every ", deletion_interval, " seconds")

func _process(delta):
	deletion_timer += delta
	if deletion_timer >= deletion_interval:
		deletion_timer = 0.0
		delete_random_blocks()

func store_original_tiles():
	original_heaven_tiles.clear()
	original_hell_tiles.clear()
	var heaven_used_cells = heaven_mid_tileset.get_used_cells()
	for cell in heaven_used_cells:
		if not is_protected_tile(cell):
			original_heaven_tiles.append(cell)
	var hell_used_cells = hell_mid_tileset.get_used_cells()
	for cell in hell_used_cells:
		if not is_protected_tile(cell):
			original_hell_tiles.append(cell)

func delete_random_blocks():
	if original_hell_tiles.is_empty():
		print("⚠️ Block Deletion System: No hell tiles left to delete!")
		return
	var heaven_deleted_count = 0
	var hell_deleted_count = 0
	for i in range(max_deletions_per_cycle):
		if original_hell_tiles.is_empty():
			break
		var random_index = randi() % original_hell_tiles.size()
		var tile_to_delete = original_hell_tiles[random_index]
		hell_mid_tileset.set_cell(tile_to_delete, -1)
		deleted_hell_tiles.append(tile_to_delete)
		original_hell_tiles.remove_at(random_index)
		hell_deleted_count += 1
		if tile_to_delete in original_heaven_tiles:
			heaven_mid_tileset.set_cell(tile_to_delete, -1)
			deleted_heaven_tiles.append(tile_to_delete)
			original_heaven_tiles.erase(tile_to_delete)
			heaven_deleted_count += 1
	if heaven_deleted_count > 0 or hell_deleted_count > 0:
		print("🗑️ Block Deletion System: Deleted ", hell_deleted_count, " hell tiles (+ ", heaven_deleted_count, " matching heaven tiles)")
		print("📊 Block Deletion System: Status - Heaven: ", original_heaven_tiles.size(), " tiles left, Hell: ", original_hell_tiles.size(), " tiles left")

func restore_all_tiles():
	print("🔄 Block Deletion System: Restoring all deleted tiles...")
	for tile_pos in deleted_heaven_tiles:
		heaven_mid_tileset.set_cell(tile_pos, 0, Vector2i(0, 0))
	for tile_pos in deleted_hell_tiles:
		hell_mid_tileset.set_cell(tile_pos, 0, Vector2i(0, 0))
	store_original_tiles()
	deleted_heaven_tiles.clear()
	deleted_hell_tiles.clear()
	print("✅ Block Deletion System: All tiles restored!")

func get_remaining_tile_count() -> Dictionary:
	return {
		"heaven": original_heaven_tiles.size(),
		"hell": original_hell_tiles.size(),
		"total": original_heaven_tiles.size() + original_hell_tiles.size()
	}

func set_deletion_interval(new_interval: float):
	deletion_interval = new_interval
	print("⏱️ Block Deletion System: Interval changed to ", new_interval, " seconds")

func pause_deletion():
	set_process(false)

func resume_deletion():
	set_process(true)

func is_protected_tile(tile_pos: Vector2i) -> bool:
	var heaven_atlas = heaven_mid_tileset.get_cell_atlas_coords(tile_pos)
	var hell_atlas = hell_mid_tileset.get_cell_atlas_coords(tile_pos)
	return heaven_atlas in protected_atlas_coords or hell_atlas in protected_atlas_coords
