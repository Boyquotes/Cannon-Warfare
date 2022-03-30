extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect button signals
	$PlayButton.connect("button_up", self, "_on_PlayButton_button_up")
	$QuitButton.connect("button_up", self, "_on_QuitButton_button_up")

# Called when the PlayButton is pressed
func _on_PlayButton_button_up():
	get_tree().change_scene("res://rooms/ArenaRoom.tscn")
	
# Called when the QuitButton is pressed
func _on_QuitButton_button_up():
	get_tree().quit()
