extends HBoxContainer

@onready var anim = $Sprite2D/AnimationPlayer

func wiggle():
	anim.play("wiggle")

func idle():
	anim.play("idle")

func set_label(what: String):
	$Label.text = tr(what)
