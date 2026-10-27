class_name Atelier
extends RefCounted
## Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json)
## et installe les améliorations de la cloche, niveau par niveau.
## Les effets des niveaux (longueur du câble, halo, oxygène) sont dans data/ameliorations.json.
## Les niveaux installés sont gardés ici (la sauvegarde viendra à l'étape 5).

const AMELIORATIONS := ["cable", "lanterne", "reservoir"]

var inventaire: Inventaire
## Niveau installé de chaque amélioration : { "cable": 0, "lanterne": 0, "reservoir": 0 }
var niveaux: Dictionary = {}

var _recettes: Dictionary = {}
var _effets: Dictionary = {}


func _init(inventaire_joueur: Inventaire) -> void:
	inventaire = inventaire_joueur
	_recettes = Donnees.charger_json("res://data/recettes.json")
	_effets = Donnees.charger_json("res://data/ameliorations.json")
	for id: String in AMELIORATIONS:
		niveaux[id] = 0


# --- Composants -----------------------------------------------------------------------

func composants() -> Array:
	return (_recettes["composants"] as Dictionary).keys()


func ingredients_composant(id: String) -> Dictionary:
	return _recettes["composants"][id]["ingredients"]


func peut_fabriquer(id: String) -> bool:
	return manquants(ingredients_composant(id)).is_empty() and inventaire.place(id) > 0


func fabriquer(id: String) -> bool:
	if not peut_fabriquer(id):
		return false
	_payer(ingredients_composant(id))
	inventaire.ajouter(id)
	return true


# --- Améliorations ----------------------------------------------------------------------

func nom_amelioration(id: String) -> String:
	return str(_recettes["ameliorations"][id]["nom"])


func niveau(id: String) -> int:
	return int(niveaux.get(id, 0))


func niveau_max(id: String) -> int:
	return (_recettes["ameliorations"][id]["niveaux"] as Array).size()


func est_au_maximum(id: String) -> bool:
	return niveau(id) >= niveau_max(id)


## Recette du prochain niveau (vide si l'amélioration est au maximum).
func prochain_niveau(id: String) -> Dictionary:
	if est_au_maximum(id):
		return {}
	return _recettes["ameliorations"][id]["niveaux"][niveau(id)]


func peut_ameliorer(id: String) -> bool:
	var recette := prochain_niveau(id)
	return not recette.is_empty() and manquants(recette["ingredients"]).is_empty()


func ameliorer(id: String) -> bool:
	if not peut_ameliorer(id):
		return false
	_payer(prochain_niveau(id)["ingredients"])
	niveaux[id] = niveau(id) + 1
	return true


# --- Effets des niveaux installés -------------------------------------------------------------

func longueur_cable_m() -> float:
	return _effet("cable", "longueur_m")


func rayon_halo() -> float:
	return _effet("lanterne", "rayon_halo")


func obscurite_max() -> int:
	return int(_effet("lanterne", "obscurite_max"))


func oxygene_max() -> float:
	return _effet("reservoir", "oxygene_max")


# --- Outils ----------------------------------------------------------------------------------

## Ce qui manque pour une recette : { id: quantité manquante }.
func manquants(ingredients: Dictionary) -> Dictionary:
	var resultat := {}
	for id: String in ingredients:
		var manque := int(ingredients[id]) - inventaire.quantite(id)
		if manque > 0:
			resultat[id] = manque
	return resultat


func _payer(ingredients: Dictionary) -> void:
	for id: String in ingredients:
		inventaire.retirer(id, int(ingredients[id]))


func _effet(id: String, cle: String) -> float:
	var valeurs: Array = _effets[id][cle]
	return float(valeurs[mini(niveau(id), valeurs.size() - 1)])
