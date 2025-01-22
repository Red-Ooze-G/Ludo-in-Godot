extends Node2D

const HUMAN_ICON : Texture = preload("res://Assets/Game Selection/human_icon.png")
const AI_ICON : Texture  = preload("res://Assets/Game Selection/ai_icon.png")
const NULL_ICON = preload("res://Assets/Game Selection/null_icon.png")

@onready var player_icons : Array[Node2D] = [$"Player 1 Icon",$"Player 2 Icon",$"Player 3 Icon",$"Player 4 Icon"]

@onready var start: Button = $START
@onready var nag_window: PanelContainer = $"NAG Window"

func _on_start_pressed() -> void:

	var players : Array[String]
	var is_players_ai : Array[bool]
	var player_count : int = 0

	#Checks every potential player and adds them to the game if specified
	for player in player_icons:
		if player.player_type_id != 0:
			players.append(player.game_piece_color)
			is_players_ai.append(true if player.player_type_id == 2 else false)
			player_count += 1

	#If there's at least two players, allow the game to commence
	if player_count >= 2:
		#Keep the player preferences on hand
		Global.players = players
		Global.is_players_ai = is_players_ai

		#Swap to the actual board game, lets get gamin'!!
		get_tree().change_scene_to_file("res://Scenes/first_map.tscn")

	#If there isn't at least two players, open up the nagging window to make them select 2 players!
	else:
		nag_window.visible = true
