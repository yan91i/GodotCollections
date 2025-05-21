extends RigidBody2D
signal collision
var rng := RandomNumberGenerator.new()
var speed = rng.randi_range(150,1300)
var direction = Vector2(1,rng.randf_range(-1,1))
var spin = rng.randf_range(-5,5)
var isfake := false
var worldwrap

func _ready() -> void:
	const WorldWrapObject2D = preload("res://scripts/WorldWrapObject2D.gd")
	worldwrap = WorldWrapObject2D.new(self,find_parent("Level").find_child("WorldWrapCollisionShape2D"),find_parent("Level").find_child("WorldWrapOuterCollisionShape2D"),Global.is_debugging)
	if not isfake or not get_class() == "Sprite2D":
		linear_velocity = direction * speed
		
func _process(delta: float) -> void:
	worldwrap.process_dup_position()
	
func destroy():
	$MeteorBlownup.play()
	$MeteorImage.hide()
	await get_tree().create_timer(1).timeout
	queue_free()
