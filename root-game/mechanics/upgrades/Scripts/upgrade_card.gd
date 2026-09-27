class_name UpgradeCard
extends Resource
# Jedna karta ulepszenia. Nową tworzysz przez FileSystem > New Resource > UpgradeCard,
# potem dodajesz ją do card_pool w UpgradeScreen.tscn.

enum Id { LONGER_ROOTS, MORE_OFFSHOOTS, LONGER_OFFSHOOTS, MORE_ROOTS, SPLIT_CHANCE }

@export var card: Texture2D
@export_multiline var description: String = ""
@export var upgrade_id: Id = Id.LONGER_ROOTS
