extends Area2D
var speed = 1300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	 # These are the key properties to ensure objects don't slow down
	linear_damp = 0
	angular_damp = 0
	# And make sure gravity scale is zero for space simulation
	gravity = 0
	var tween = create_tween()
	tween.tween_property($Sprite2D,"scale",Vector2(1,1),.2).from(Vector2(0,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print("rot",rotation)
	position += Vector2(0,-1).rotated(rotation)*speed * delta


func _on_body_entered(body: Node2D) -> void:
	body.destroy()
	queue_free()
