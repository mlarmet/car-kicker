extends Node3D

signal boost_take(vehicle : VehicleBody3D)

var rotation_speed: float = 2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Rotate the text
	$BoostPadText.rotate_y(rotation_speed * delta)
	# Rotate the duplicate collision
	$BoostPadCollisionRotate.rotate_y(rotation_speed * delta)
# =================================================================

func _on_body_entered(body):
	if is_visible() and body.is_in_group("vehicle"):
		emit_signal("boost_take", body)
# =================================================================
