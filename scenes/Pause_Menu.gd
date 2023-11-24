extends Control

var ready_to_resume: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
# =================================================================

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Used to prevent paused action to be directly unpaused
	if Input.is_action_just_released("paused"):
		ready_to_resume = true
		
	if Input.is_action_just_pressed("paused") and ready_to_resume:
		resume()
# =================================================================

func resume():
	ready_to_resume = false
	hide()
	get_tree().paused = false
# =================================================================
	
func _on_resume_btn_pressed():
	resume()
# =================================================================

func _on_quit_btn_pressed():
	# Reset paused to false
	resume()
	# Go back to main menu
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
# =================================================================
