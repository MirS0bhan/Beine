extends AnimatableBody2D

@onready var heaven_sprite: Sprite2D = $Heaven
@onready var hell_sprite: Sprite2D = $Hell

func _ready() -> void:
	heaven_sprite.visible = true
	hell_sprite.visible = false
	print("✓ Platform initialized")

func set_heaven() -> void:
	heaven_sprite.visible = true
	hell_sprite.visible = false

func set_hell() -> void:
	heaven_sprite.visible = false
	hell_sprite.visible = true
