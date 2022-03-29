extends Node

export (PackedScene) var Player
export (PackedScene) var Rock

## Constants
export (Vector2) var WINDOW_DIMENSIONS; # Holds the dimensions of the window. (NOT the dimensions of the visible section, since there's camera zoom)
export (int) var NUMBER_OF_PLAYERS; # Holds the number of players to spawn and manage
export (int) var NUMBER_OF_OBSTACLES; # Holds the number of obstacles to spawn and manage

## Variables
var bottomOfScreen; # Holds the coordinates of the bottom end of visibility
var rightSideOfScreen; # Holds the coordinates of the right end of visibility

var horizontalSpawnLimit; # Holds how far, horizontally, something can attempt to be spawned
var verticalSpawnLimit; # Holds how far, vertically, something can attempt to be spawned

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the coordinates of the end of camera visibility
	var zoom = $Camera2D.get_zoom();
	bottomOfScreen = WINDOW_DIMENSIONS.y * zoom.y;
	rightSideOfScreen = WINDOW_DIMENSIONS.x * zoom.x;
	
	# Set the limits of where we can attempt to spawn obstacles or players (where borders start to appear)
	horizontalSpawnLimit = rightSideOfScreen - $WallTileMap.get_cell_size().x;
	verticalSpawnLimit = bottomOfScreen - $Credits.get_size().y - $WallTileMap.get_cell_size().y;
	
	# Spawn all obstacles
	var rng = RandomNumberGenerator.new()
	rng.randomize();
	for i in NUMBER_OF_OBSTACLES:
		# Create a random rock between the borders, with a random position and rotation
		var rock = Rock.instance();
		rock.position = getRandomValidPosition(rng, 16)
		rock.rotation = deg2rad(rng.randi_range(0, 360))
	
		# Add the rock to the tree.
		self.add_child(rock);


	# Spawn all players
	for i in NUMBER_OF_PLAYERS:
		# Create a random player between the borders, with a random position and rotation
		var player = Player.instance();
		player.position = getRandomValidPosition(rng);
		player.rotation = deg2rad(rng.randi_range(0, 360))
			
		# Give the player its ID, or Player Number
		player.init(i + 1);
	
		# Add the player to the tree. Must do this now to check for collisions 
		self.add_child(player);
		
		# Keep resetting the player's position until it is no longer colliding
		while (player.move_and_collide(Vector2(0,0))):
			player.position = getRandomValidPosition(rng);

# Returns a random position between the borders
# rng=RandomNumberGenerator to use, buffer=Optional additional buffer to use, to increase the minimum distance from the borders
func getRandomValidPosition(rng, buffer=0):
	return Vector2(
			rng.randi_range($WallTileMap.get_cell_size().x + buffer, horizontalSpawnLimit - buffer),
			rng.randi_range($WallTileMap.get_cell_size().y + buffer, verticalSpawnLimit - buffer));
