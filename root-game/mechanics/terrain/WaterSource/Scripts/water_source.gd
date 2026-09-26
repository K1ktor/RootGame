@tool
class_name WaterSource
extends Polygon2D

enum CollisionSource { OUTER, INNER }
enum GradientDirection { VERTICAL, HORIZONTAL, RADIAL }

const MIN_AREA := 1.0          
const COLLINEAR_EPS := 0.001   

const GENERATED_PROPERTIES := ["texture", "texture_offset", "texture_scale"]

const FILLS := {
	GradientDirection.VERTICAL: [GradientTexture2D.FILL_LINEAR, Vector2(0.5, 0.0), Vector2(0.5, 1.0)],
	GradientDirection.HORIZONTAL: [GradientTexture2D.FILL_LINEAR, Vector2(0.0, 0.5), Vector2(1.0, 0.5)],
	GradientDirection.RADIAL: [GradientTexture2D.FILL_RADIAL, Vector2(0.5, 0.5), Vector2(1.0, 0.5)],
}

@export_range(0.0, 64.0, 0.5, "or_greater", "suffix:px") var inset: float = 8.0:  
	set(value):
		inset = maxf(value, 0.0)
		_rebuild()
@export var collision_source: CollisionSource = CollisionSource.OUTER:
	set(value):
		collision_source = value
		_rebuild()

@export_group("Wygląd")
@export var bank_gradient: Gradient:
	set(value):
		bank_gradient = value
		_update_look()
@export var water_gradient: Gradient:
	set(value):
		water_gradient = value
		_update_look()
@export var gradient_direction: GradientDirection = GradientDirection.VERTICAL:
	set(value):
		gradient_direction = value
		_update_look()

var _last_polygon := PackedVector2Array()
var _warning := ""
var _bank_texture := GradientTexture2D.new()
var _water_texture := GradientTexture2D.new()


func _ready() -> void:
	_update_look()
	_rebuild()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if polygon != _last_polygon:
		_rebuild()


func _validate_property(property: Dictionary) -> void:
	if str(property.name) in GENERATED_PROPERTIES:
		property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray([_warning]) if _warning else PackedStringArray()


func _rebuild() -> void:
	if not is_node_ready():
		return
	_last_polygon = polygon
	var inner := _inner_polygon()

	var water := get_node_or_null(^"Water") as Polygon2D
	if water:
		water.polygon = inner
		water.visible = not inner.is_empty()
	_map_textures()

	var shape := _clean(polygon if collision_source == CollisionSource.OUTER else inner)
	var valid := _is_simple(shape)
	var collision := get_node_or_null(^"StaticBody2D/CollisionPolygon2D") as CollisionPolygon2D
	if collision:
		collision.polygon = shape if valid else PackedVector2Array()

	var warning := _compute_warning(valid, inner)
	if warning != _warning:
		_warning = warning
		update_configuration_warnings()


func _compute_warning(valid: bool, inner: PackedVector2Array) -> String:
	if polygon.size() < 3:
		return "WaterSource potrzebuje co najmniej 3 punktów."
	if not valid:
		return "Kształt kolizji jest niepoprawny (krawędzie się przecinają) - kolizja wyłączona."
	if inner.is_empty():
		return "Brzeg (inset) jest grubszy niż kształt - woda jest ukryta."
	return ""

func _inner_polygon() -> PackedVector2Array:
	var best := PackedVector2Array()
	if polygon.size() < 3:
		return best
	var best_area := MIN_AREA
	for part in Geometry2D.offset_polygon(polygon, -inset, Geometry2D.JOIN_ROUND):
		var area := absf(_area(part))
		if area > best_area:
			best = part
			best_area = area
	return best

func _update_look() -> void:
	var fill: Array = FILLS[gradient_direction]
	for pair in [[_bank_texture, bank_gradient], [_water_texture, water_gradient]]:
		var tex: GradientTexture2D = pair[0]
		tex.gradient = pair[1]
		tex.fill = fill[0]
		tex.fill_from = fill[1]
		tex.fill_to = fill[2]
	_map_textures()

func _map_textures() -> void:
	if not is_node_ready():
		return
	_map_texture(self, _bank_texture, bank_gradient)
	var water := get_node_or_null(^"Water") as Polygon2D
	if water:
		_map_texture(water, _water_texture, water_gradient)

static func _map_texture(target: Polygon2D, tex: GradientTexture2D, gradient: Gradient) -> void:
	var points := target.polygon
	if gradient == null or points.size() < 3:
		target.texture = null
		return
	var rect := _bounds(points)
	target.texture = tex
	target.texture_offset = -rect.position
	target.texture_scale = tex.get_size() / rect.size.max(Vector2.ONE)


static func _bounds(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for p in points:
		rect = rect.expand(p)
	return rect


static func _area(points: PackedVector2Array) -> float:
	var sum := 0.0
	var n := points.size()
	for i in n:
		sum += points[i].cross(points[(i + 1) % n])
	return sum * 0.5

static func _clean(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	var removed := true
	while removed and out.size() >= 3:
		removed = false
		var n := out.size()
		for i in n:
			var ab := out[i] - out[(i + n - 1) % n]
			var bc := out[(i + 1) % n] - out[i]
			if absf(ab.cross(bc)) <= COLLINEAR_EPS * ab.length() * bc.length():
				out.remove_at(i)
				removed = true
				break
	return out

static func _is_simple(points: PackedVector2Array) -> bool:
	var n := points.size()
	if n < 3 or absf(_area(points)) < MIN_AREA:
		return false
	for i in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		for j in range(i + 2, n - 1 if i == 0 else n):
			if Geometry2D.segment_intersects_segment(a, b, points[j], points[(j + 1) % n]) != null:
				return false
	return true
