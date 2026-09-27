extends Node
# Ulepszenia wybrane przez gracza. Autoload, żeby przetrwały zmianę levela.
# RootSpawner czyta stąd bonusy przy każdym spawnie korzenia.

const ROOT_LENGTH_BONUS := 0.2        # +20% długości segmentu korzenia za poziom
const OFFSHOOTS_BONUS := 1            # +1 odrost na segment za poziom
const OFFSHOOT_LENGTH_BONUS := 0.3    # +30% długości odrostu za poziom
const ROOTS_BONUS := 1                # +1 korzeń za poziom
const SPLIT_CHANCE_BONUS := 0.15      # +15% szansy na rozdwojenie za poziom

# Maksymalny poziom ulepszenia (brak wpisu = bez limitu). Wymaksowane karty nie są losowane.
const MAX_LEVEL := {
	UpgradeCard.Id.MORE_ROOTS: 4,
	UpgradeCard.Id.SPLIT_CHANCE: 4,
	UpgradeCard.Id.MORE_OFFSHOOTS: 8,
	UpgradeCard.Id.LONGER_OFFSHOOTS: 3,
}

var _levels := {}  # UpgradeCard.Id -> ile razy wybrane


func apply(card: UpgradeCard) -> void:
	_levels[card.upgrade_id] = level(card.upgrade_id) + 1


func level(id: UpgradeCard.Id) -> int:
	return _levels.get(id, 0)


func is_available(id: UpgradeCard.Id) -> bool:
	return not MAX_LEVEL.has(id) or level(id) < MAX_LEVEL[id]


# Nowa gra - zeruje wszystkie ulepszenia
func clear() -> void:
	_levels.clear()


func root_length_mult() -> float:
	return 1.0 + ROOT_LENGTH_BONUS * level(UpgradeCard.Id.LONGER_ROOTS)


func extra_offshoots() -> int:
	return OFFSHOOTS_BONUS * level(UpgradeCard.Id.MORE_OFFSHOOTS)


func offshoot_length_mult() -> float:
	return 1.0 + OFFSHOOT_LENGTH_BONUS * level(UpgradeCard.Id.LONGER_OFFSHOOTS)


func extra_roots() -> int:
	return ROOTS_BONUS * level(UpgradeCard.Id.MORE_ROOTS)


func split_chance() -> float:
	return minf(SPLIT_CHANCE_BONUS * level(UpgradeCard.Id.SPLIT_CHANCE), 1.0)
