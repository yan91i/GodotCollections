extends Node2D

@export var msg : String = '+1': set = set_msg
@export var still : bool = false

func _ready():
	# no messages after game is over
	if not global.is_match_running():
		queue_free()
		return
		
	if not still:
		appear()

func set_msg(value):
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		var sgn = ""
		if value >= 0:
			sgn = "+"
		else:
			$Label.visible = false
			$BadLabel.visible = true
		msg = sgn+str(value)
	else:
		msg = value
		
	$Label.text = tr(msg)
	$BadLabel.text = tr(msg)
	
	
signal end
func _on_AnimationPlayer_animation_finished(anim_name):
	if not still:
		queue_free()
	else:
		$AnimationPlayer.stop(true)
	emit_signal('end')
	
func appear():
	$AnimationPlayer.play("Appear")
	
	
