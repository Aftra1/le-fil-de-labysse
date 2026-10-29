class_name Atelier
extends RefCounted
## Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json)
## et installe les améliorations de la cloche, niveau par niveau.
## Les effets des niveaux (longueur du câble, halo, oxygène) sont dans data/ameliorations.json.
## Les niveaux installés sont gardés ici et enregistrés dans la sauvegarde (voir charger_niveaux).
## Construit aussi les passerelles qui relient les îlots à l'île (une construction = un îlot relié)
## et les machines de l'île (data/machines.json), chacune sur un emplacement libre.

const AMELIORATIONS := ["cable", "lanterne", "reservoir"]
const CONSTRUCTIONS := ["passerelle"]

var inventaire: Inventaire
## Niveau installé de chaque amélioration : { "cable": 0, "lanterne": 0, "reservoir": 0 }
var niveaux: Dictionary = {}
## Îlots reliés à l'île par une construction : [ "ilot_est", ... ]
var ilots_relies: Array = []
## Machines construites : { emplacement: machine }, ex. { "ile_ouest": "moulin" }.
var machines: Dictionary = {}

var _recettes: Dictionary = {}
var _effets: Dictionary = {}
var _machines: Dictionary = {}


func _init(inventaire_joueur: Inventaire) -> void:
	inventaire = inventaire_joueur
	_recettes = Donnees.charger_json("res://data/recettes.json")
	_effets = Donnees.charger_json("res://data/ameliorations.json")
	_machines = Donnees.charger_json("res://data/machines.json")
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
	return recette_niveau(id, niveau(id) + 1)


## Recette d'un niveau donné (1 = premier niveau), vide s'il n'existe pas.
func recette_niveau(id: String, cible: int) -> Dictionary:
	var niveaux_recettes: Array = _recettes["ameliorations"][id]["niveaux"]
	if cible < 1 or cible > niveaux_recettes.size():
		return {}
	return niveaux_recettes[cible - 1]


func peut_ameliorer(id: String) -> bool:
	var recette := prochain_niveau(id)
	return not recette.is_empty() and manquants(recette["ingredients"]).is_empty()


func ameliorer(id: String) -> bool:
	if not peut_ameliorer(id):
		return false
	_payer(prochain_niveau(id)["ingredients"])
	niveaux[id] = niveau(id) + 1
	return true


## Niveaux lus depuis une sauvegarde : améliorations inconnues ignorées, niveaux bornés à 0..max.
func charger_niveaux(donnees: Dictionary) -> void:
	for id: String in AMELIORATIONS:
		var valeur = donnees.get(id, 0)
		niveaux[id] = clampi(int(valeur), 0, niveau_max(id)) if (valeur is float or valeur is int) else 0


# --- Constructions (passerelles vers les îlots) -------------------------------------------

func nom_construction(id: String) -> String:
	return str(_recettes["constructions"][id]["nom"])


func ingredients_construction(id: String) -> Dictionary:
	return _recettes["constructions"][id]["ingredients"]


func effet_construction(id: String) -> String:
	return str(_recettes["constructions"][id]["effet"])


## Îlot relié par cette construction.
func ilot_de(id: String) -> String:
	return str(_recettes["constructions"][id]["ilot"])


func est_construite(id: String) -> bool:
	return est_relie(ilot_de(id))


func est_relie(ilot: String) -> bool:
	return ilots_relies.has(ilot)


func peut_construire(id: String) -> bool:
	return not est_construite(id) and manquants(ingredients_construction(id)).is_empty()


func construire(id: String) -> bool:
	if not peut_construire(id):
		return false
	_payer(ingredients_construction(id))
	ilots_relies.append(ilot_de(id))
	return true


## Îlots lus depuis une sauvegarde : seuls les îlots connus sont gardés, sans doublon.
func charger_ilots(donnees: Array) -> void:
	ilots_relies.clear()
	for id: String in CONSTRUCTIONS:
		var ilot := ilot_de(id)
		if donnees.has(ilot) and not ilots_relies.has(ilot):
			ilots_relies.append(ilot)


# --- Machines et emplacements -------------------------------------------------------------

## Identifiants des machines, dans l'ordre du fichier de données.
func liste_machines() -> Array:
	return (_machines["machines"] as Dictionary).keys()


## Réglages d'une machine : nom, ressource, recharge_s, plafond, ingredients, effet.
func machine(id: String) -> Dictionary:
	return _machines["machines"][id]


func nom_machine(id: String) -> String:
	return str(machine(id)["nom"])


## Emplacements : [{ id, nom, position, ilot }], dans l'ordre du fichier de données.
func emplacements() -> Array:
	return _machines["emplacements"]


func emplacement(id: String) -> Dictionary:
	for donnees: Dictionary in emplacements():
		if str(donnees["id"]) == id:
			return donnees
	return {}


## Un emplacement est utilisable s'il est sur l'île ou sur un îlot relié.
func emplacement_accessible(id: String) -> bool:
	var donnees := emplacement(id)
	if donnees.is_empty():
		return false
	var ilot := str(donnees["ilot"])
	return ilot == "" or est_relie(ilot)


func emplacement_libre(id: String) -> bool:
	return emplacement_accessible(id) and not machines.has(id)


## Emplacements accessibles et libres, dans l'ordre du fichier de données.
func emplacements_libres() -> Array:
	var resultat: Array = []
	for donnees: Dictionary in emplacements():
		if emplacement_libre(str(donnees["id"])):
			resultat.append(str(donnees["id"]))
	return resultat


## Nombre de machines « id » construites.
func nombre_machines(id: String) -> int:
	return machines.values().count(id)


func peut_construire_machine(id: String) -> bool:
	return not emplacements_libres().is_empty() and manquants(machine(id)["ingredients"]).is_empty()


## Construit la machine sur « cible » si cet emplacement est libre, sinon sur le premier libre.
## Renvoie l'emplacement choisi (vide si la construction est impossible).
func construire_machine(id: String, cible: String = "") -> String:
	if not peut_construire_machine(id):
		return ""
	var lieu := cible if emplacement_libre(cible) else str(emplacements_libres()[0])
	_payer(machine(id)["ingredients"])
	machines[lieu] = id
	return lieu


## Machines lues depuis une sauvegarde : emplacements et machines inconnus ignorés.
## À appeler après charger_ilots (un emplacement d'îlot n'existe que si l'îlot est relié).
func charger_machines(donnees: Dictionary) -> void:
	machines.clear()
	for lieu: String in donnees:
		var id = donnees[lieu]
		if id is String and _machines["machines"].has(id) and emplacement_libre(lieu):
			machines[lieu] = id


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
