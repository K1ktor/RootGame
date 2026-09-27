extends Node2D
# Testowy przełącznik leveli do sprawdzania ulepszeń.
# Po wybraniu karty (Signals.upgrade_chosen) ładuje następny level, po ostatnim wraca do pierwszego.
# Klawisze: N - następny level, R - restart levelu, U - wymuś ekran kart, C - wyczyść ulepszenia.

@export var levels: Array[PackedScene] = []

var _index := 0
var _level: Node

@onready var _info: Label = %Info


func _ready() -> void:
	Signals.upgrade_chosen.connect(func(_card: UpgradeCard) -> void: _load_level(_index + 1))
	_load_level(0)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_N:
			_load_level(_index + 1)
		KEY_R:
			_load_level(_index)
		KEY_U:
			Signals.level_complete.emit()   # tylko debug - normalnie emituje RootSpawner
		KEY_C:
			Upgrades.clear()
			_load_level(_index)
		_:
			return
	get_viewport().set_input_as_handled()


func _load_level(index: int) -> void:
	if levels.is_empty():
		return
	_index = posmod(index, levels.size())
	if _level:
		remove_child(_level)
		_level.queue_free()
	_level = levels[_index].instantiate()
	add_child(_level)
	_update_info()


func _update_info() -> void:
	var lines := PackedStringArray([
		"Level %d/%d (%s)" % [_index + 1, levels.size(), _level.name],
		"N - następny   R - restart   U - wymuś karty   C - wyczyść ulepszenia",
		"",
	])
	for id_name in UpgradeCard.Id:
		lines.append("%s: %d" % [id_name, Upgrades.level(UpgradeCard.Id[id_name])])
	_info.text = "\n".join(lines)
