extends Marker2D
class_name Spot

@export var tile_type = Tile.TileType.NORMAL
@export var next_tile: Spot
@export var alt_tile: Spot
@export var alt_tile_affiliation: String
var connected_game_pieces : Array[GamePiece]
@onready var timer: Timer = $Timer

#Store any incoming game pieces in this spot
func connect_game_piece(game_piece : GamePiece) -> void:
	connected_game_pieces.append(game_piece)
	timer.start( (Global.spaces_to_move * .2) + 0.1 )

#Removes any game pieces that left this spot
func disconnect_game_piece(game_piece : GamePiece) -> void:
	connected_game_pieces.remove_at(connected_game_pieces.find(game_piece))
	timer.start( 0.1 )

#Gets the next point in the game piece's path
func get_next_point(game_piece_affiliation : String) -> Spot:
	
	#If this spot has a unit_color alternate path, then go to it if it matches the unit
	if game_piece_affiliation == alt_tile_affiliation:
		return alt_tile
		
	#Otherwise, just take the normal / possible only path
	return next_tile

#Silly name, but basically if the unit is occupied by a unit of a different team, kill it off
func check_if_die(attacker_affiliation : String) -> void:
	
	#If the tile is SAFE, then don't kill any units
	if tile_type == Tile.TileType.SAFE:
		return
	
	#Compare the affiliation of the incoming game piece (i.e. attacker) against every other game piece in this spot
	for game_piece in connected_game_pieces:
		
		#If its a different team/color, then kill it off
		if attacker_affiliation != game_piece.unit_affiliation:
			game_piece.die()

func shrink_game_pieces() -> void:
	#doesnt need to run IF only 1 game piece
	var num_of_game_pieces : int = connected_game_pieces.size()
	
	#Stores the radius of the tile
	var x_radius = 30
	var y_radius = 30
	
	#Determines how far times the radius the game piece should be located relative to the Spot
	var offsets = [.8, .5, .25, .35, .5]
	
	#Stores whether the game piece should be up/down from the spot (pos=up, neg=down)
	var x_sign = 1
	#Stores whether the game piece should be left/right from the spot (pos=right, neg=left)
	var y_sign = 1
	
	#Stores how far from the middle, the game piece should move toward the left/right
	var x_offset_distance
	
	#Stores the x & y positions of where the game piece should move
	var y
	var x
	
	#Stores the max amount of rows the Spot has
	var x_grid = ceil( (num_of_game_pieces / 2.0))
	
	#Stores whether or not the Top/Bottom has an odd-number amount of rows
	var is_top_odd = (int(floor(num_of_game_pieces / 2.0)) % 2) == 1
	var is_bottom_odd = (int(ceil(num_of_game_pieces / 2.0)) % 2) == 1

	#X-offset multipler and also helps tracks whether the next game piece should be left/right
	var x_mult :float = .25

	for game_piece in connected_game_pieces:
		
		#Every 2 game pieces go to the top row of the tile, and the others go to the bottom row
		y = self.position.y + (y_radius * .5 * y_sign)
		game_piece.position.y = y
		
		#If the top or bottom have an odd-number of rows, then the offset should be different
		if (is_bottom_odd and y_sign > 0) or (is_top_odd and y_sign < 0):
			x_offset_distance = offsets[x_grid -2]
		else:
			x_offset_distance = offsets[x_grid-1]

		#This basically changes this sign for the x multipler every 2 runs
		if x_mult == ((ceil(x_mult) + floor(x_mult)) / 2.0):
			x_sign *= -1

		#Determining what the game piece's x position should be...
		x = self.position.x + (ceil(x_mult) * x_sign * x_offset_distance * x_radius)

		#...and setting it to what it should be here
		game_piece.position.x = x

		#Alternate the up/down position to be down/up 
		y_sign *= -1
		
		#Slowly increases the x-offset multipler (also determines when X-offset should be right/left)
		x_mult += .25

	#If the bottom has an odd numbered amount of rows, then one of them needs to be centered
	if is_bottom_odd:
		connected_game_pieces[-1].position.x = self.position.x
	#If the top has an odd numbered amount of rows, then one of them needs to be centered
	if is_top_odd:
		connected_game_pieces[-2].position.x = self.position.x

#Changes position of the game piece so multiple can occupy the same space
func _on_timeout() -> void:
	if connected_game_pieces.size() > 1:
		shrink_game_pieces()
	elif connected_game_pieces.size() == 1:
		connected_game_pieces[0].position = self.position
