class_name Offshoot
extends Line2D
# Krótki boczny odrost korzenia. Tworzy go Root przy każdym nowym segmencie.
# Grubość (width) ustawiasz w scenie Offshoot.tscn, kolor przejmuje od korzenia.

@export var length_min: float = 12.0
@export var length_max: float = 28.0
@export_range(0.0, 90.0) var angle_min_deg: float = 30.0   # odchylenie od kierunku korzenia
@export_range(0.0, 90.0) var angle_max_deg: float = 70.0
@export var grow_duration: float = 0.6
@export var wave_amplitude: float = 2.0
@export var points_count: int = 4
@export var tip_width_ratio: float = 0.3

var _path: PackedVector2Array = []
var _delay: float = 0.0
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, tip_width_ratio))
	width_curve = curve
	show_behind_parent = true
	set_process(false)  # rusza dopiero po sprout()


# Wołać po dodaniu do drzewa, w klatce fizyki (sprawdza kolizje).
# anchor i parent_dir w lokalnych współrzędnych rodzica; delay = czas do startu wzrostu.
func sprout(anchor: Vector2, parent_dir: Vector2, delay: float, collision_mask: int) -> void:
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var dir := parent_dir.rotated(side * deg_to_rad(_rng.randf_range(angle_min_deg, angle_max_deg)))
	var length := _rng.randf_range(length_min, length_max)
	var normal := dir.orthogonal()
	var amp := _rng.randf_range(-wave_amplitude, wave_amplitude)
	var path := PackedVector2Array([anchor])
	for i in range(1, points_count + 1):
		var t := float(i) / points_count
		path.append(anchor + dir * length * t + normal * sin(t * PI) * amp)

	_path = Root.clip_path(self, path, collision_mask)["path"]
	_delay = delay
	_time = 0.0
	points = PackedVector2Array()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	var t := clampf((_time - _delay) / grow_duration, 0.0, 1.0)
	if t <= 0.0:
		return
	points = Root.partial_path(_path, ease(t, Root.GROW_EASE))
	if t >= 1.0:
		set_process(false)
