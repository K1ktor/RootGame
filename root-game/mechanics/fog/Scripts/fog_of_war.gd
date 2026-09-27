@tool
class_name FogOfWar
extends Node2D
# Mgła wojny odkrywana przez korzenie.
# W SubViewporcie trzyma "kopię" korzeni ze źródła (RootSpawner albo pojedynczy Root):
# dla każdej Line2D źródła (korzeń + odrosty) lustrzaną Line2D z tymi samymi punktami,
# ale grubszą o reveal_width_mult i białą. Ten obraz to maska dla shadera mgły.
# Nie skalujemy samego spawnera, bo przesunęłoby to korzenie, a drugi spawner
# wylosowałby inne ścieżki - dlatego kopiujemy geometrię co klatkę.
#
# Pozycja węzła = środek górnej krawędzi mgły. Postaw go na linii ziemi,
# a mgła rozciągnie się w dół o size.y i na boki o size.x / 2.

@export var source: Node2D                   # RootSpawner (albo Root), którego korzenie odkrywają mgłę
@export var size := Vector2(1280, 720):      # szerokość i głębokość mgły pod węzłem
	set(value):
		size = value.max(Vector2.ONE)
		_resize_mask()
		queue_redraw()

@export_group("Odkrywanie")
@export var reveal_width_mult: float = 4.0   # ile razy maska jest grubsza od korzenia (przed ulepszeniami)
@export var reveal_min_width: float = 24.0   # minimalna grubość odkrycia (lokalne jednostki korzenia)
@export_range(0.1, 1.0) var mask_scale: float = 0.5   # rozdzielczość maski względem obszaru (mniej = taniej i miękko)

@export_group("Rozmycie")
@export_range(0.0, 32.0, 0.1) var blur_radius: float = 3.0:   # promień rozmycia brzegu (w pikselach maski)
	set(value):
		blur_radius = value
		_set_shader_param("blur_radius", value)
@export_range(0.0, 1.0, 0.01) var edge_min: float = 0.05:     # od tej wartości maski mgła zaczyna znikać
	set(value):
		edge_min = value
		_set_shader_param("edge_min", value)
@export_range(0.0, 1.0, 0.01) var edge_max: float = 0.6:      # od tej wartości mgły nie ma wcale
	set(value):
		edge_max = value
		_set_shader_param("edge_max", value)

@export_group("Wygląd")
@export var fog_texture: Texture2D:          # brak = jednolity kolor
	set(value):
		fog_texture = value
		queue_redraw()
@export var fog_color: Color = Color(0.08, 0.06, 0.05, 1.0):   # kolor mgły (mnożony przez teksturę)
	set(value):
		fog_color = value
		queue_redraw()
@export var tile_texture := false:           # powtarzaj teksturę zamiast rozciągać na cały obszar
	set(value):
		tile_texture = value
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if value else CanvasItem.TEXTURE_REPEAT_PARENT_NODE
		queue_redraw()
@export_range(0.0, 1.0) var editor_preview_alpha: float = 0.6:   # przezroczystość podglądu w edytorze
	set(value):
		editor_preview_alpha = value
		queue_redraw()

var _viewport: SubViewport
var _mirror_root: Node2D
var _mirrors := {}                           # źródłowa Line2D -> lustrzana Line2D w masce
var _white: Texture2D


func _ready() -> void:
	process_priority = 100   # po korzeniach, żeby maska nie była klatkę w tyle
	_set_shader_param("blur_radius", blur_radius)
	_set_shader_param("edge_min", edge_min)
	_set_shader_param("edge_max", edge_max)
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white = ImageTexture.create_from_image(img)
	if Engine.is_editor_hint():
		set_process(false)
		_resize_mask()
		return

	_viewport = SubViewport.new()
	_viewport.transparent_bg = true   # tło przezroczyste = maska 0 = mgła
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_mirror_root = Node2D.new()
	_viewport.add_child(_mirror_root)
	_resize_mask()

	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("mask_texture", _viewport.get_texture())


func _process(_delta: float) -> void:
	_sync_mirrors()


func _draw() -> void:
	var color := fog_color
	if Engine.is_editor_hint():
		color.a *= editor_preview_alpha
	draw_texture_rect(fog_texture if fog_texture else _white, _area(), tile_texture, color)
	if Engine.is_editor_hint():
		draw_rect(_area(), Color(0.6, 0.6, 1.0, 0.8), false, 2.0)


func _area() -> Rect2:
	return Rect2(-size.x * 0.5, 0.0, size.x, size.y)


func _resize_mask() -> void:
	if not is_node_ready():
		return
	var area := _area()
	var mask_size := Vector2i((area.size * mask_scale).ceil()).max(Vector2i.ONE)
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("mask_area", Vector4(area.position.x, area.position.y, area.size.x, area.size.y))
		mat.set_shader_parameter("mask_texel_size", Vector2.ONE / Vector2(mask_size))
	if _viewport == null:
		return
	_viewport.size = mask_size
	_mirror_root.scale = Vector2.ONE * mask_scale
	_mirror_root.position = -area.position * mask_scale


func _set_shader_param(param: StringName, value: Variant) -> void:
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(param, value)


func _reveal_width(src: Line2D) -> float:
	return maxf(src.width * reveal_width_mult, reveal_min_width) * Upgrades.reveal_mult()


func _sync_mirrors() -> void:
	# Korzenie usunięte (np. RootSpawner.reset()) - mgła wraca
	for src in _mirrors.keys():
		if not is_instance_valid(src) or not src.is_inside_tree():
			_mirrors[src].queue_free()
			_mirrors.erase(src)
	if not is_instance_valid(source):
		return

	var to_local_xform := global_transform.affine_inverse()
	for node in source.find_children("*", "Line2D", true, false):
		var src := node as Line2D
		var mirror: Line2D = _mirrors.get(src)
		if mirror == null:
			mirror = _make_mirror(src)
			_mirrors[src] = mirror
		mirror.transform = to_local_xform * src.global_transform
		mirror.points = src.points
		# Bez width_curve - odkrycie ma stałą grubość, więc czubek też odsłania teren
		mirror.width = _reveal_width(src)
		mirror.visible = src.is_visible_in_tree()


func _make_mirror(src: Line2D) -> Line2D:
	var mirror := Line2D.new()
	mirror.default_color = Color.WHITE
	mirror.joint_mode = Line2D.LINE_JOINT_ROUND
	mirror.begin_cap_mode = Line2D.LINE_CAP_ROUND
	mirror.end_cap_mode = Line2D.LINE_CAP_ROUND
	mirror.antialiased = true
	_mirror_root.add_child(mirror)
	return mirror
