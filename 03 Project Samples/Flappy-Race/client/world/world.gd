extends CommonWorld

const INTERPOLATION_OFFSET = 100

export(PackedScene) var Confetti

# World state vars
var last_world_state := 0
var world_state_buffer := []
# Used for the race progress bar
var finish_line_x_pos: int

# Player vars
# Represents the body of the camera target, which could be a player or a spectator target
var current_player: CommonPlayer

# Spectate vars
var spectate_target: Node
var camera_target_id := -1
var camera_starting_position := Vector2(-5000, 0)


func _ready() -> void:
	Globals.client_world = self
	Network.Client.send_client_ready()
	$MainCamera.position = camera_starting_position
	$MainCamera.velocity = Vector2.ZERO


func _process(_delta: float) -> void:
	# Update the player's progress in the UI
	if finish_line_x_pos != 0:
		update_player_progress()
	# Make wind particles spawn ahead of the camera
	$WindParticles.position.x = $MainCamera.position.x + get_viewport_rect().size.x


func update_player_progress() -> void:
	for player_id in player_list:
		var player_entry = player_list[player_id]
		if (
			not player_entry.spectate
			and player_entry.body != null
			and is_instance_valid(player_entry.body)
		):
			var player_progress: float = 0.0
			player_progress = player_entry.body.get_progress()
			$UI.RaceProgress.set_progress(player_id, player_progress)


func _physics_process(_delta: float) -> void:
	var render_time = Network.Client.client_clock - INTERPOLATION_OFFSET
	if world_state_buffer.size() > 1:
		# world_state_buffer[0] will always be the oldest received world_state
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2].T:
			world_state_buffer.remove(0)
		if world_state_buffer.size() > 2:
			# We have a future world state available - smooth movement!
			interpolate_world_state(render_time)
		elif render_time > world_state_buffer[1].T:
			# No future world_states available - guess where things will be
			extrapolate_world_state(render_time)


func interpolate_world_state(render_time: int) -> void:
	var interpolation_factor = (
		float(render_time - world_state_buffer[1]["T"])
		/ float(world_state_buffer[2]["T"] - world_state_buffer[1]["T"])
	)
	for player in world_state_buffer[2].keys():
		if str(player) == "T":
			# Ignore the included timestamp
			continue
		if player == multiplayer.get_network_unique_id():
			# Ignore the local player
			continue
		if not world_state_buffer[1].has(player):
			# A connecting player won't be available in past world_state yet
			continue
		if has_node(str(player)):
			# Use the position between past and future world_states to calculate
			# the current position
			var new_position = lerp(
				world_state_buffer[1][player]["P"],
				world_state_buffer[2][player]["P"],
				interpolation_factor
			)
			var new_velocity = lerp(
				world_state_buffer[1][player]["V"],
				world_state_buffer[2][player]["V"],
				interpolation_factor
			)
			get_node(str(player)).move_player(new_position, new_velocity)
		# TODO this should only spawn players if they are present in a future
		# world state but sometimes they still seem to arrive after death
		# else:
		# 	spawn_player(player, world_state_buffer[2][player]["P"])


func extrapolate_world_state(render_time: int) -> void:
	var extrapolation_factor = (
		(
			float(render_time - world_state_buffer[0]["T"])
			/ float(world_state_buffer[1]["T"] - world_state_buffer[0]["T"])
		)
		- 1.00
	)
	for player in world_state_buffer[1].keys():
		if str(player) == "T":
			# Ignore the included timestamp
			continue
		if player == multiplayer.get_network_unique_id():
			# Ignore the local player
			continue
		if not world_state_buffer[0].has(player):
			# A connecting player won't be available in past world_state yet
			continue
		if has_node(str(player)):
			var position_delta = (
				world_state_buffer[1][player]["P"]
				- world_state_buffer[0][player]["P"]
			)
			var new_position = (
				world_state_buffer[1][player]["P"]
				+ (position_delta * extrapolation_factor)
			)
			var velocity_delta = (
				world_state_buffer[1][player]["V"]
				- world_state_buffer[0][player]["V"]
			)
			var new_velocity = (
				world_state_buffer[1][player]["V"]
				+ (velocity_delta * extrapolation_factor)
			)
			get_node(str(player)).move_player(new_position, new_velocity)


func update_world_state(world_state: Dictionary) -> void:
	if world_state["T"] > last_world_state:
		last_world_state = world_state["T"]
		world_state_buffer.append(world_state)


func start_game(game_seed: int, new_game_options: Dictionary, new_player_list: Dictionary) -> void:
	var result := $LevelGenerator.connect("progress_changed", $UI/Loading, "set_progress")
	assert(result == OK)
	$UI/Loading.set_hint_text("Generating level")
	$UI/Loading.start()
	Network.Client.game_options = new_game_options
	.start_game(game_seed, new_game_options, new_player_list)
	if not level_generator.level_ready:
		# Level generator could be finished before returning to this function
		yield(level_generator, "level_ready")
	$UI.set_player_list(new_player_list)
	$UI.update_lives(game_options.lives)
	Network.Client.send_client_ready()
	$UI/Loading.set_hint_text("Waiting for players")
	finish_line_x_pos = level_generator.finish_line.position.x


func late_join_start(
	game_seed: int, new_game_options: Dictionary, new_player_list: Dictionary, time: float
) -> void:
	start_game(game_seed, new_game_options, new_player_list)
	if not level_generator.level_ready:
		# Level generator could be finished before returning to this function
		yield(level_generator, "level_ready")
	$UI/Loading.stop()
	spawn_player_list(new_player_list)
	reset_camera()
	$UI.set_late_join_spectator(time)
	finish_line_x_pos = level_generator.finish_line.position.x


# Called through the server once all players are ready
func start_countdown() -> void:
	.start_countdown()
	reset_camera()
	$UI/Loading.stop()
	$UI.start_countdown()
	# Make the camera swoop into the starting position
	var tween = get_tree().create_tween()
	tween.tween_property($MainCamera, "position", Vector2.ZERO, 3).set_ease(Tween.EASE_OUT).set_trans(
		Tween.TRANS_CUBIC
	)


func _on_UI_countdown_finished() -> void:
	for player in spawned_players:
		player.start()
	var client_id = multiplayer.get_network_unique_id()
	if player_list[client_id].spectate == false:
		var player = player_list[client_id].body
		# Give the player a jump at the start
		player.velocity.y = -STARTING_JUMP
		player.enable_control()
	$MusicPlayer.play_random_track()
	$MainCamera.add_trauma(1.0)
	spawn_confetti(Vector2.ZERO)


func spawn_confetti(pos: Vector2) -> void:
	var confetti: Particles2D = Confetti.instance()
	confetti.set_position(pos)
	confetti.set_emitting(true)
	add_child(confetti)


func reset_camera() -> void:
	var client_id = multiplayer.get_network_unique_id()
	if player_list[client_id].spectate:
		spectate_leader()
	else:
		$UI.set_spectating(false)
		set_camera_target(client_id)


func set_camera_target(player_id: int) -> void:
	if camera_target_id == player_id:
		push_error("This player is already the camera target!")
		return
	camera_target_id = player_id
	var player = player_list[player_id].body
	current_player = player
	$UI.RaceProgress.set_active_player(player_id)
	$MainCamera.set_target(player)


func reset_game() -> void:
	Network.Client.send_start_game_request()


func spawn_player(player_id: int, spawn_position: Vector2, _is_bot: bool) -> Node2D:
	var player = .spawn_player(player_id, spawn_position, _is_bot)
	# Only needed on the client
	player.connect("coins_changed", self, "_on_Player_coins_changed")
	player.connect("got_item", self, "_on_Player_got_item")
	player.set_body_colour(player_list[player_id]["colour"])
	player.set_player_name(player_list[player_id]["name"])
	return player


func despawn_player(player_id: int) -> void:
	if not has_node(str(player_id)):
		# Player already despawned
		return
	$UI.RaceProgress.remove_player(player_id)
	.despawn_player(player_id)
	if player_id == camera_target_id:
		$MainCamera.add_trauma(1.0)
		if spawned_players.empty():
			# Race should be finished so stop here
			return

		# Only show the death UI if this client was controlling the player
		if player_id == multiplayer.get_network_unique_id():
			$UI.show_death()

		# Delay to see death animation
		yield(get_tree().create_timer(4), "timeout")
		chunk_tracker.remove_player(player_id)
		spectate_leader()


func set_spectate_target(target: Node2D) -> void:
	assert(target != null)
	if spectate_target == target:
		# Already spectating this player
		return
	# Disconnect camera switching from old target if they exist
	if (
		spectate_target != null
		and spectate_target.is_connected("tree_exited", self, "spectate_leader")
	):
		spectate_target.disconnect("tree_exited", self, "spectate_leader")
	# Ensure the camera switches when the target despawns
	var result := target.connect("tree_exited", self, "spectate_leader")
	assert(result == OK)
	spectate_target = target
	# Target name should be the player ID
	var new_player_id = int(target.name)
	set_camera_target(new_player_id)
	$UI.set_spectate_player_name(target.player_name)


func spectate_leader() -> void:
	var leader := get_lead_player()
	if leader == null:
		# No leader so don't do anything - race should be finished
		return
	set_spectate_target(leader)
	$UI.set_spectating(true)


func _on_Player_death(player: CommonPlayer) -> void:
	# Only update for the camera target
	if int(player.name) == camera_target_id:
		._on_Player_death(player)
		$MainCamera.add_trauma(1.0)


func _on_Player_score_changed(player: CommonPlayer) -> void:
	._on_Player_score_changed(player)
	# Only update for the camera target
	if int(player.name) == camera_target_id:
		$UI.update_score(player.score)


func _on_Player_coins_changed(player: CommonPlayer) -> void:
	# Only update for the camera target
	if int(player.name) == camera_target_id:
		$UI.update_coins(player.coins)
		$MainCamera.add_trauma(0.3)


func _on_Player_got_item(player: CommonPlayer, item: Item) -> void:
	# Only update for the camera target
	if int(player.name) == camera_target_id:
		$UI.get_item(item)
		$MainCamera.add_trauma(0.3)


func _on_UI_request_restart() -> void:
	reset_game()


func player_finished(player_id: int, place: int, time: float) -> void:
	# Spawn confetti whenever a player finishes
	spawn_confetti(Vector2(finish_line_x_pos, 0))

	if player_id == camera_target_id:
		$MainCamera.add_trauma(1.0)

	# Only show the finished screen if this client was controlling the player
	if player_id == multiplayer.get_network_unique_id():
		$UI.show_finished(place, time)
		$MusicPlayer.stop()
		$FinishMusic.play()
		$FinishChime.play()


func _on_UI_spectate_change(forward_not_back) -> void:
	var new_target_index := 0
	var current_target_index: int = spawned_players.find(spectate_target)
	if forward_not_back:
		new_target_index = (current_target_index + 1) % spawned_players.size()
	else:
		new_target_index = (current_target_index - 1) % spawned_players.size()
	set_spectate_target(spawned_players[new_target_index])


func end_race() -> void:
	.end_race()
	# Make the camera swoop past the finish line
	var tween = get_tree().create_tween()
	tween.tween_property($MainCamera, "velocity", Vector2(50, 0), 3).set_ease(Tween.EASE_IN).set_trans(
		Tween.TRANS_CUBIC
	)
