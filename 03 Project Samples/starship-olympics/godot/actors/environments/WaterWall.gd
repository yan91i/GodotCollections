@tool
extends StaticBody2D

func _ready():
	refresh()
	
func _on_GShape_changed():
	refresh()
	
func refresh():
	var gshape = get_gshape()
	
	if not gshape:
		return
		
	if not gshape.is_connected('changed', Callable(self, '_on_GShape_changed')):
		gshape.connect('changed', Callable(self, '_on_GShape_changed'))
		
	var polygon = gshape.to_PoolVector2Array()
	var line = gshape.to_closed_PoolVector2Array()
	$"%SuperOverlay".polygon = polygon
	$"%Top".polygon = polygon
	$"%Overlay".polygon = polygon
	$"%Outline".points = line
	$"%Bottom".points = $"%Outline".points
	$"%OverlapArea/CollisionPolygon2D".polygon = polygon
	$"%RepulsionArea/CollisionPolygon2D".polygon = polygon
	$CollisionPolygon2D.polygon = polygon
	$"%Top".texture_offset = gshape.get_extents()

func get_gshape():
	for child in get_children():
		if child is GShape:
			return child
	return null
	
func _on_OverlapArea_body_entered(body):
	if body.has_method('dive_in'):
		body.dive_in()
		
	# trigger rockets
	if body.has_method('detonate'):
		body.detonate()
		
func _on_OverlapArea_body_exited(body):
	if body.has_method('dive_out'):
		body.dive_out()
		
#func _physics_process(delta):
#	for body in $"%RepulsionArea".get_overlapping_bodies():
#		if not body is Ship:
#			continue
#		body.apply_central_impulse(100*(body.global_position - global_position))
