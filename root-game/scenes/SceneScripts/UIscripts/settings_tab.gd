extends PanelContainer

@onready var music_slider: Slider = $MarginContainer/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: Slider = $MarginContainer/MarginContainer/VBoxContainer/SFXSlider

@onready var MusicLabel = $MarginContainer/MarginContainer/VBoxContainer/Label2
@onready var SFXLabel = $MarginContainer/MarginContainer/VBoxContainer/Label

var music_bus_index: int
var sfx_bus_index: int

func _ready() -> void:
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	music_slider.value_changed.connect(_on_music_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_value_changed)
	
	music_slider.value = Config.music_volume
	sfx_slider.value = Config.sfx_volume
	
	_set_labels()

func _on_music_value_changed(value: float) -> void:
	Config.music_volume = value
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(music_bus_index, value == 0.0)
	_set_labels()

func _on_sfx_value_changed(value: float) -> void:
	Config.sfx_volume = value
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_index, value == 0.0)
	_set_labels()

func _set_labels() -> void:
	MusicLabel.text = "Music " + str(int(Config.music_volume *100)) + "%"
	SFXLabel.text = "SFX " + str(int(Config.sfx_volume *100)) + "%"

func _on_close_btn_pressed() -> void:
	queue_free()
