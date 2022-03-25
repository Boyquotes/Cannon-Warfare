extends Area2D

var parentNumber;
var velVec = Vector2();

# Called to pass creator ID information
func init(parentNumber, rot):
	self.parentNumber = parentNumber;
	velVec.x = cos(rot)
	velVec.y = sin(rot)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += velVec.x;
	position.y += velVec.y;

# Called when the cannonball enters a body
func _on_Cannonball_body_entered(body):
	# Get all players
	var players = get_tree().get_nodes_in_group("Players");
	
	# If we've entered a player, ensure it's not the player that made us and then do damage
	if (body in players && body.playerNumber != parentNumber):
		body.health -= 1
		queue_free()
