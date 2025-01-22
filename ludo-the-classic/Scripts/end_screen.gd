extends Node2D

@onready var window: Sprite2D = $WinnerScreen
@onready var player_color: Sprite2D = $PlayerColor
@onready var label: Label = $"Player _ WINS"
@onready var exit_button: Button = $ExitButton

func _ready() -> void:
	#Will be used to store the color of the winning player
	var color : Color

	#Store the color of the winning player
	match Global.current_player:
		"red":
			color = Color(0.35, 0.0, 0.0)
		"orange":
			color = Color(0.6, 0.33, 0.12)
		"green":
			color = Color(0.0, 0.35, 0.0)
		"purple":
			color = Color(0.27, 0.0, 0.37)

	#Tint the window to the winning player's color
	window.modulate = color

	#Adds the name of the color to the scene in its own color
	player_color.texture = load(("res://Assets/End Screen/"+Global.current_player+".png"))

#Exits the game if the player presses Exit
func _on_exit_pressed() -> void:
	get_tree().quit()

#Starts the game over if the player pressed Play Again
func _on_play_again_press() -> void:
	get_tree().change_scene_to_file("res://Scenes/game_selection.tscn")
