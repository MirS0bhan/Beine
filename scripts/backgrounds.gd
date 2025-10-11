extends Node

var current_world = "heaven"
var world_switch_timer = 0.0
var world_switch_interval = 5.0
var flicker_timings = [
	{"time": 1.0, "duration": 0.07},
	{"time": 0.7, "duration": 0.1},
	{"time": 0.5, "duration": 0.09},
	{"time": 0.35, "duration": 0.08},
	{"time": 0.25, "duration": 0.07},
	{"time": 0.18, "duration": 0.06},
	{"time": 0.125, "duration": 0.05},
	{"time": 0.09, "duration": 0.04},
	{"time": 0.06, "duration": 0.03},
	{"time": 0.04, "duration": 0.02},
	{"time": 0.02, "duration": 0.015},
	{"time": 0.01, "duration": 0.01}
]
var flicker_triggered = {}
var is_flickering = false

@onready var heaven_objects = $HeavenObjects
@onready var hell_objects = $HellObjects

func _ready():
	setup_worlds()
	start_world_switching()

func _process(delta):
	update_world_timer(delta)

func setup_worlds():
	set_world_visibility(heaven_objects, true)
	set_world_visibility(hell_objects, false)

func set_world_visibility(world_container: Node, visible: bool):
	for child in world_container.get_children():
		if "visible" in child:
			child.visible = visible

func start_world_switching():
	world_switch_timer = 2.0

func update_world_timer(delta):
	world_switch_timer -= delta
	var time_left = max(0, world_switch_timer)
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
	else:
		set_world_visibility(heaven_objects, false)
		set_world_visibility(hell_objects, true)

func switch_world():
	world_switch_timer = world_switch_interval
	flicker_triggered.clear()
	current_world = "hell" if current_world == "heaven" else "heaven"
	if current_world == "heaven":
		set_world_visibility(heaven_objects, true)
		set_world_visibility(hell_objects, false)
	else:
		set_world_visibility(heaven_objects, false)
		set_world_visibility(hell_objects, true)
