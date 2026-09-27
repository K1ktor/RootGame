extends Node

var levels_list = [ preload("res://Level Data/level1.tscn"), preload("res://Level Data/level2.tscn") ]
var levelCompleted = 0

const old_scene_pos = Vector2(0.0, 250.0)
const new_scene_pos = Vector2(2000.0, 250.0)
var timer := 1000.0
@export var speed := 200.0
@onready var activeScene := $"../activeScene"
@onready var oldScene := $"../oldScene"

# To dodalem bo to spawnuje wszystkie rooty, wsm to powinno sie nazywac 
# root_manager a nie spawner ale chuj
@export var root_spawner : RootSpawner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resetProgress()
	timer = 1000
	pass # Replace with function body.

func resetProgress():
	timer = 0
	var scene : Node2D = levels_list[1].instantiate()
	activeScene.remove_child(get_child(0))
	oldScene.remove_child(get_child(0))
	add_child(scene)
	oldScene = activeScene
	activeScene = scene
	#root_spawner = activeScene.get_node("RootSpawner")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta * speed
	print(timer)
	var progress = min(timer, 1000.0) / 1000.0
	var easeing = easeInOutCubic(progress) * 2000
	oldScene.position = old_scene_pos + easeing * Vector2.LEFT
	activeScene.position = new_scene_pos + easeing * Vector2.LEFT
	pass

func easeInOutCubic(x: float) -> float:
	if x < 0.5:
		return 4.0 * x * x * x
	else:
		return 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0


func _on_button_button_down() -> void:
	resetProgress()
	pass # Replace with function body.
