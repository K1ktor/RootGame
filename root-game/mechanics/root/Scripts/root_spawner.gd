class_name RootSpawner
extends Node2D

signal root_stopped(root: Root, hit_position: Vector2)

const MAX_ROOTS_PER_CLICK := 16

@export var root_scene: PackedScene
@export_range(1, 16) var roots_per_click: int = 1
@export_range(0.0, 120.0) var spread_deg: float = 40.0

@export_group("Rozdwojenie")
@export_range(0.0, 90.0) var split_angle_deg: float = 30.0   # odchylenie gałęzi od korzenia-rodzica
@export_range(1, 64) var max_growing_roots: int = 12         # limit, żeby rozdwojenia nie eksplodowały

# Zwiększane przy każdym reset(), żeby odroczone spawny sprzed resetu nie dodały korzenia
var _generation := 0
# Któryś korzeń napił się wody - reszta zamrożona, nic nowego nie spawnujemy
var _level_done := false
# Signals.level_complete leci tylko raz na level, niezależnie od liczby korzeni
var _level_complete_emitted := false


func _ready() -> void:
	_spawn_initial()


# Usuwa wszystkie korzenie i spawnuje je od nowa jak na starcie
func reset() -> void:
	_generation += 1
	_level_done = false
	_level_complete_emitted = false
	for child in get_children():
		if child is Root:
			remove_child(child)
			child.queue_free()
	_spawn_initial()


func _root_count() -> int:
	return mini(roots_per_click + Upgrades.extra_roots(), MAX_ROOTS_PER_CLICK)


func _spawn_initial() -> void:
	for i in _root_count():
		_spawn(_fan_offset_deg(i))


func _fan_offset_deg(i: int) -> float:
	var count := _root_count()
	if count <= 1:
		return 0.0
	var half := spread_deg * 0.5
	return lerpf(-half, half, float(i) / (count - 1))


# is_branch = korzeń powstały z rozdwojenia; po zatrzymaniu nie spawnuje następcy
func _spawn(offset_deg: float, swing_from: Root = null, is_branch := false, at := Vector2.ZERO) -> Root:
	var root := root_scene.instantiate() as Root
	root.angle_offset_deg = offset_deg
	root.position = at
	_apply_upgrades(root)
	add_child(root)
	if swing_from:
		root.copy_swing(swing_from)
	root.stopped.connect(_on_root_stopped.bind(root, is_branch))
	root.segment_finished.connect(_on_segment_finished.bind(root))
	root.drink_finished.connect(_on_root_drink_finished)
	return root


func _apply_upgrades(root: Root) -> void:
	root.segment_length *= Upgrades.root_length_mult()
	root.offshoots_per_segment += Upgrades.extra_offshoots()
	root.offshoot_length_mult *= Upgrades.offshoot_length_mult()


func _growing_roots() -> int:
	var count := 0
	for child in get_children():
		if child is Root and not child.is_stopped():
			count += 1
	return count


func _on_segment_finished(tip_position: Vector2, root: Root) -> void:
	if _level_done or _growing_roots() >= max_growing_roots:
		return
	if randf() >= Upgrades.split_chance():
		return
	var side := 1.0 if randf() < 0.5 else -1.0
	_spawn(root.angle_offset_deg + side * split_angle_deg, root, true, to_local(tip_position))

func _on_root_stopped(hit_position: Vector2, root: Root, is_branch: bool) -> void:
	root_stopped.emit(root, hit_position)
	if root.has_drunk():
		_finish_level(root)
		return
	if is_branch or _level_done:
		return

	_spawn_next.call_deferred(root.angle_offset_deg, root, _generation)

func _finish_level(winner: Root) -> void:
	_level_done = true
	for child in get_children():
		if child is Root and child != winner:
			child.active = false


func _on_root_drink_finished() -> void:
	if _level_complete_emitted:
		return
	_level_complete_emitted = true
	Signals.level_complete.emit()

func _spawn_next(offset_deg: float, swing_from: Root, generation: int) -> void:
	if generation != _generation or _level_done:
		return
	_spawn(offset_deg, swing_from)
