extends Node

var audio_player: AudioStreamPlayer
	
func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = preload("res://assets/sound/music/Dan_Roguelike_Music.wav")
	audio_player.bus = "Music"   # optional, if you have a Music audio bus
	add_child(audio_player)
	audio_player.play()
