extends Area3D

signal goal_detect(side: String)

enum player_type {FIRST, SECOND}
@export var player: player_type = player_type.FIRST

@onready var goalExplosion : GPUParticles3D = $Particles/GoalExplosion

# Called when the node enters the scene tree for the first time.
func _ready():
	var color_hex = ""
	var color_hex_explosion = ""
	
	if player == player_type.FIRST:
		color_hex = Global.first_player_color
		color_hex_explosion = Global.second_player_color
	elif player == player_type.SECOND:
		color_hex = Global.second_player_color
		color_hex_explosion = Global.first_player_color
	
	Global.change_object_color($TopBar/TopBarShape, Color(color_hex))
	
	goalExplosion.set_emitting(false)
	goalExplosion.set_one_shot(true)
	
	Global.change_object_color(goalExplosion, Color.BLACK)
	
	goalExplosion.material_override.set_emission(Color(color_hex_explosion))
	goalExplosion.material_override.set_feature(0, true) # 0 is emission_enabled : boold
# =================================================================

func _on_body_entered(body):
	if body.is_in_group("ball"):
		goalExplosion.set_emitting(true)
		
		var side = "left" if player == player_type.FIRST else "right"
		emit_signal("goal_detect", side)
# =================================================================
