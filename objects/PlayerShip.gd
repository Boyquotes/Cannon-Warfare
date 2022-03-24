extends KinematicBody2D

export (float) var rotDamp; # Dampening constant of the rotation
export (float) var rotAcc; # Angular Acceleration
export (int) var maxRotSpeed; # Maximum rotation speed

# Declare member variables here.
var velVec = Vector2(); # Velocity Vector
var accVec = Vector2(); # Acceleration Vector
var rotVel = 0; # Angular velocity

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	getMovementInput();
	
	# Ensure rotation velocity magnitude doesn't exceed maximum speed
	if (abs(rotVel) > maxRotSpeed):
		if (rotVel < 0):
			rotVel = maxRotSpeed * -1;
		else:
			rotVel = maxRotSpeed;
			
	# Update rotation
	rotation += rotVel * delta;
	dampenRotation();
	
# Called every frame in _physics_process. Handles all input
func getMovementInput():
	if (Input.is_action_pressed("ui_left")):
		rotVel -= rotAcc;
	if (Input.is_action_pressed("ui_right")):
		rotVel += rotAcc;
	if Input.is_action_pressed("ui_up"):
		velVec.x += 1
		
# Called every frame in _physics_process. Dampens the angular velocity
func dampenRotation():
	if (abs(rotVel - rotDamp) < rotDamp):
		rotVel = 0
		return;
	elif (rotVel > 0):
		rotVel -= rotDamp;
		return;
	elif (rotVel < 0):
		rotVel += rotDamp;
		return;
