extends Node
## Autoload « Game » : point central du jeu.
## Déclare toutes les actions d'entrée en code, avec des touches PHYSIQUES
## (physical_keycode) : la touche A du clavier QWERTY correspond au Q de l'AZERTY,
## donc ZQSD fonctionne tel quel en AZERTY.

## Butin rangé sur l'île : { "cristal": 3, "corail": 1 }.
## Provisoire (étape 2) : l'inventaire et la sauvegarde viendront plus tard.
var stock_ile: Dictionary = {}


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


func deposer_butin(butin: Dictionary) -> void:
	for minerai: String in butin:
		stock_ile[minerai] = int(stock_ile.get(minerai, 0)) + int(butin[minerai])
