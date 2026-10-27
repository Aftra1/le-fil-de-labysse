extends Node
## Autoload « Game » : point central du jeu.
## Déclare toutes les actions d'entrée en code, avec des touches PHYSIQUES
## (physical_keycode) : la touche A du clavier QWERTY correspond au Q de l'AZERTY,
## donc ZQSD fonctionne tel quel en AZERTY.


func _ready() -> void:
	_declarer_actions()


func _declarer_actions() -> void:
	_ajouter_action("move_left", [KEY_A, KEY_LEFT])
	_ajouter_action("move_right", [KEY_D, KEY_RIGHT])
	_ajouter_action("move_up", [KEY_W, KEY_UP])
	_ajouter_action("move_down", [KEY_S, KEY_DOWN])
	_ajouter_action("interact", [KEY_E, KEY_SPACE])
	_ajouter_action("pause", [KEY_ESCAPE])


func _ajouter_action(nom: StringName, touches: Array[Key]) -> void:
	if InputMap.has_action(nom):
		InputMap.erase_action(nom)
	InputMap.add_action(nom)
	for touche: Key in touches:
		var evenement := InputEventKey.new()
		evenement.physical_keycode = touche
		InputMap.action_add_event(nom, evenement)
