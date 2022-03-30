extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect button signals
	$BackButton.connect("button_up", self, "_on_BackButton_button_up")

# Called when the BackButton is pressed
func _on_BackButton_button_up():
	get_tree().change_scene("res://rooms/MainMenu.tscn")
