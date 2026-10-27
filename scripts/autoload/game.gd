extends Node
## Autoload « Game » : point central du jeu.
## Déclare toutes les actions d'entrée en code, avec des touches PHYSIQUES
## (physical_keycode) : la touche A du clavier QWERTY correspond au Q de l'AZERTY,
## donc ZQSD fonctionne tel quel en AZERTY.
## Garde aussi l'inventaire et la liste des ressources (data/ressources.json).

## { id: { "nom": ..., "couleur": nom dans la palette } }, dans l'ordre d'affichage.
var ressources: Dictionary = {}
var inventaire := Inventaire.new()


func _ready() -> void:
	_declarer_actions()
	ressources = Donnees.charger_json("res://data/ressources.json")


func nom_ressource(id: String) -> String:
	return str(ressources[id]["nom"]) if ressources.has(id) else id


func couleur_ressource(id: String) -> Color:
	return Palette.couleur(str(ressources[id]["couleur"])) if ressources.has(id) else Color.MAGENTA


func _declarer_actions() -> void:
	_ajouter_action("move_left", [KEY_A, KEY_LEFT])
	_ajouter_action("move_right", [KEY_D, KEY_RIGHT])
	_ajouter_action("move_up", [KEY_W, KEY_UP])
	_ajouter_action("move_down", [KEY_S, KEY_DOWN])
	_ajouter_action("interact", [KEY_E, KEY_SPACE])
	_ajouter_action("pause", [KEY_ESCAPE])
	_ajouter_action("inventaire", [KEY_I, KEY_TAB])
	_ajouter_action("clic", [])
	var clic_gauche := InputEventMouseButton.new()
	clic_gauche.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("clic", clic_gauche)


func _ajouter_action(nom: StringName, touches: Array[Key]) -> void:
	if InputMap.has_action(nom):
		InputMap.erase_action(nom)
	InputMap.add_action(nom)
	for touche: Key in touches:
		var evenement := InputEventKey.new()
		evenement.physical_keycode = touche
		InputMap.action_add_event(nom, evenement)
