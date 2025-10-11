extends Node2D

var last_position: Vector2

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	last_position = position

func _process(_delta):
	if position.x < last_position.x:
		animated_sprite.flip_h = true
	elif position.x > last_position.x:
		animated_sprite.flip_h = false
	last_position = position
