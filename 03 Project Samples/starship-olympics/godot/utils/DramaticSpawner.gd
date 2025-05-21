extends Node2D

@export (float, 0, 1, 0.01) var match_progress_trigger = 0.5
@export (float, 0, 10, 0.01) var jitter = 0.5
@export (float, 0, 1, 0.01) var chance = 1.0

var total_time : float
var content = []

func _ready():
	store()
	global.the_match.connect('setup', Callable(self, '_on_match_setup'))
	global.the_match.connect('tick', Callable(self, '_on_match_tick'))
	
func _on_match_setup():
	total_time = global.the_match.time_left
	
func _on_match_tick(time_left):
	if is_active() and time_left < (1-match_progress_trigger)*total_time:
		if randf() > chance:
			abort()
			return
			
		await get_tree().create_timer(jitter*randf()).timeout
		unstore()
	
func store():
	# store children outside the tree
	for child in get_children():
		content.append(child)
		remove_child(child)
		
func unstore():
	# put children back into the tree
	# WARNING the node is inserted as sibling of self
	for child in content:
		get_parent().add_child(child)
		child.global_position += global_position
	content = []
	
func is_active():
	return len(content) > 0
	
func abort():
	content = []
	
