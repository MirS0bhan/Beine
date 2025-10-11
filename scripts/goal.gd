extends Area2D

signal player_reached_goal

@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var particles: CPUParticles2D = get_node_or_null("CPUParticles2D")

var is_active: bool = true
var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if animated_sprite:
		animated_sprite.play("default")
	if particles:
		particles.emitting = true

func _process(_delta: float) -> void:
	if animated_sprite:
		var pulse := 1.0 + sin(Time.get_ticks_msec() / 200.0) * 0.1
		animated_sprite.scale = Vector2(pulse, pulse)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body.name == "Player":
		player_inside = true
		trigger_goal()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false

func trigger_goal() -> void:
	if not is_active:
		print("⚠ Goal already triggered, ignoring")
		return
	print("🎯 GOAL TRIGGERED!")
	is_active = false
	
	print("  → Checking signal connections...")
	var connections = player_reached_goal.get_connections()
	print("  → Signal has %d connections: %s" % [connections.size(), connections])
	
	print("  → Emitting player_reached_goal signal...")
	player_reached_goal.emit()
	print("  → Signal emitted successfully")
	play_completion_effects()
	print("✓ Goal reached and effects playing!")

func play_completion_effects() -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = preload("res://assets/sounds/power_up.wav")
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)
	if particles:
		particles.amount = 50
		particles.emitting = true
	if animated_sprite:
		var tween := create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(2, 2, 2), 0.2)
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.2)
