class_name UpgradeCardView
extends Button
# Klikalna karta na ekranie ulepszeń. Pokazuje teksturę i opis z UpgradeCard.

signal chosen(card: UpgradeCard)

@export var hover_scale: float = 1.06
@export var hover_duration: float = 0.12

var _card: UpgradeCard
var _tween: Tween

@onready var _description: Label = %Description


func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(_card))
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))
	resized.connect(func() -> void: pivot_offset = size * 0.5)


# Wołać po dodaniu do drzewa
func setup(card: UpgradeCard) -> void:
	_card = card
	_description.text = card.description


func _set_hovered(hovered: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * (hover_scale if hovered else 1.0), hover_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
