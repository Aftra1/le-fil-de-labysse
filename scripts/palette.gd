class_name Palette
extends RefCounted
## Palette fixe du jeu (data/palette.json) : toutes les couleurs affichées en viennent.
## Elle est organisée en rampes, une par matière (ciel, nuage, roche, herbe, or…), du plus sombre
## au plus clair : les ombres tirent vers le bleu-vert, les lumières vers le jaune.
## Une couleur se nomme « rampe.indice » (ex. « herbe.4 ») ou par un alias (ex. « contour_haut »).

const CHEMIN := "res://data/palette.json"

static var _couleurs: Dictionary = {}     # nom -> Color (entrées des rampes et alias)
static var _rampes: Dictionary = {}       # rampe -> Array[Color]
static var _position: Dictionary = {}     # couleur RGBA32 -> [rampe, indice]
static var _entrees: Array = []           # noms « rampe.indice », sans les alias


static func couleur(nom: String) -> Color:
	_charger()
	if not _couleurs.has(nom):
		push_error("Couleur absente de la palette : %s" % nom)
		return Color.MAGENTA
	return _couleurs[nom]


## Tons d'une rampe, du plus sombre au plus clair.
static func rampe(nom: String) -> Array:
	_charger()
	return _rampes.get(nom, [])


## Noms de toutes les couleurs (une par entrée de rampe, sans les alias).
static func noms() -> Array:
	_charger()
	return _entrees


static func contient(nom: String) -> bool:
	_charger()
	return _couleurs.has(nom)


## Le ton juste en dessous dans la même rampe (ombre portée « un ton plus sombre »).
static func plus_sombre(teinte: Color, crans: int = 1) -> Color:
	_charger()
	var cle := teinte.to_rgba32()
	if not _position.has(cle):
		return teinte
	var ou: Array = _position[cle]
	var tons: Array = _rampes[ou[0]]
	return tons[maxi(int(ou[1]) - crans, 0)]


## Le ton juste au-dessus dans la même rampe (reflets, repères).
static func plus_clair(teinte: Color, crans: int = 1) -> Color:
	_charger()
	var cle := teinte.to_rgba32()
	if not _position.has(cle):
		return teinte
	var ou: Array = _position[cle]
	var tons: Array = _rampes[ou[0]]
	return tons[mini(int(ou[1]) + crans, tons.size() - 1)]


static func _charger() -> void:
	if not _couleurs.is_empty():
		return
	var donnees: Dictionary = Donnees.charger_json(CHEMIN)
	var rampes: Dictionary = donnees["rampes"]
	for nom_rampe: String in rampes:
		var tons: Array = []
		for i in (rampes[nom_rampe] as Array).size():
			var teinte := Color.html(str(rampes[nom_rampe][i]))
			var nom := "%s.%d" % [nom_rampe, i]
			tons.append(teinte)
			_couleurs[nom] = teinte
			_entrees.append(nom)
			_position[teinte.to_rgba32()] = [nom_rampe, i]
		_rampes[nom_rampe] = tons
	var alias: Dictionary = donnees["alias"]
	for nom: String in alias:
		_couleurs[nom] = _couleurs[str(alias[nom])]
