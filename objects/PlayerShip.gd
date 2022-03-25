extends KinematicBody2D

## Constants
# Movement constants
export (float) var rotDampConstant; # Dampening constant of the rotation
export (float) var rotAcc; # Angular Acceleration
export (float) var velDampConstant; # Dampening constant of the linear velocity
export (int) var maxRotSpeed; # Maximum rotation speed
export (int) var accRateOfChange; # Rate at which linear acceleration increases
export (int) var maxSpeed; # Maximum linear speed

# Other constants
export (int) var health; # HP of the player, number set in inspector is starting health
export (int) var playerNumber; # Player ID

# Declare member variables here.
var velVec = Vector2(); # Velocity Vector
var accVec = Vector2(); # Acceleration Vector
var rotVel = 0; # Angular velocity

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite.animation = "player" + str(playerNumber) + "Default";
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Kill player if health reaches 0
	if (health < 0):
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
	velVec = move_and_slide(velVec);
	
	dampenRotation();
	dampenVelocity();
	
# Handles all input. Called every frame in _physics_process
func getMovementInput():
	if (Input.is_action_pressed("ui_left" + str(playerNumber))):
		rotVel -= rotAcc;
	if (Input.is_action_pressed("ui_right" + str(playerNumber))):
		rotVel += rotAcc;
	if (Input.is_action_pressed("ui_up" + str(playerNumber))):
		accVec.x = cos(rotation)
		accVec.y = sin(rotation)
		
		accVec = accVec.normalized() * accRateOfChange;
		
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
