extends VehicleBody3D

const STEER_SPEED: float = 2.0
const STEER_LIMIT: float = 0.7

const BOOST_VALUE: float = 400.0 
const DEFAULT_ENGINE_FORCE: float = 400.0

enum camera_position_list {FIRST, THIRD_BALL, THIRD_CAR}
var camera_position : camera_position_list = camera_position_list.THIRD_BALL

enum player_type {FIRST, SECOND}
@export var player: player_type = player_type.FIRST

@export var engine_force_value: float = DEFAULT_ENGINE_FORCE

@onready var boost_particles: GPUParticles3D = $Particles/Boost

@onready var lbl_vitesse: Label = %LblVitesse
@onready var lbl_marche: Label = %LblMarche
@onready var lbl_boost: Label = %LblBoost

@onready var boost_sound: AudioStreamPlayer = $Audios/BoostSound

# If player is the second, all variable will be complete with "_2" to differenciate vehicle control
var extra: String = ""

var color_hex = Global.first_player_color 

var front_action: String = "accelerate"
var back_action: String = "brake"
var left_action: String = "steer_left"
var right_action: String = "steer_right"
var reset_action: String = "reset"
var boost_action: String = "boost"
var change_cam_action: String = "change_camera"

var boost: float = Global.boost_max

# Called when the node enters the scene tree for the first time.
func _ready():
	set_camera_current()

	Global.change_night_mode.connect(toggle_lights)
	
	if player == player_type.SECOND:
		extra = "_2"
		lbl_vitesse = %LblVitesse_2
		lbl_marche = %LblMarche_2
		lbl_boost = %LblBoost_2
		
		color_hex = Global.second_player_color

	$NightNode/RearLights.hide()
	
	boost_particles.set_emitting(false)
	
	set_boost_text()
	
	set_vehicle_color()
# =================================================================

func _physics_process(delta):
	var steer_target = Input.get_action_strength(left_action + extra) - Input.get_action_strength(right_action + extra)
	steer_target *= STEER_LIMIT
	
	var speed = linear_velocity.length()
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)
	set_speed_text(speed)
	
	var fwd_mps =  linear_velocity * transform.basis
	set_sens_text(fwd_mps.x)
	
	if Global.ready_to_play:
		get_input(delta)
	else:
		engine_force = 0
	
	# Change Camera on input, FIRST => THIRD_BALL => THIRD_CAR
	if Input.is_action_just_pressed(change_cam_action + extra):
		if Global.is_split:
			camera_position = ((camera_position + 1) % camera_position_list.size()) as camera_position_list
			
			set_camera_current()
		
	# Show reverse light if vehicle is braking, but not in reverse
	if fwd_mps.x <= -1:
		# Vehicle go reverse
		$NightNode/RearLights.hide()
	elif Input.is_action_just_pressed(back_action + extra):
		# Vehicle is braking
		$NightNode/RearLights.show()
	elif Input.is_action_just_released(back_action + extra):
		# Vehicle is not braking
		$NightNode/RearLights.hide()
# =================================================================

func get_input(delta):
	var fwd_mps =  linear_velocity * transform.basis
	var speed = linear_velocity.length()
	
		# Update vehicle speed if front action is pressed
	if Input.is_action_pressed(front_action + extra):
		# Increase engine force at low speeds to make the initial acceleration faster.
		if speed < 5 and speed != 0:
			engine_force = clamp(engine_force_value * 5 / speed, 0, engine_force_value * 2)
		else:
			engine_force = engine_force_value
	else:
		engine_force = 0
		
	# Update vehicle speed if back action is pressed
	if Input.is_action_pressed(back_action + extra):
		# Voiture a l'arret
		if fwd_mps.x < 0.5:
			# Increase engine force at low speeds to make the initial acceleration faster.
			if speed < 5 and speed != 0:
				engine_force = -clamp(engine_force_value * 5 / speed, 0, engine_force_value*2)
			else:
				engine_force = -engine_force_value
		else:
			brake = 0.5
	else:
		brake = 0.0
	
	# Boost action is released
	if Input.is_action_just_released(boost_action + extra):
		boost_off()
	
	# Update vehicle speed with boost
	if fwd_mps.x >= 0 and boost > 0.0:
		# Vehicle go forward and have boost
		if Input.is_action_just_pressed(boost_action + extra):
			boost_on()
	else:
		boost_off()
		
	if boost_particles.emitting:
		if boost - delta * 10 > 0.0:
			boost -= delta*10
			boost = snapped(boost, 0.1)
			
		set_boost_text()
		
	# Reset vehicle only if vehicle is stoped and rolled over
	if Input.is_action_just_pressed(reset_action + extra):
		# Enable reset only if vehicle is stop
		if lbl_marche.text == "Arrêt" and speed < 1: 
			var orientation_in_deg = get_rotation_degrees()
			
			if orientation_in_deg.z <= -1 or orientation_in_deg.z > 179:
				rotation.z = 0
				rotation.x = 0
				global_transform.origin = Vector3(0,1,0)
# =================================================================	

func boost_on():
	# Boost action is pressed
	engine_force_value = DEFAULT_ENGINE_FORCE + BOOST_VALUE
	boost_particles.set_emitting(true)
	boost_sound.play()
# =================================================================	

func boost_off():
	engine_force_value = DEFAULT_ENGINE_FORCE
	boost_particles.set_emitting(false)
	boost_sound.stop()
# =================================================================	

# This function is used to set witch camera is current
func set_camera_current():
	$Camera/FirstView.current = camera_position == camera_position_list.FIRST
	
	$Camera/ThirdViewCar.current = camera_position == camera_position_list.THIRD_CAR
	$Camera/ThirdViewBall.current = camera_position == camera_position_list.THIRD_BALL
# =================================================================

# This function is used to set text of the direction of the car
func set_sens_text(forward_x):
	var sens:String
	
	if forward_x >= 1:
		sens = "Avant"
	elif forward_x <= -1:
		sens = "Arrière"
	else:
		sens = "Arrêt"
		
	lbl_marche.text = sens
# =================================================================

# This function is used to set text of the speed of the car
func set_speed_text(speed):
	lbl_vitesse.text = str("%.0f" % (speed * 3.6)).pad_zeros(2) + " Km/h"
# =================================================================

# This function is used to set boost of the car
func set_boost_text():
	lbl_boost.text = str("%.1f" % boost)
# =================================================================

func toggle_lights(is_night: bool):
	if is_night:
		$NightNode/FrontLights.show()
	else:
		$NightNode/FrontLights.hide()
# =================================================================

func set_vehicle_color(node = self):
	for vehicle_part in node.get_children():
		if vehicle_part.get_child_count() > 0:
			set_vehicle_color(vehicle_part)
			
		if vehicle_part.is_in_group("vehicle_color"):
			Global.change_object_color(vehicle_part, Color(color_hex))
# =================================================================

func reset():
	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	global_rotation = Vector3.ZERO
	
	boost_particles.set_emitting(false)
	boost_sound.stop()
	boost = Global.boost_max
	set_boost_text()

	if Global.is_split:
		set_camera_current()
# =================================================================
