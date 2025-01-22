extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

var current_team: String = 'gray'

#Loads in other colors of dice that exist
var dice_colors : Dictionary = { 
	"red": preload("res://Assets/dice/red_dice.png"), 
	"orange": preload("res://Assets/dice/orange_dice.png"), 
	"green": preload("res://Assets/dice/green_dice.png"), 
	"purple": preload("res://Assets/dice/purple_dice.png") 
}

signal dice_has_rolled

func _ready() -> void:
	#Randomizes the seed so dice roll is really random xd
	randomize()

#If the button is pressed, rolls the dice once
func _on_button_pressed() -> void:
	if Global.is_dice_clickable:

		#Make it so dice can't be rolled again
		Global.is_dice_clickable = false
		roll_dice()

func roll_dice() -> void:
	#Plays the dice roll animation
	animation_player.play("roll")

	#Starts a timer with the duration of the dice roll animation
	timer.start()

#When the timer (that is proced by a click) finishes its time...
func _on_timer_timeout() -> void:
	
	#...then create a random dice roll with a value from 1 to 6 
	Global.dice_roll_value = randi_range(1,6)
	
	#Change the spite to display the dice roll using animations
	animation_player.play(str(Global.dice_roll_value))

	#If its a human's turn, allow him to move the unit himself
	if not Global.is_current_player_ai:
		Global.is_unit_clickable = true
	emit_signal("dice_has_rolled")

func change_dice_color(color_id : String):
	#Changes the color to whatever is in the dice_color index
	# 0 = red dice texture
	# 1 = orange dice texture
	# 2 = green dice texture
	# 3 = purple dice texture
	self.texture = dice_colors[color_id]

	#Changes it to the default dice sprite
	animation_player.play("Default")
