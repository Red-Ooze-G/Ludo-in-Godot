extends Node

var players : Array[String]
var is_players_ai : Array[bool]

var current_player : String = 'red'
var is_current_player_ai : bool = false
var is_unit_clickable : bool = false
var is_dice_clickable : bool = true
var dice_roll_value : int = 2

#same thing as dice roll but accounts for moving on board being 1 instead of 6
var spaces_to_move : int = 2

var is_ai_next_player : bool = false

var player_turn_counter : int = 1

signal unit_moved(is_repeating_turn : bool)

var scores : Array[int]
