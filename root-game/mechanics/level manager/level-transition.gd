extends Node

@export var oldPlant : Sprite2D
@export var newPlant : Sprite2D
var oldPlantRoot : Root
var newPlantRoot : Root
const oldPlantPos = Vector2(610.0, 140.0)
const newPlantPos = Vector2(1610.0, 140.0)
var timer := 1000.0
@export var speed := 200.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	oldPlant.position = Vector2(610.0, 140.0)
	newPlant.position = Vector2(1610.0, 140.0)
	oldPlant.visible = true
	newPlant.visible = true
	resetProgress()
	timer = 1000
	oldPlantRoot.global_scale = Vector2.ONE
	newPlantRoot.global_scale = Vector2.ONE
	pass # Replace with function body.

func resetProgress():
	timer = 0
	var temp = newPlant
	newPlant = oldPlant
	oldPlant = temp
	oldPlantRoot = oldPlant.get_node("Root")
	newPlantRoot = newPlant.get_node("Root")
	oldPlantRoot.active = false
	newPlantRoot.active = false
	newPlantRoot._reset()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta * speed
	if (timer >= 1000):
		newPlantRoot.active = true
	var progress = min(timer, 1000.0) / 1000.0
	var ease = easeInOutCubic(progress) * 1000
	oldPlant.position = oldPlantPos + ease * Vector2.LEFT
	newPlant.position = newPlantPos + ease * Vector2.LEFT
	pass

func easeInOutCubic(x: float) -> float:
	if x < 0.5:
		return 4.0 * x * x * x
	else:
		return 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0


func _on_button_button_down() -> void:
	resetProgress()
	pass # Replace with function body.
