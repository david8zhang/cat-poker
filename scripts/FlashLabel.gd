extends RichTextLabel

var flash_speed = 1.0  # Time for a full fade cycle
var time = 0.0  # Track elapsed time

func _process(delta):
	time += delta
	# Calculate alpha as a sine wave for smooth fading
	var alpha = (sin(time * PI * 2 / flash_speed) + 1) / 2
	modulate.a = alpha  # Adjust opacity (alpha) of the label
