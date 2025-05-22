extends Node

var audio_players = []
@export var play_on_ready = false

func _ready():
	for c in get_children():
		if c is AudioStreamPlayer or c is AudioStreamPlayer2D or c is AudioStreamPlayer3D:
			audio_players.append(c)
	if play_on_ready:
		play()

func play():
	if audio_players.size() == 0:
		return
	audio_players[randi_range(0, audio_players.size()-1)].play()

func stop():
	for ap in audio_players:
		ap.stop()

func is_playing():
	for ap in audio_players:
		if ap.playing:
			return true
	return false
