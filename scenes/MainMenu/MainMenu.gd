extends Control

func _on_above_cam_button_trigger_pressed():
	Global.is_split = false
	start()
# =================================================================

func _on_split_screen_button_trigger_pressed():
	Global.is_split = true
	start()
# =================================================================
	
func start():
	Global.temps = 0
	
	get_tree().change_scene_to_file("res://scenes/Principale/Principale.tscn")
# =================================================================
