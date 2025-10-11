extends ColorRect

@export var glitch_intensity: float = 0.8
@export_range(1.0, 200.0) var pixelation_amount: float = 96.0
@export var enabled: bool = true

enum State { NORMAL_WAIT, PIXELATED_1, NORMAL_BREAK, PIXELATED_2 }
var current_state: State = State.NORMAL_WAIT
var state_timer: float = 0.0
var state_durations = {
	State.NORMAL_WAIT: 3.0,
	State.PIXELATED_1: 0.2,
	State.NORMAL_BREAK: 0.5,
	State.PIXELATED_2: 0.2
}

var glitch_material: ShaderMaterial

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_material = ShaderMaterial.new()
	glitch_material.shader = preload("res://shaders/glitch_effect.gdshader")
	glitch_material.set_shader_parameter("glitch_strength", 0.0)
	glitch_material.set_shader_parameter("pixelation_amount", pixelation_amount)
	material = glitch_material
	print("✓ Glitch Manager initialized with pattern cycle")

func _process(delta: float) -> void:
	if not enabled:
		return
	state_timer += delta
	if state_timer >= state_durations[current_state]:
		state_timer = 0.0
		advance_state()
		update_glitch_state()

func advance_state() -> void:
	match current_state:
		State.NORMAL_WAIT:
			current_state = State.PIXELATED_1
		State.PIXELATED_1:
			current_state = State.NORMAL_BREAK
		State.NORMAL_BREAK:
			current_state = State.PIXELATED_2
		State.PIXELATED_2:
			current_state = State.NORMAL_WAIT

func update_glitch_state() -> void:
	if glitch_material:
		match current_state:
			State.PIXELATED_1, State.PIXELATED_2:
				glitch_material.set_shader_parameter("glitch_strength", glitch_intensity)
			State.NORMAL_WAIT, State.NORMAL_BREAK:
				glitch_material.set_shader_parameter("glitch_strength", 0.0)

func set_glitch_intensity(new_intensity: float) -> void:
	glitch_intensity = clamp(new_intensity, 0.0, 1.0)

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		if glitch_material:
			glitch_material.set_shader_parameter("glitch_strength", 0.0)
		visible = false
	else:
		visible = true

func set_pixelation_amount(amount: float) -> void:
	if glitch_material:
		glitch_material.set_shader_parameter("pixelation_amount", clamp(amount, 1.0, 200.0))
