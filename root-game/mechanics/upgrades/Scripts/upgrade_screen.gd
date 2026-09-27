class_name UpgradeScreen
extends CanvasLayer
# Po ukończeniu levela (Signals.level_complete) i rozpłynięciu się mgły wojny pokazuje kilka losowych kart z card_pool.
# Gracz wybiera jedną, trafia ona do autoloadu Upgrades i leci Signals.upgrade_chosen.

@export var card_pool: Array[UpgradeCard] = []
@export var card_view_scene: PackedScene
@export_range(1, 5) var cards_to_show: int = 3
@export var pause_game: bool = true

@onready var _cards_box: HBoxContainer = %Cards

var _waiting_for_fog := false


func _ready() -> void:
	hide()
	Signals.level_complete.connect(_on_level_complete)


func _on_level_complete() -> void:
	if visible or _waiting_for_fog:
		return
	# Najpierw mgła wojny ma się całkiem rozpłynąć, dopiero potem karty
	_waiting_for_fog = true
	await get_tree().process_frame   # mgły mogą odebrać level_complete po nas
	while _any_fog_dissolving():
		await get_tree().process_frame
	_waiting_for_fog = false
	_show_cards()


func _any_fog_dissolving() -> bool:
	for fog in get_tree().get_nodes_in_group(FogOfWar.GROUP):
		if (fog as FogOfWar).is_dissolving():
			return true
	return false


func _show_cards() -> void:
	var options := _pick_cards()
	if options.is_empty():
		return  # wszystko wymaksowane
	_clear_cards()
	for card in options:
		var view := card_view_scene.instantiate() as UpgradeCardView
		_cards_box.add_child(view)
		view.setup(card)
		view.chosen.connect(_on_card_chosen)
	show()
	(_cards_box.get_child(0) as Control).grab_focus()
	if pause_game:
		get_tree().paused = true


func _pick_cards() -> Array[UpgradeCard]:
	var available: Array[UpgradeCard] = []
	for card in card_pool:
		if card and Upgrades.is_available(card.upgrade_id):
			available.append(card)
	available.shuffle()
	available.resize(mini(cards_to_show, available.size()))
	return available


func _on_card_chosen(card: UpgradeCard) -> void:
	Upgrades.apply(card)
	hide()
	_clear_cards()
	if pause_game:
		get_tree().paused = false

	print("SKibidi")

	Signals.upgrade_chosen.emit(card)


func _clear_cards() -> void:
	for child in _cards_box.get_children():
		_cards_box.remove_child(child)
		child.queue_free()
