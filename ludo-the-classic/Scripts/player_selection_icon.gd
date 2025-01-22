extends Node2D
@export var game_piece_color : String
@export var player_type_id : int = 0

@onready var game_selection: Node2D = $".."
@onready var player_icon: Sprite2D = $Sprite2D

func _ready() -> void:
	if player_type_id == 1:
		player_icon.texture = game_selection.HUMAN_ICON

func _on_button_pressed() -> void:
	#If they don't have a player type, set it to HUMAN
	if player_type_id == 0:
		player_icon.texture = game_selection.HUMAN_ICON
		player_type_id = 1
	
	#If their player type is HUMAN, set it to AI
	elif player_type_id == 1:
		player_icon.texture = game_selection.AI_ICON
		player_type_id = 2
		
	#If their player type is AI, then remove it
	else:
		player_icon.texture = game_selection.NULL_ICON
		player_type_id = 0
