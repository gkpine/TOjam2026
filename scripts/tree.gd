extends Node2D

# idfk how to set autoplay in the inspector, so
func _ready() -> void:
	$AnimatedSprite2D.play("default")



func _on_area_2d_body_entered(body: Node2D) -> void:
	print("collision")
