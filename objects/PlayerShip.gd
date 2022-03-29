extends KinematicBody2D

export (PackedScene) var Cannonball

## Constants
# Movement constants
export (float) var ROT_DAMP_CONSTANT; # Dampening constant of the rotation
export (float) var ROT_ACC; # Angular Acceleration
export (float) var VEL_DAMP_CONSTANT; # Dampening constant of the linear velocity
export (int) var MAX_ROT_SPEED; # Maximum rotation speed
export (int) var ACC_RATE_OF_CHANGE; # Rate at which linear acceleration increases
export (int) var MAX_SPEED; # Maximum linear speed
export (float) var KNOCKBACK_MULTIPLIER; # Multiplier for the knockback vector. Must be greater than 1 to offset the velocity before the collision
export (float) var DEFAULT_KNOCKBACK; # Smallest amount of knockback possible

# Other constants
export (int) var PLAYER_NUMBER; # Player ID
export (int) var DAMAGE_FROM_COLLISION; # Damage taken when colliding with body
export (int) var MAX_CANNON_CHARGE; # Value at which the cannon is ready to fire
export (float) var CANNON_CHARGE_RATE_OF_CHANGE; # Rate at which the cannon charge changes per frame. Half of this is removed from the charge value every frame as well

# GUI Identifiers
var cannonChargeBarVerticalBuffer; # How far the charge bar is from the ship, vertically

# Declare member variables here.
export (int) var health; # HP of the player, number set in inspector is starting health
var velVec = Vector2(); # Velocity Vector
var accVec = Vector2(); # Acceleration Vector
var rotVel = 0; # Angular velocity
var cannonCharge = 0; # How much the cannon is currently charged

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set sprite based on player id
	$AnimatedSprite.animation = "player" + str(PLAYER_NUMBER) + "Default";
	# Add self to player group
	add_to_group("Players")
	
	# Initalize the CannonChargeBar
	$CannonChargeBar.min_value = 0;
	$CannonChargeBar.max_value = MAX_CANNON_CHARGE;
	cannonChargeBarVerticalBuffer = 40
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Kill player if health reaches 0
	if (health <= 0):
		queue_free()
	
	# Reset vectors and get input
	accVec = Vector2();
	getInput();
	
	# Decrease the charge value by half of the 'standard' rate of change 
	if (cannonCharge >= 0):
		cannonCharge -= (CANNON_CHARGE_RATE_OF_CHANGE/2)
	# If cannonCharge is less than zero
	else:
		cannonCharge = 0
	$CannonChargeBar.value = cannonCharge;
	
	# Ensure angular velocity doesn't exceed maximum speed
	if (abs(rotVel) > MAX_ROT_SPEED):
		if (rotVel < 0):
			rotVel = MAX_ROT_SPEED * -1;
		else:
			rotVel = MAX_ROT_SPEED;
			
	# Update rotation
	rotation += rotVel * delta;
	
	# Update, normalize, and apply velocity
	velVec += accVec;
	if (velVec.length() > MAX_SPEED):
		velVec = velVec.normalized() * MAX_SPEED;

	# Move and handle collisions
	var collision = move_and_collide(velVec * delta);
	# If collided with a BODY, then apply knockback to self
	if collision:
		var pointOfCollision = collision.get_position();
		
		# If the body we collided with was also a boat, then call its hitByOtherShip method (applies knockback to other ship due to own velocity)
		if (collision.get_collider().has_method("hitByOtherShip")):
			collision.get_collider().hitByOtherShip(velVec)
			# Do damage to the ship we hit. We only reach this if our velocity contributed to the collision, otherwise the other ship will go through this instead
			collision.get_collider().takeDamage(DAMAGE_FROM_COLLISION);
			
		# Do damage to self if collided with something OTHER than a boat
		else:
			takeDamage(DAMAGE_FROM_COLLISION)
		
		# Declare knockback vector. Points from collision to self, multiplied by velocity magnitude and multiplier
		var knockbackVector = ((self.position - pointOfCollision).normalized() * velVec.length() * KNOCKBACK_MULTIPLIER);
		# If the knockback vector is still zero, then apply the base amount of knockback
		if (knockbackVector == Vector2(0,0)):
			knockbackVector = ((self.position - pointOfCollision).normalized() * DEFAULT_KNOCKBACK)
		velVec.x += knockbackVector.x
		velVec.y += knockbackVector.y
	
	# Dampening
	dampenRotation();
	dampenVelocity();
	
	# GUI Handling
	manageChargeBar();
	
# Handles all input. Called every frame in _physics_process
func getInput():
	## Movement
	if (Input.is_action_pressed("ui_left" + str(PLAYER_NUMBER))):
		rotVel -= ROT_ACC;
	if (Input.is_action_pressed("ui_right" + str(PLAYER_NUMBER))):
		rotVel += ROT_ACC;
	if (Input.is_action_pressed("ui_up" + str(PLAYER_NUMBER))):
		accVec.x = cos(rotation)
		accVec.y = sin(rotation)
		
		accVec = accVec.normalized() * ACC_RATE_OF_CHANGE;
		
	## Shooting
	# Increase cannon charge when holding shoot key
	if (Input.is_action_pressed("ui_shoot" + str(PLAYER_NUMBER))):
		cannonCharge += CANNON_CHARGE_RATE_OF_CHANGE;
	if (Input.is_action_just_released("ui_shoot" + str(PLAYER_NUMBER))):
		if (cannonCharge >= MAX_CANNON_CHARGE):
			shoot();
			cannonCharge = 0;
		
func shoot():
	# Create first cannonball (aiming left), give position and angle
	var cannonball0 = Cannonball.instance();
	cannonball0.position = self.position;
	cannonball0.init(PLAYER_NUMBER, rotation - PI/2)

	# Create second cannonball (aiming right), give position and angle
	var cannonball1 = Cannonball.instance();
	cannonball1.position = self.position;
	cannonball1.init(PLAYER_NUMBER, rotation + PI/2)
	
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
	$DamageSound.playing = true;
	$AnimatedSprite.speed_scale += 1;
	
# Dampens the angular velocity. Called every frame in _physics_process
func dampenRotation():
	# If making rotVel approach zero by the ROT_DAMP_CONSTANT would make it switch signs, then just set it to zero
	if (abs(rotVel - ROT_DAMP_CONSTANT) < ROT_DAMP_CONSTANT):
		rotVel = 0
		return;
	else:
		rotVel -= sign(rotVel) * ROT_DAMP_CONSTANT;
		
# Dampens the linear velocity. Called when not pressing up
func dampenVelocity():
	# Only dampen the velocity if not pressing up. Otherwise, small enough velocities will be completely cancelled out
	if (Input.is_action_pressed("ui_up" + str(PLAYER_NUMBER))):
		return;
	
	# If making VelVec's x approach zero by the VEL_DAMP_CONSTANT would make it switch signs, then just set it to zero
	if (abs(velVec.x - VEL_DAMP_CONSTANT) < VEL_DAMP_CONSTANT):
		velVec.x = 0;
	else:
		velVec.x -= sign(velVec.x) * VEL_DAMP_CONSTANT
		
	# If making VelVec's y approach zero by the VEL_DAMP_CONSTANT would make it switch signs, then just set it to zero
	if (abs(velVec.y - VEL_DAMP_CONSTANT) < VEL_DAMP_CONSTANT):
		velVec.y = 0;
	else:
		velVec.y -= sign(velVec.y) * VEL_DAMP_CONSTANT
		
# Ensures the charge bar stays in the correct location relative to the ship. Called every frame
func manageChargeBar():
	# Set the relative rotation to the inverse of the ship's rotation, thus canceling each other out
	$CannonChargeBar.set_rotation(-1*rotation)
	# Set position to the ship's position, but slightly higher based on the vertical buffer
	$CannonChargeBar.set_global_position(Vector2(
		position.x - ($CannonChargeBar.get_size().x/2), # Position is based on upper left, so subtract half of the width to account for that
		 position.y - cannonChargeBarVerticalBuffer))
