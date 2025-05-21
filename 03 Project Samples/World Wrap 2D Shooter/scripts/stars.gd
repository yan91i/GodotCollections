extends Node2D
var rng := RandomNumberGenerator.new()
var starcount = 30
var worldwrap
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	const WorldWrapObject2D = preload("res://scripts/WorldWrapObject2D.gd")
	for i in range(starcount):
		var star = $starnode.duplicate()
		var rect = get_viewport().get_visible_rect().size
		var levelcollisionshape = find_parent("Level").find_child("WorldWrapCollisionShape2D")
		var limitx = levelcollisionshape.shape.size.x / 2
		var limity = levelcollisionshape.shape.size.y / 2
		# Global position is the countainer node2d
		star.position = Vector2(rng.randi_range(-limitx,limitx),rng.randi_range(-limity,limity))
		var starspritescale = rng.randf_range(2,4)
		# Scale and animation speed belong to the AnimatedSprite2D
		star.get_child(0).scale = Vector2(starspritescale,starspritescale)
		star.get_child(0).speed_scale = rng.randf_range(.2,2)
		worldwrap = WorldWrapObject2D.new(star,find_parent("Level").find_child("WorldWrapCollisionShape2D"),find_parent("Level").find_child("WorldWrapOuterCollisionShape2D"),Global.is_debugging,true)
		# Here we create the duplicate in the Stars Node. Creating the duplicate inside of a starnode itself
		# would result in improper positionning.
		worldwrap.create_static_duplicates($".")
		$".".add_child(star)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
