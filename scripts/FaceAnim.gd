extends Sprite2D

@export var amplitude = 2.5  # Maximum distance the sprite will move up or down
@export var speed = 0.5 # Speed of the motion

var base_y = 0.0  # Original Y position of the sprite
var time_elapsed = 0.0  # Tracks elapsed time
var hold_timer = 0.0  # Tracks the hold time at peaks
var prev_wave = 0.0

func _ready():
	# Store the original Y position
	base_y = position.y

func _process(delta):
	# Increment elapsed time
	time_elapsed += delta * speed
	
	# Calculate normalized sine value (-1 to 1)
	var wave = sin(time_elapsed * PI * 2)

	# Update the Y position using the sine wave
	position.y = base_y + wave * amplitude
