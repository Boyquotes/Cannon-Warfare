extends KinematicBody2D

export (PackedScene) var Cannonball

## Constants
# Movement constants
export (float) var rotDampConstant; # Dampening constant of the rotation
export (float) var rotAcc; # Angular Acceleration
export (float) var velDampConstant; # Dampening constant of the linear velocity
export (int) var maxRotSpeed; # Maximum rotation speed
export (int) var accRateOfChange; # Rate at which linear acceleration increases
export (int) var maxSpeed; # Maximum linear speed
export (float) var knockbackMultiplier; # Multiplier for the knockback vector. Must be greater than 1 to offset the velocity before the collision
export (float) var defaultKnockback; # Smallest amount of knockback possible

# Other constants
export (int) var health; # HP of the player, number set in inspector is starting health
export (int) var playerNumber; # Player ID
export (int) var damageFromCollision; # Damage taken when colliding with body

# Declare member variables here.
var velVec = Vector2(); # Velocity Vector
var accVec = Vector2(); # Acceleration Vector
var rotVel = 0; # Angular velocity

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set sprite based on player id
	$AnimatedSprite.animation = "player" + str(playerNumber) + "Default";
	# Add self to player group
	add_to_group("Players")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Kill player if health reaches 0
	if (health <= 0):
		queue_free()
	
	accVec = Vector2();
	
	getMovementInput();
	
	# Ensure angular velocity doesn't exceed maximum speed
	if (abs(rotVel) > maxRotSpeed):
		if (rotVel < 0):
			rotVel = maxRotSpeed * -1;
		else:
			rotVel = maxRotSpeed;
			
	# Update rotation
	rotation += rotVel * delta;
	
	# Update, normalize, and apply velocity
	velVec += accVec;
	if (velVec.length() > maxSpeed):
		velVec = velVec.normalized() * maxSpeed;

	# Move and handle collisions
	var collision = move_and_collide(velVec * delta);
	# If collided with a BODY, then apply knockback to self
	if collision:
		var pointOfCollision = collision.get_position();
		
		# If the body we collided with was also a boat, then call its hitByOtherShip method (applies knockback to other ship due to own velocity)
		if (collision.get_collider().has_method("hitByOtherShip")):
			collision.get_collider().hitByOtherShip(velVec)
			# Do damage to the ship we hit. We only reach this if our velocity contributed to the collision, otherwise the other ship will go through this instead
			collision.get_collider().takeDamage(damageFromCollision);
			
		# Do damage to self if collided with something OTHER than a boat
		else:
			takeDamage(damageFromCollision)
		
		# Declare knockback vector. Points from collision to self, multiplied by velocity magnitude and multiplier
		var knockbackVector = ((self.position - pointOfCollision).normalized() * velVec.length() * knockbackMultiplier);
		# If the knockback vector is still zero, then apply the base amount of knockback
		if (knockbackVector == Vector2(0,0)):
			print("Here")
			knockbackVector = ((self.position - pointOfCollision).normalized() * defaultKnockback)
		velVec.x += knockbackVector.x
		velVec.y += knockbackVector.y
	
	# Dampening
	dampenRotation();
	dampenVelocity();
	
# Handles all input. Called every frame in _physics_process
func getMovementInput():
	# Movement
	if (Input.is_action_pressed("ui_left" + str(playerNumber))):
		rotVel -= rotAcc;
	if (Input.is_action_pressed("ui_right" + str(playerNumber))):
		rotVel += rotAcc;
	if (Input.is_action_pressed("ui_up" + str(playerNumber))):
		accVec.x = cos(rotation)
		accVec.y = sin(rotation)
		
		accVec = accVec.normalized() * accRateOfChange;
		
	# Shooting
	if (Input.is_action_just_pressed("ui_shoot" + str(playerNumber))):
		shoot();
		
func shoot():
	# Create first cannonball (aiming left), give position and angle
	var cannonball0 = Cannonball.instance();
	cannonball0.position = self.position;
	cannonball0.init(playerNumber, rotation - PI/2)

	# Create second cannonball (aiming right), give position and angle
	var cannonball1 = Cannonball.instance();
	cannonball1.position = self.position;
	cannonball1.init(playerNumber, rotation + PI/2)
	
	# Add as a child to the cannonballHolder child node. If we just add it as a child of the Player node, then it'll move weird
	# when the Player node moves due to how child transform is handled
	$BulletHolder.add_child(cannonball0);
	$BulletHolder.add_child(cannonball1);

# Applies knockback due to other ship when colliding with other ship. Called when this ship is hit by another ship
func hitByOtherShip(otherVelVec):
	velVec.x += otherVelVec.x;
	velVec.y += otherVelVec.y;
	
# Called when the ship is meant to take damage
func takeDamage(damageAmount):
	health -= damageAmount;
	$ShipHealthBar.frame -= damageAmount;
	
# Dampens the angular velocity. Called every frame in _physics_process
func dampenRotation():
	# If making rotVel approach zero by the rotDampConstant would make it switch signs, then just set it to zero
	if (abs(rotVel - rotDampConstant) < rotDampConstant):
		rotVel = 0
		return;
	else:
		rotVel -= sign(rotVel) * rotDampConstant;
		
# Dampens the linear velocity. Called when not pressing up
func dampenVelocity():
	# Only dampen the velocity if not pressing up. Otherwise, small enough velocities will be completely cancelled out
	if (Input.is_action_pressed("ui_up" + str(playerNumber))):
		return;
	
	# If making VelVec's x approach zero by the velDampConstant would make it switch signs, then just set it to zero
	if (abs(velVec.x - velDampConstant) < velDampConstant):
		velVec.x = 0;
	else:
		velVec.x -= sign(velVec.x) * velDampConstant
		
	# If making VelVec's y approach zero by the velDampConstant would make it switch signs, then just set it to zero
	if (abs(velVec.y - velDampConstant) < velDampConstant):
		velVec.y = 0;
	else:
		velVec.y -= sign(velVec.y) * velDampConstant
