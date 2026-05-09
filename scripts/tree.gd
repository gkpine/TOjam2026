extends Node2D

# idfk how to set autoplay in the inspector, so
func _ready() -> void:
	$AnimatedSprite2D.play("default")
