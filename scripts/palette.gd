class_name Palette
extends RefCounted
## Palette fixe du jeu (data/palette.json) : toutes les couleurs affichées en viennent.
## Haut : ciel, nacre, crème, or. Bas : lagon, bleu nuit, abysse, noir, cyan, violet.

const CHEMIN := "res://data/palette.json"

static var _couleurs: Dictionary = {}


static func couleur(nom: String) -> Color:
	if _couleurs.is_empty():
		_charger()
	if not _couleurs.has(nom):
		push_error("Couleur absente de la palette : %s" % nom)
		return Color.MAGENTA
	return _couleurs[nom]


static func noms() -> Array:
	if _couleurs.is_empty():
		_charger()
	return _couleurs.keys()


static func contient(nom: String) -> bool:
	if _couleurs.is_empty():
		_charger()
	return _couleurs.has(nom)


static func _charger() -> void:
	var donnees: Dictionary = Donnees.charger_json(CHEMIN)
	for nom: String in donnees:
		_couleurs[nom] = Color.html(str(donnees[nom]))
