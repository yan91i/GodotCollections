extends Node

func start():
	# listen to all ships
	for ship in get_tree().get_nodes_in_group('player_ship'):
		ship.connect('bump', Callable(self, '_on_ship_bumped').bind(ship))
		
func _on_ship_bumped(ship):
	assert(ship is Ship)
	
	global.the_match.add_score(ship.get_id(), 1)
	global.arena.show_msg(ship.get_color(), 1, ship.position)
	
