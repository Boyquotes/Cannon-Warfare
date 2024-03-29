extends Area2D

var parentNumber;
var velVec = Vector2();
var hitSomething = false;

export (int) var damage;
export (float) var speed;

# Called to pass creator ID information
func init(parentNumber, rot):
	self.parentNumber = parentNumber;
	
	# Set sprite based on parent id
	$AnimatedSprite.animation = "cannonball" + str(self.parentNumber);
	
	# Set velocity based on own rotation
	velVec.x = cos(rot)
	velVec.y = sin(rot)
	velVec = velVec.normalized() * speed;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += velVec * delta
	# If we've hit something, and the sound is done playing, then destroy self
	if (hitSomething):
		if ($HitSound.playing == false):
			queue_free();

# Called when the cannonball enters a body
func _on_Cannonball_body_entered(body):
	# Get all players
	var players = get_tree().get_nodes_in_group("Players");
	
	# If we're invisible, we've already hit something and are just playing the sound. Leave this function
	if ($AnimatedSprite.visible == false):
		return;
	
	# If we've entered a player, ensure it's not the player that made us
	if (body in players && body.PLAYER_NUMBER != parentNumber):
		# Damage the ship
		body.takeDamage(damage)
		
		# Play the hitsound and set self to invisible, if we haven't already done so
		if (hitSomething == false):
			$HitSound.playing = true;
			$AnimatedSprite.visible = false;
		
		hitSomething = true;
	if (not body in players):
		# Play the hitsound and set self to invisible, if we haven't already done so
		if (hitSomething == false):
			$HitSound.playing = true;
			$AnimatedSprite.visible = false;
		
		hitSomething = true;
