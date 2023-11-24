extends Node

signal change_night_mode(is_night: bool)

var ready_to_play : bool = true

var temps: float = 0.0

var score_left: int = 0
var score_right: int = 0

# Default parms, can be change during playing 
var is_split: bool = false
var is_night: bool = false

# Params bellow can be edited
var first_player_color = "#002eff"
var second_player_color = "#de0000"

var goal_timeout: float = 4.0
var start_timeout: float = 3.0

var boost_pad_timeout: float = 5.0
var boost_pad_duration: float = 10.0

var boost_max : float = 100.0
# =================================================================

func change_object_color(obj, new_color: Color):
	var new_material = StandardMaterial3D.new()
	new_material.albedo_color = new_color
	obj.material_override = new_material
# =================================================================
