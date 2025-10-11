extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	print("You died!")
	Engine.time_scale = 0.5
	
	# Play death animation if player has die() method
	if body.has_method("die"):
		body.die()
	
	body.get_node("CollisionShape2D").queue_free()
	timer.start()

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
