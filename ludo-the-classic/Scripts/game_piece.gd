extends Node
class_name GamePiece

@export var respawn_marker: Spot
@export var unit_affiliation : String = 'gray'

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var button: Button = $Button
@onready var timer: Timer = $"Movement Timer"

var connected_marker: Spot
var is_on_board : bool = false
var is_movable : bool = false

func _ready() -> void:
	#Change the unit to whatever color its affiliated with
	animation_player.play(unit_affiliation)

	#The current marker its at, is obviously gonna be the marker it spawned in
	connected_marker = respawn_marker

	#Move it to where its supposed to go
	self.position = connected_marker.position

#Checks to see if a HUMAN player's attempt to move a unit is allowed and moves it if it can
func _on_button_pressed() -> void:

	#Preliminary Check, basically check 
	# >if the unit should even be able to be moved (if its in the unit-move phase) OR
	# >if the unit belongs to the player trying to move it
	# >if the forecast determined if it can't move
	if (Global.is_unit_clickable == false or 
		unit_affiliation != Global.current_player or
		not is_movable):
		return

	#Disables the ability to run this method again so player doesn't spam it
	Global.is_unit_clickable = false

	move_piece_accordingly()

#Determine how a piece will be treated, depending on whether its on the board or not
func move_piece_accordingly() -> void:
	#If the unit is NOT on the board, move it once onto the board
	if not is_on_board:
		is_on_board = true
		move_game_piece(1)

	#If it is on the board, move it its deserved amount of spaces
	else:
		move_game_piece()

#Moves the game piece
func move_game_piece(tiles_to_move : int = Global.dice_roll_value) -> void:
	
	Global.spaces_to_move = tiles_to_move
	
	#Remove it from the list of game_units at the spot
	connected_marker.disconnect_game_piece(self)
	
	#Create a tween to move the unit around
	var tween = create_tween()

	#Move the unit roll_value amount of times
	for i in range(tiles_to_move):

		#Unless the unit has reached the end, move it
		if connected_marker.tile_type != Tile.TileType.END:
			#Checks to see what the [next tile] is and stores it as the [now-current tile]
			connected_marker = connected_marker.get_next_point(unit_affiliation)

			#Move over to the new current tile
			tween.tween_property(self, "position", connected_marker.position, 0.2)

		#If the unit has reached the end, leave it be
		else:
			print('Fail safe played! Some naughty player is trying to move beyond the end...')

	#Make sure the spot/marker knows that the unit is there
	connected_marker.connect_game_piece(self)

	#If the unit reached its destination, give a point
	if connected_marker.tile_type == Tile.TileType.END:
		Global.scores[0] += 1

	#After movement, check if dying should occur
	connected_marker.check_if_die(unit_affiliation)

	check_if_swap(tiles_to_move)

#Checks if player should have an additional turn after their move
#Future ROG: IDK why this is here and not in the main scene...
func check_if_swap(moved_tiles :int):

	#If either they didn't roll a 6, or rolled too many, then transition to next player
	if Global.dice_roll_value != 6 or Global.player_turn_counter > 3:
		#Reverts the repeat counter before transitioning
		Global.player_turn_counter = 1

		#Tells main that a unit has moved and will not repeat their turn
		Global.emit_signal("unit_moved", false, moved_tiles)
		return

	#Track the fact that the current player repeated their turn
	Global.player_turn_counter += 1

	Global.emit_signal("unit_moved", true, moved_tiles)

#Removes game piece from board back to its respawn point
func die() -> void:
	#Disconnect the game piece from its pre-death tile
	connected_marker.disconnect_game_piece(self)
	
	#Make the new spot, its normal respawn point
	connected_marker = respawn_marker

	#Create a tween to move the unit around
	var tween = create_tween()
	
	#Move it to its respawn point
	tween.tween_property(self, "position", connected_marker.position, 1)
	
	#It is set to inactive and needs a roll of a 6 to move
	is_on_board = false

#Forecast what's ahead of the unit. Used by HUMANS and AI
# > HUMANS & AI use it to determine if their turn should be skipped if a move cannot be made
# > AI specifically uses it to determine which unit it should move depending on what's ahead
func forecast_path(is_AIs_turn : bool = false) -> int:

	#If its not on the board, it should be priority to get it on the board
	if is_on_board == false and Global.dice_roll_value == 6:
		return 4
	elif is_on_board == false:
		return 0

	#Basically for keeping track of the upcoming markers, starting with the current connected marker
	var checked_tile : Spot = connected_marker

	#Checking to see if this unit can even move dice_roll amount of times
	#Using checked_tile as a means to keep track of the current Spot/Marker we're accessing
	for i in range(Global.dice_roll_value):

		#If the penultimate spot is END, that means we can't fully move dice_roll amount of spaces
		#Thus we return 0 to signify no movement can be made
		#i.e. If we have a roll of 5, but 4 spaces ahead is the end, then means we can't move 5
		if checked_tile.tile_type == Tile.TileType.END:
			return 0

		#If the unit is destined to take the normal path, take it
		if checked_tile.alt_tile_affiliation != unit_affiliation:
			checked_tile = checked_tile.next_tile

		#If the unit is destined to take the alternate path in the fork, take it
		else:
			checked_tile = checked_tile.alt_tile

	#If this is not for AI purposes, then we got info we needed. This space CAN be moved
	if not is_AIs_turn:
		return 1

	#Checking to see if theres any enemies of the AI within that dice_roll space
	for unit_in_spot in checked_tile.connected_game_pieces:
		if unit_affiliation != unit_in_spot.unit_affiliation:
			return 3

	#If the tile leads to the end, it should be higher priority than a normal move
	if checked_tile.tile_type == Tile.TileType.END:
		return 2

	#If its a normal move, then its the lowest priority, but at least a move the AI can do
	return 1
