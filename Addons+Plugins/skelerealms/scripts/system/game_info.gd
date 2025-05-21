extends Node
## holds Current game state.


## What world the player is in.
@export var world: StringName = &"init"

var is_loading:bool = false
var paused:bool = false
var game_running:bool = true :
	get:
		return game_running
	set(val):
		if val:
			$Timer.paused = false
			game_running = val # does this call Set again?
		else:
			$Timer.paused = true
			game_running = val

var world_time:Dictionary = {
	&"world_time" : 0,
	&"minute" : 0,
	&"hour" : 0,
	&"day" : 0,
	&"week" : 0,
	&"month" : 0,
	&"year" : 0,
}
## Continuity flags are values that can be set that allow for dialogue and the world to match up with that the player has done.
## for example, dialogue could set [code]met_alice:true[/code] if the Player meets the character Alice. Then, if the player meets Alice elsewhere, Alice can read this value and respond as though she as a character already knows the player.
var continuity_flags:Dictionary = {}
var minute:int:
	get:
		return world_time[&"minute"]
var hour:int:
	get:
		return world_time[&"hour"]
var day:int:
	get:
		return world_time[&"day"]
var week:int:
	get:
		return world_time[&"week"]
var month:int:
	get:
		return world_time[&"month"]
var year:int:
	get:
		return world_time[&"year"]
var is_game_started:bool
var command_paused:bool
## This is the point at which all entity loading, chunk loading, etc. is done. Normally, you would want this to be the player.
var world_origin:Node3D:
	get:
		if world_origin == null:
			world_origin = get_viewport().get_camera_3d()
		return world_origin
## The time between minutes, from 0 to 1.
var time_fraction:float:
	get:
		return _internal_seconds / ProjectSettings.get_setting("skelerealms/seconds_per_minute")
var _internal_seconds:float = 0.0

signal pause
signal unpause
signal console_frozen
signal console_unfrozen

signal minute_incremented
signal hour_incremented
signal day_incremented
signal week_incremented
signal month_incremented
signal year_incremented
signal game_started

signal game_loading(wid:String)
signal game_loaded


func _ready():
	set_name.call_deferred("GameInfo")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var t = Timer.new()
	t.name = "Timer"
	add_child(t)
	
	$Timer.timeout.connect(_on_timer_complete.bind())
	$Timer.one_shot = false
	$Timer.start(1)
	$Timer.paused = not game_running


## Puase the game.
func pause_game(silent:bool = false):
	if command_paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused = true
	get_tree().paused = true
	$Timer.paused = true
	if not silent:
		pause.emit()


## Unpause the game.
func unpause_game():
	if command_paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	paused = false
	get_tree().paused = false
	$Timer.paused = false
	unpause.emit()


func console_freeze() -> void:
	if paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	command_paused = true
	get_tree().paused = true
	$Timer.paused = true
	console_frozen.emit()


func console_unfreeze() -> void:
	if paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	command_paused = false
	get_tree().paused = false
	$Timer.paused = false
	console_unfrozen.emit()


func toggle_console_freeze() -> void:
	if not is_game_started:
		return
	
	if command_paused:
		console_unfreeze()
	else:
		console_freeze()


func toggle_pause():
	if not is_game_started:
		return
	
	if paused:
		unpause_game()
	else:
		pause_game()


func _on_timer_complete():
	# Increment world time
	world_time[&"world_time"] += 1
	# Increment minute
	if world_time[&"world_time"] % roundi(ProjectSettings.get_setting("skelerealms/seconds_per_minute")) == 0:
		world_time[&"minute"] += 1
		_internal_seconds = 0
		minute_incremented.emit()
	# Wrap minutes to hours
	if world_time[&"minute"] > roundi(ProjectSettings.get_setting("skelerealms/minutes_per_hour")):
		world_time[&"minute"] = 0
		world_time[&"hour"] += 1
		hour_incremented.emit()
	# Wrap hours to days
	if world_time[&"hour"] > roundi(ProjectSettings.get_setting("skelerealms/hours_per_day")):
		world_time[&"hour"] = 0
		world_time[&"day"] += 1
		day_incremented.emit()
	# Wrap days to weeks
	if world_time[&"day"] > roundi(ProjectSettings.get_setting("skelerealms/days_per_week")):
		world_time[&"day"] = 0
		world_time[&"week"] += 1
		week_incremented.emit()
	# Wrap weeks to months
	if world_time[&"week"] > roundi(ProjectSettings.get_setting("skelerealms/weeks_in_month")):
		world_time[&"week"] = 0
		world_time[&"month"] += 1
		month_incremented.emit()
	# Wrap months to years
	if world_time[&"month"] > roundi(ProjectSettings.get_setting("skelerealms/months_in_year")):
		world_time[&"month"] = 0
		world_time[&"year"] += 1
		year_incremented.emit()


func save() -> Dictionary:
	return {
		"world" : world,
		&"world_time" : world_time,
		"continuity_flags" : continuity_flags
	}


func load_game(data:Dictionary):
	world = data["world"]
	world_time = data[&"world_time"]
	continuity_flags = data["continuity_flags"]


func reset_data() -> void: # this should never happen but just in case
	world_time = {
		&"world_time" : 0,
		&"minute" : 0,
		&"hour" : 0,
		&"day" : 0,
		&"week" : 0,
		&"month" : 0,
		&"year" : 0,
	}
	continuity_flags = {}
	world = "init"


func start_game() -> void:
	game_started.emit()
	is_game_started = true


func _process(delta: float) -> void:
	if not paused:
		_internal_seconds += delta


func _progress_through_day() -> float:
	var hour_progress = hour / ProjectSettings.get_setting("skelerealms/hours_per_day")
	var minutes_progress = minute / (ProjectSettings.get_setting("skelerealms/minutes_per_hour") * ProjectSettings.get_setting("skelerealms/hours_per_day"))
	var seconds_progress = time_fraction / (ProjectSettings.get_setting("skelerealms/minutes_per_hour") * ProjectSettings.get_setting("skelerealms/hours_per_day"))
	return hour_progress + minutes_progress + seconds_progress
