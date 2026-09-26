class_name RootSpawner
extends Node2D

signal root_stopped(root: Root, hit_position: Vector2)

@export var root_scene: PackedScene
@export_range(1, 16) var roots_per_click: int = 1
@export_range(0.0, 120.0) var spread_deg: float = 40.0 


func _ready() -> void:
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

	_spawn.call_deferred(root.angle_offset_deg, root)
