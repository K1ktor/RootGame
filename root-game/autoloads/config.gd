extends Node

var music_volume: float = 0.8
var sfx_volume: float = 0.8

func _ready() -> void:
	var music_bus_index = AudioServer.get_bus_index("Music")
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))
