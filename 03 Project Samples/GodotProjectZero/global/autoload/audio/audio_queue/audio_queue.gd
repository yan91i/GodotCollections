class_name AudioQueue extends Node

@export var stream_player_count: int = 4
@export_enum(&"Master", &"Music", &"SFX") var bus: String = &"SFX"

var _available_stream_players: Array[AudioStreamPlayer] = []
var _playing_stream_players: Dictionary = {}
var _audio_queue: Array[AudioItem] = []


class AudioItem:
	var stream: AudioStream
	var pitch_scale: float
	var id: String
	var volume: float


###############
## overrides ##
###############


func _ready() -> void:
	for i in stream_player_count:
		var stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
		stream_player.bus = bus
		add_child(stream_player)
		stream_player.finished.connect(_on_stream_player_finished.bind(stream_player))
		_available_stream_players.append(stream_player)


#############
## methods ##
#############


func play(id: String, stream: AudioStream, pitch_variance: float, volume: float = 1.0) -> void:
	var pitch_scale: float = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	var audio_item: AudioItem = AudioItem.new()
	audio_item.stream = stream
	audio_item.pitch_scale = pitch_scale
	audio_item.id = id
	audio_item.volume = volume
	_enqueue_audio_item(audio_item)


func stop(id: String) -> void:
	var stream_player: AudioStreamPlayer = _playing_stream_players.get(id, null)
	if stream_player == null:
		return
	stream_player.stop()
	_playing_stream_players.erase(id)
	_on_stream_player_finished(stream_player)


#############
## helpers ##
#############


func _enqueue_audio_item(audio_item: AudioItem) -> void:
	if _available_stream_players.size() > 0:
		var stream_player: AudioStreamPlayer = _available_stream_players.pop_front()
		_play_audio_item(stream_player, audio_item)
	else:
		_audio_queue.push_back(audio_item)


func _play_audio_item(stream_player: AudioStreamPlayer, audio_item: AudioItem) -> void:
	stream_player.volume_db = linear_to_db(audio_item.volume)
	stream_player.stream = audio_item.stream
	stream_player.pitch_scale = audio_item.pitch_scale
	stream_player.play()
	_playing_stream_players[audio_item.id] = stream_player


#############
## signals ##
#############


func _on_stream_player_finished(stream_player: AudioStreamPlayer) -> void:
	stream_player.pitch_scale = 1.0
	if _audio_queue.size() > 0:
		var audio_item: AudioItem = _audio_queue.pop_front()
		_play_audio_item(stream_player, audio_item)
	else:
		_available_stream_players.append(stream_player)
