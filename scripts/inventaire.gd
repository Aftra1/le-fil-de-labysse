class_name Inventaire
extends RefCounted
## Inventaire unique : ressources du ciel et minerais de plongée.
## Le plafond par ressource est de 99 ; un entrepôt (machine du palier 2) le porte à 199.

const PLAFOND := 99
## Plafond le plus haut possible (entrepôt amélioré) : borne des quantités lues d'une sauvegarde.
const PLAFOND_MAX := 499

var plafond := PLAFOND
var _quantites: Dictionary = {}


func quantite(id: String) -> int:
	return int(_quantites.get(id, 0))


## Place restante avant le plafond pour cette ressource.
func place(id: String) -> int:
	return maxi(plafond - quantite(id), 0)


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


## Ramène chaque quantité sous le plafond (chargement d'une partie sans entrepôt).
func borner() -> void:
	for id: String in _quantites:
		_quantites[id] = mini(int(_quantites[id]), plafond)


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


## Inventaire lu depuis une sauvegarde : identifiants inconnus ignorés, quantités bornées à 0..PLAFOND_MAX
## (l'entrepôt, chargé ensuite avec les machines, fixe le vrai plafond).
static func depuis_dictionnaire(donnees: Dictionary, ids_connus: Array) -> Inventaire:
	var inventaire := Inventaire.new()
	inventaire.plafond = PLAFOND_MAX
	for id in donnees:
		var valeur = donnees[id]
		if ids_connus.has(str(id)) and (valeur is float or valeur is int):
			inventaire.ajouter(str(id), int(valeur))
	inventaire.plafond = PLAFOND
	return inventaire
