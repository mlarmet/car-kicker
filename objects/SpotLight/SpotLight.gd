extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Global.change_night_mode.connect(toggle_lights)
# =================================================================

func toggle_lights(is_night: bool):
	if is_night:
		$Lights.show()
	else:
		$Lights.hide()
# =================================================================
