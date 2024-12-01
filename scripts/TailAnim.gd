extends Sprite2D

var amplitude = 3  # Maximum distance the sprite will move up or down
var speed = 0.4 # Speed of the motion

var base_x = 0.0
var time_elapsed = 0.0  # Tracks elapsed time
var hold_timer = 0.0  # Tracks the hold time at peaks

func _ready():
	# Store the original Y position
	base_x = position.x

func _process(delta):
	# Increment elapsed time
	time_elapsed += delta * speed
	
	# Calculate normalized sine value (-1 to 1)
	var wave = sin(time_elapsed * PI * 2)

	# Update the Y position using the sine wave
	position.x = base_x + wave * amplitude
