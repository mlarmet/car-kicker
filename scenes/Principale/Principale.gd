extends Node3D

const BALL_INIT_POSITION: Vector3 = Vector3(0, 1, 0)

const LEFT_VEHICLE_INIT_POSITION: Vector3 = Vector3(-27.5, 0.8, 0)
const RIGHT_VEHICLE_INIT_POSITION: Vector3 = Vector3(27.5,0.8,0)

var vehicle_left: VehicleBody3D
var vehicle_right: VehicleBody3D

var count_down: float = Global.start_timeout

# Objects
@onready var ball: RigidBody3D = $Objects/Ball
@onready var boost_pad_container: Node3D = $Objects/BoostPads

# Timers
@onready var start_timeout_timer: Timer = %StartTimeoutTimer
@onready var goal_timeout_timer: Timer = %GoalTimeoutTimer

@onready var boost_pad_duration_timer: Timer = %BoostPadDurationTimer
@onready var boost_pad_timeout_timer: Timer = %BoostPadTimeoutTimer

# Sounds
@onready var goal_sound: AudioStreamPlayer = $Audios/GoalSound
@onready var count_down_sound: AudioStreamPlayer = $Audios/CountDownSound
@onready var bonus_take_sound: AudioStreamPlayer = $Audios/BonusTakeSound

# Called when the node enters the scene tree for the first time.
func _ready():
	$IHM/Infos/Options/NightLabel/NightCheckBox.button_pressed = Global.is_night
	_on_night_check_box_toggled(Global.is_night)
	
	# Connect goal signal to add point and reset position
	$Objects/Goals/GoalLeft.goal_detect.connect(handle_goal_detect)
	$Objects/Goals/GoalRight.goal_detect.connect(handle_goal_detect)
	
	for boost_pad in boost_pad_container.get_children():
		boost_pad.boost_take.connect(handle_boost_take)
	
	$IHM/Pause_Menu.hide()
	%StartCountDown.hide()
	
	goal_timeout_timer.connect("timeout", prepare_game)
	start_timeout_timer.connect("timeout", start_game)
	
	boost_pad_duration_timer.connect("timeout", reset_boost_pad)
	boost_pad_timeout_timer.connect("timeout", show_boost_pad)
	
	set_is_split_screen()
	
	prepare_game()
# =================================================================

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Global.is_split:
		for vehicle in [vehicle_left, vehicle_right]:
			var cam = vehicle.get_node("Camera/ThirdViewBall")
			
			# Cam track ball like Rocket League 
			cam.global_position = (vehicle.position + vehicle.position.direction_to(ball.position).normalized() * Vector3(-10,0,-10))
			cam.position.y = 5
			
			cam.global_position.lerp(ball.global_position, 0.1)
			
			cam.look_at(ball.global_position, Vector3.UP)
	
	# Count timer only if not scored
	if goal_timeout_timer.is_stopped() and start_timeout_timer.is_stopped():
		Global.temps += delta
	
		var minutes = int(Global.temps / 60.0)
		var secondes = int(Global.temps) % 60
	
		$IHM/Infos/Score/Timer.text = str(minutes).pad_zeros(2) + ":" + str(secondes).pad_zeros(2)
	
	if Input.is_action_just_pressed("paused"):
		$IHM/Pause_Menu.show()
		get_tree().paused = true
		
	if !start_timeout_timer.is_stopped():
		%StartCountDown.show()
		
		count_down -= delta
		
		var text = ""
		if count_down < 0.5:
			text = "Go !"
		else:
			text = str("%.0f" % count_down)
		
		%StartCountDown.text = text
# =================================================================

func _on_night_check_box_toggled(button_pressed):
	Global.is_night = button_pressed
	
	Global.change_night_mode.emit(Global.is_night)
	
	if Global.is_night:
		$NightNode.show()
		$LightNode.hide()
	else:
		$NightNode.hide()
		$LightNode.show()
# =================================================================

func handle_goal_detect(side: String):
	if side == "left":
		Global.score_right += 1
		%ScoreRight.text = str(Global.score_right)
	else:
		Global.score_left += 1
		%ScoreLeft.text = str(Global.score_left)
	scored_actions()
# =================================================================

func handle_boost_take(vehicle: VehicleBody3D):
	hide_boost_pad()
	
	vehicle.boost = Global.boost_max
	vehicle.set_boost_text()
	
	bonus_take_sound.play()
# =================================================================

func scored_actions():
	# Stop Ball
	ball.angular_velocity = Vector3.ZERO
	ball.linear_velocity = Vector3.ZERO
	
	# Remove grativy to disabled collision without object falling
	ball.gravity_scale = 0.0
	# Disabled Ball Collision
	ball.get_node("BallCollision").set_deferred("disabled", true)
	
	ball.hide()
	
	# Set CameraCar current to true
	for vehicle in [vehicle_left, vehicle_right]:
		if Global.is_split:
			vehicle.get_node("Camera/ThirdViewBall").current = true

			vehicle.get_node("Camera/ThirdViewCar").current = false
			vehicle.get_node("Camera/FirstView").current = false
	
	# Play Goal Sound
	goal_sound.play()
	
	# Start Goal Timeout
	goal_timeout_timer.start(Global.goal_timeout)
# =================================================================

func reset_positions():
	ball.global_position = BALL_INIT_POSITION
	
	# Stop Ball
	ball.angular_velocity = Vector3.ZERO
	ball.linear_velocity = Vector3.ZERO
	
	# Reset Ball Gravity to one time of default
	ball.gravity_scale = 1.0
	# Reactivated Ball Collsion
	ball.get_node("BallCollision").set_deferred("disabled", false)
	
	ball.show()
	
	# Reset Vehicle properties
	vehicle_left.reset()
	vehicle_right.reset()
	
	# Set Left Vehicle position
	vehicle_left.global_position = LEFT_VEHICLE_INIT_POSITION
	
	# Set Vehicle position
	vehicle_right.rotation.y = deg_to_rad(180)
	vehicle_right.global_position = RIGHT_VEHICLE_INIT_POSITION
# =================================================================

func prepare_game():
	# Reset all objects positions
	reset_positions()
	
	# Stop Goal Timeout
	goal_timeout_timer.stop()
	Global.ready_to_play = false
	
	# Play Count Down sound
	if !count_down_sound.playing:
		count_down_sound.play()
		
	hide_boost_pad()
	
	boost_pad_duration_timer.stop()
	boost_pad_timeout_timer.stop()
	
	# Start Count Down Timeout
	start_timeout_timer.start(Global.start_timeout)
# =================================================================

func start_game():
	Global.ready_to_play = true
	start_timeout_timer.stop()
	
	boost_pad_timeout_timer.start(Global.boost_pad_timeout)
	
	%StartCountDown.hide()
	count_down = Global.start_timeout
# =================================================================

func set_is_split_screen():
	if Global.is_split:
		$Vehicles.free()
		$Camera3D.free()
		
		vehicle_left = $IHM/SplitScreen/GridContainer/SubViewportContainer/SubViewport/VehicleLeft
		vehicle_right = $IHM/SplitScreen/GridContainer/SubViewportContainer2/SubViewport/VehicleRight
	else:
		$IHM/SplitScreen.free()
		$Camera3D.current = true
		
		vehicle_left = $Vehicles/VehicleLeft
		vehicle_right = $Vehicles/VehicleRight
# =================================================================

func hide_boost_pad():
	for boost_pad in boost_pad_container.get_children():
		boost_pad.hide()
# =================================================================

func show_boost_pad():
	var random_pad_number : int = randi() % 2 + 1
	
	var boost_pad = boost_pad_container.get_node("BoostPad_" + str(random_pad_number))
	boost_pad.show()
	
	boost_pad_timeout_timer.stop()
	boost_pad_duration_timer.start(Global.boost_pad_duration)
# =================================================================

func reset_boost_pad():
	hide_boost_pad()
	
	boost_pad_duration_timer.stop()
	boost_pad_timeout_timer.start(Global.boost_pad_timeout)
# =================================================================

