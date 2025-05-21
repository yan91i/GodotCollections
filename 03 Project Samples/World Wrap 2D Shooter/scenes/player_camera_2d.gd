extends Camera2D
## Set to other than 0, this will override zoom of the camera at start using a proportion of viewport rectangle longuest side.
@export var overridezoom : float = 0.0 


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("viewport ",get_viewport_rect().size)
	var sidelenght = min(get_viewport_rect().size[0],get_viewport_rect().size[1])
	
	if overridezoom == 0:
		return
	var ratio =  sidelenght / overridezoom
	print("ratio",ratio)
	zoom = Vector2(ratio,ratio)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
