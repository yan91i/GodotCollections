extends Component

var target : Ship: get = get_target, set = set_target

@export var keep_target_timeout : float = 1.0
@export var detection_insensitive_timeout : float = 0.5
var keep_target_t : float = 0
var detection_insensitive_t : float = 0
var last_valid_target = null
var thrust := 0.0

func set_target(value):
	target = value
	if target:
		last_valid_target = target
	else:
		thrust = 0
	
func get_target():
	return target
	
func set_keep_target_timeout():
	keep_target_t = keep_target_timeout
	
func set_detection_insensitive_timeout():
	detection_insensitive_t = detection_insensitive_timeout
	
func update_timeouts(delta):
	if not enabled:
		return
		
	keep_target_t -= delta
	detection_insensitive_t -= delta
	
func has_keep_target_timed_out():
	return keep_target_t <= 0
	
func has_detection_insensitive_timed_out():
	return detection_insensitive_t <= 0
	
func enable_with_timeout(wait_time):
	await get_tree().create_timer(wait_time).timeout
	enable()

func get_last_valid_target():
	return last_valid_target
	
