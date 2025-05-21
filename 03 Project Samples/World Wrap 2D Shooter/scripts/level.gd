extends Node2D
var rng := RandomNumberGenerator.new()
var health: int = 3
func _ready() -> void:
	# Set health in ui
	get_tree().call_group("ui",'set_health',health)
	generate_start_meteors()

func is_space_free_in_circle(position: Vector2,radius: float):
	var space_state = get_world_2d().get_direct_space_state()
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()	
	circle_shape.radius = radius
	query.shape = circle_shape
	query.transform = Transform2D(0,position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result = space_state.intersect_shape(query)
	return result.size() == 0
func is_space_free_in_rect(position: Vector2,size: Vector2):
	var space_state = get_world_2d().get_direct_space_state()
	var query = PhysicsShapeQueryParameters2D.new()
	var square_shape = RectangleShape2D.new()
	square_shape.size = size
	query.shape = square_shape
	query.transform = Transform2D(0,position)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result = space_state.intersect_shape(query)
	return result.size() == 0
	
func generate_start_meteors() -> void:
	var meteor_count := 600
	for i in meteor_count:
		var meteortype = rng.randi_range(1,10)
		meteortype = var_to_str(meteortype)
		if len(meteortype) == 1:
			meteortype = "0" + meteortype
		var meteorfilename = "res://scenes/meteor"+ meteortype +".tscn"
		var meteor_scene: PackedScene = load(meteorfilename)
		var rangex = find_child("WorldWrapCollisionShape2D").shape.size.x / 2
		var rangey = find_child("WorldWrapCollisionShape2D").shape.size.y / 2
		var random_x = rng.randi_range(-rangex,rangex)
		var random_y = rng.randi_range(-rangey,rangey)
		var meteor = meteor_scene.instantiate()
		meteor.position = Vector2(random_x,random_y)
		var meteorsize = meteor.find_child("MeteorImage").texture.get_size()*meteor.find_child("MeteorImage").scale
		if is_space_free_in_rect(Vector2(random_x,random_y),meteorsize):
			$Meteors.add_child(meteor)
	
func _on_player_laser(pos,rot) -> void:
	#print("Laser position",pos,"ship angle",rot)
	var laser_scene: PackedScene = load("res://scenes/laser.tscn")	
	var laser = laser_scene.instantiate()
	$Lasers.add_child(laser)
	var laserdistancefromship = -40
	laser.rotation = rot
	laser.position = pos + Vector2(0,laserdistancefromship).rotated(rot)

func _on_wrap_boundary_meteroid_body_exited(body: Node2D) -> void:
	pass
	#print("meteor bound")
