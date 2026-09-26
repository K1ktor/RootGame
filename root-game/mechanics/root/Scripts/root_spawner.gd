class_name RootSpawner
extends Node2D

signal root_stopped(root: Root, hit_position: Vector2)

@export var root_scene: PackedScene
@export_range(1, 16) var roots_per_click: int = 1
@export_range(0.0, 120.0) var spread_deg: float = 40.0 

# Zwiększane przy każdym reset(), żeby odroczone spawny sprzed resetu nie dodały korzenia
var _generation := 0


func _ready() -> void:
	_spawn_initial()


# Usuwa wszystkie korzenie i spawnuje je od nowa jak na starcie
func reset() -> void:
	_generation += 1
	for child in get_children():
		if child is Root:
			remove_child(child)
			child.queue_free()
	_spawn_initial()


func _spawn_initial() -> void:
	for i in roots_per_click:
		_spawn(_fan_offset_deg(i))


func _fan_offset_deg(i: int) -> float:
	if roots_per_click <= 1:
		return 0.0
	var half := spread_deg * 0.5
	return lerpf(-half, half, float(i) / (roots_per_click - 1))


func _spawn(offset_deg: float, swing_from: Root = null) -> Root:
	var root := root_scene.instantiate() as Root
	root.angle_offset_deg = offset_deg
	add_child(root)
	if swing_from:
		root.copy_swing(swing_from)
	root.stopped.connect(_on_root_stopped.bind(root))
	return root


func _on_root_stopped(hit_position: Vector2, root: Root) -> void:
	root_stopped.emit(root, hit_position)
	if root.has_drunk():
		return

	_spawn_next.call_deferred(root.angle_offset_deg, root, _generation)


func _spawn_next(offset_deg: float, swing_from: Root, generation: int) -> void:
	if generation != _generation:
		return
	_spawn(offset_deg, swing_from)
