extends Node2D

@onready var dice: Sprite2D = $Dice
@onready var turn_skip_timer: Timer = $"Turn Skip Timer"
@onready var new_turn_timer: Timer = $"New Turn Delay Timer"

#Game Piece Scene that will be used to make all the game pieces
var game_piece_blueprint = preload("res://Scenes/game_piece.tscn")

#Store each team's game pieces in the form of a list
var game_pieces : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	#Connecting to a signal, so we can "listen" when a player's turn ends so we can start the next player's turn
	Global.unit_moved.connect(_on_unit_move)

	#List that will hold every player's score, will receive a zero for each player at the start
	var scores : Array[int]

	#Create each player and give them a score of 0
	for player in Global.players:
		game_pieces[player] = create_game_pieces(player)
		scores.append(0)

	Global.scores = scores
	Global.current_player = Global.players[0]
	Global.is_current_player_ai = Global.is_players_ai[0]
	
	#Change the color of the dice to match the color of the current player
	dice.change_dice_color(Global.current_player)
	
	#Start the first turn
	initiate_new_turn()

#Spawns in the game pieces in their respective spots
func create_game_pieces(game_piece_team : String) -> Array[GamePiece]:

	#Create a list to hold created Game Pieces
	var created_game_pieces : Array[GamePiece]

	#Create 4 copies/instances of a game piece for the defined player
	for i in range(1,5):

		var instance : GamePiece = game_piece_blueprint.instantiate()
		instance.unit_affiliation = game_piece_team
		var spot_node : Spot = get_node('Spots/'+game_piece_team+'_'+str(i))
		instance.respawn_marker = spot_node
		spot_node.connect_game_piece(instance)
		add_child(instance)
		created_game_pieces.append(instance)

	return created_game_pieces

#Allows the dice to be used by the HUMAN player. If AI, rolls the dice for them
func initiate_new_turn():

	#If the current player is AI, then roll the dice automatically
	if Global.is_current_player_ai:
		dice.roll_dice()

	#If the current player is HUMAN, allow them to roll the dice themselves
	else:
		Global.is_dice_clickable = true

#Signal receiver. Checks if a turn should be repeated. If not, transitions to the next player
func _on_unit_move(is_repeating_turn : bool, moved_tiles : int) -> void:

	#If the user has moved all their units to the finish, open up a win screen for them
	if Global.scores[0] == 4:
		var win_window = load("res://Scenes/end_screen.tscn").instantiate()
		add_child(win_window)
		Global.is_dice_clickable = false
		return

	#If they do NOT qualify for a repeat turn, then swap information to the next player
	if not is_repeating_turn:
		await transition_turns()
		pass

	#Determines whether the next player is AI - used for determining dice roll delay
	var is_ai_moving_next : bool = (Global.is_current_player_ai and is_repeating_turn) or (Global.is_players_ai[1] and not is_repeating_turn)

	#Conditional timer delay: determines how long timer should be. 
	# > If HUMAN, the delay only needs to be up until their unit finishes moving.
	# > If AI, the delay needs to account for their unit moving and a bit after to process what's going on
	var timer_seconds : float = (0.03 * moved_tiles + 1.5) if is_ai_moving_next else (0.2 * moved_tiles * 0.9)

	#Start a timer that starts a new turn on timeout
	new_turn_timer.start(timer_seconds)

func _delay_new_turn() -> void:
	initiate_new_turn()

#Changes current player to the next player
func transition_turns() -> void:
	#Moves current player to the back of the line
	Global.players.append(Global.players.pop_front())
	Global.is_players_ai.append(Global.is_players_ai.pop_front())
	Global.scores.append(Global.scores.pop_front())
	
	#Makes it so game knows who the current player is and if theyre AI or HUMAN
	Global.current_player = Global.players[0]
	Global.is_current_player_ai = Global.is_players_ai[0]
	
	#Change the color of the dice to match the color of the current player
	dice.change_dice_color(Global.current_player)

#Creates a list of Forecasts for every unit
#A forecast of a unit is information about what is at the tile dice_roll spaces away
#i.e. A roll of 4 = check 4 tiles from a game piece. If theres a unit, returns a 2, etc
func forecast_all_units(is_AIs_turn : bool = false) -> Array[int]:

	var forecasts : Array[int]
	var forecast : int

	#Generates a forecast of all player's units. Also determines if they can move their unit
	for game_piece : GamePiece in game_pieces[Global.current_player]:
		forecast = game_piece.forecast_path(is_AIs_turn)
		game_piece.is_movable = forecast != 0
		forecasts.append(forecast)

	return forecasts

#When the dice is rolled (by either AI or a human player)
func _on_dice_roll() -> void:
	#Create a forecast - which generates information for both HUMAN and AI
	# >For human & AI, determines if they can play a move with the dice roll they were given
	# >Additionally for AI, it ranks the quality of any moves it can play 
	#  i.e. moving unit-2 eats another player so do that
	var forecast : Array[int] = forecast_all_units(Global.is_current_player_ai)

	#If the player has ZERO playable moves, then skip their turn
	if forecast.max() == 0:
		turn_skip_timer.start()
		return

	#If the player is AI, do their turn for them using the provided forecast as guidance
	if Global.is_current_player_ai:
		var unit_index_to_move : int = forecast.find(forecast.max())
		game_pieces[Global.current_player][unit_index_to_move].move_piece_accordingly()

	#If the player is human, allow them to move their game piece for them
	else:
		Global.is_unit_clickable = true

#When Turn-Skip timer goes off, transition to the next player's turn
func _delay_turn_skip() -> void:
	await transition_turns()
	initiate_new_turn()
