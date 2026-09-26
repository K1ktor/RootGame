class_name Root
extends Node2D

signal segment_finished(tip_position: Vector2)
signal stopped(hit_position: Vector2)

enum State { AIMING, GROWING, STOPPED }

const GROW_EASE := 0.6

@export_group("Strzałka")
@export var max_angle_deg: float = 80.0      
@export var swing_speed_deg: float = 90.0    
@export var angle_offset_deg: float = 0.0   
@export var arrow_length: float = 36.0
@export var arrow_color: Color = Color.WHITE

@export_group("Wzrost")
@export var segment_length: float = 80.0
@export var grow_duration: float = 1.25     
@export var points_per_segment: int = 12
@export_flags_2d_physics var collision_mask: int = 1

@export_group("Odrosty")
@export var offshoot_scene: PackedScene
@export_range(0, 20) var offshoots_per_segment: int = 2

@export_group("Wygląd")
@export var base_width: float = 14.0
@export var tip_width_ratio: float = 0.2    
@export var root_color: Color = Color(0.55, 0.38, 0.22)
@export var root_gradient: Gradient
@export var wave_amplitude: float = 6.0

var _state: State = State.AIMING
var _angle: float = 0.0                     
var _swing_dir: float = 1.0
var _click_queued := false

var _points: PackedVector2Array = [Vector2.ZERO]  
var _segment: PackedVector2Array = []            
var _blocked := false
var _grow_time: float = 0.0

var _line: Line2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_line = Line2D.new()
	_line.width = base_width
	_line.default_color = root_color
	_line.gradient = root_gradient
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_line.antialiased = true
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, tip_width_ratio))
	_line.width_curve = curve
	_line.show_behind_parent = true 
	add_child(_line)
	_line.points = _points


func _process(delta: float) -> void:
	match _state:
		State.AIMING:
			_swing(delta)
		State.GROWING:
			_grow(delta)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if _click_queued and _state == State.AIMING:
		_start_segment()
	_click_queued = false

func _unhandled_input(event: InputEvent) -> void:
	if _state != State.AIMING:
		return
	if event is InputEventMouseButton:
		_click_queued = _click_queued or (event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	elif event is InputEventKey:
		_click_queued = _click_queued or (event.pressed and not event.echo and event.keycode == KEY_SPACE)


func _draw() -> void:
	if _state != State.AIMING:
		return
	var tip := _tip()
	var dir := _direction()
	var end := tip + dir * arrow_length
	var side := dir.orthogonal() * 7.0
	draw_line(tip, end, arrow_color, 3.0, true)
	draw_colored_polygon(PackedVector2Array([end + dir * 12.0, end + side, end - side]), arrow_color)

func copy_swing(other: Root) -> void:
	_angle = other._angle
	_swing_dir = other._swing_dir


func _tip() -> Vector2:
	return _points[_points.size() - 1]


func _direction() -> Vector2:
	return Vector2.DOWN.rotated(_angle + deg_to_rad(angle_offset_deg))


func _swing(delta: float) -> void:
	var limit := deg_to_rad(max_angle_deg)
	_angle += _swing_dir * deg_to_rad(swing_speed_deg) * delta
	if _angle > limit:
		_angle = limit
		_swing_dir = -1.0
	elif _angle < -limit:
		_angle = -limit
		_swing_dir = 1.0


func _start_segment() -> void:
	var start := _tip()
	var dir := _direction()
	var normal := dir.orthogonal()
	var amp := _rng.randf_range(-wave_amplitude, wave_amplitude)
	var waves := _rng.randi_range(1, 2)
	var path := PackedVector2Array([start])
	for i in range(1, points_per_segment + 1):
		var t := float(i) / points_per_segment
		path.append(start + dir * segment_length * t + normal * sin(t * PI * waves) * amp)

	var clip := clip_path(self, path, collision_mask)
	_segment = clip["path"]
	_blocked = clip["hit"]
	_spawn_offshoots()
	_grow_time = 0.0
	_state = State.GROWING


func _spawn_offshoots() -> void:
	if offshoot_scene == null or _segment.size() < 3:
		return
	for k in offshoots_per_segment:
		var idx := _rng.randi_range(1, _segment.size() - 2)
		var seg_dir := (_segment[idx + 1] - _segment[idx - 1]).normalized()

		var p := float(idx) / (_segment.size() - 1)
		var delay := (1.0 - pow(1.0 - p, GROW_EASE)) * grow_duration
		var o := offshoot_scene.instantiate() as Offshoot
		o.default_color = root_color
		if o.gradient == null:
			o.gradient = root_gradient
		add_child(o)
		move_child(o, 0) 
		o.sprout(_segment[idx], seg_dir, delay, collision_mask)


func _grow(delta: float) -> void:
	_grow_time += delta
	var t := clampf(_grow_time / grow_duration, 0.0, 1.0)
	var shown := _points.duplicate()
	shown.append_array(partial_path(_segment, ease(t, GROW_EASE)).slice(1))
	_line.points = shown
	if t >= 1.0:
		_finish_segment()


func _finish_segment() -> void:
	_points.append_array(_segment.slice(1))
	_line.points = _points
	if _blocked:
		_state = State.STOPPED
		queue_redraw()
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		stopped.emit(to_global(_tip()))
	else:
		_state = State.AIMING
		segment_finished.emit(to_global(_tip()))


# Pomocnicze, używane też przez Offshoot

static func partial_path(path: PackedVector2Array, f: float) -> PackedVector2Array:
	var reach := f * (path.size() - 1)
	var full := int(reach)
	var out := path.slice(0, full + 1)
	if full < path.size() - 1:
		out.append(path[full].lerp(path[full + 1], reach - full))
	return out


static func clip_path(node: Node2D, path: PackedVector2Array, mask: int) -> Dictionary:
	var space := node.get_world_2d().direct_space_state
	var out := PackedVector2Array([path[0]])
	for i in range(1, path.size()):
		var hit := _raycast_obstacle(space, node.to_global(path[i - 1]), node.to_global(path[i]), mask)
		if not hit.is_empty():
			out.append(node.to_local(hit["position"]))
			return {"path": out, "hit": true}
		out.append(path[i])
	return {"path": out, "hit": false}


static func _raycast_obstacle(space: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to, mask)
	var exclude: Array[RID] = []
	var hit := space.intersect_ray(query)
	while not hit.is_empty() and not (hit["collider"] is StaticBody2D or hit["collider"] is TileMapLayer):
		exclude.append(hit["rid"])
		query.exclude = exclude
		hit = space.intersect_ray(query)
	return hit
