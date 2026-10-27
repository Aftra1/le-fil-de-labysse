class_name Inventaire
extends RefCounted
## Inventaire unique : ressources du ciel et minerais de plongée.

const PLAFOND := 99

var _quantites: Dictionary = {}


func quantite(id: String) -> int:
	return int(_quantites.get(id, 0))


## Place restante avant le plafond pour cette ressource.
func place(id: String) -> int:
	return PLAFOND - quantite(id)


## Ajoute dans la limite du plafond ; renvoie la quantité réellement ajoutée.
func ajouter(id: String, nombre: int = 1) -> int:
	var ajout := clampi(nombre, 0, place(id))
	if ajout > 0:
		_quantites[id] = quantite(id) + ajout
	return ajout


## Ajoute un butin { id: nombre } ; renvoie ce qui n'a pas pu entrer.
func ajouter_tout(butin: Dictionary) -> Dictionary:
	var refuse := {}
	for id: String in butin:
		var reste := int(butin[id]) - ajouter(id, int(butin[id]))
		if reste > 0:
			refuse[id] = reste
	return refuse


func retirer(id: String, nombre: int = 1) -> bool:
	if quantite(id) < nombre:
		return false
	_quantites[id] = quantite(id) - nombre
	return true


func total() -> int:
	var somme := 0
	for id: String in _quantites:
		somme += int(_quantites[id])
	return somme


# --- Sauvegarde -------------------------------------------------------------------------

## Quantités non nulles { id: nombre }.
func vers_dictionnaire() -> Dictionary:
	var resultat := {}
	for id: String in _quantites:
		if int(_quantites[id]) > 0:
			resultat[id] = int(_quantites[id])
	return resultat


## Inventaire lu depuis une sauvegarde : identifiants inconnus ignorés, quantités bornées à 0..PLAFOND.
static func depuis_dictionnaire(donnees: Dictionary, ids_connus: Array) -> Inventaire:
	var inventaire := Inventaire.new()
	for id in donnees:
		var valeur = donnees[id]
		if ids_connus.has(str(id)) and (valeur is float or valeur is int):
			inventaire.ajouter(str(id), int(valeur))
	return inventaire
