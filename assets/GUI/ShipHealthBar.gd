extends AnimatedSprite

export (int) var verticalBuffer; # How far up the healthbar should be relative to the ship

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Ensure healthbar stays straight and directly above the ship
	global_rotation = 0;
	global_position.y = get_parent().position.y - verticalBuffer;
	global_position.x = get_parent().position.x;
