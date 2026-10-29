class_name Atelier
extends RefCounted
## Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json)
## et installe les améliorations de la cloche, niveau par niveau.
## Les effets des niveaux (longueur du câble, halo, oxygène) sont dans data/ameliorations.json.
## Les niveaux installés sont gardés ici et enregistrés dans la sauvegarde (voir charger_niveaux).
## Construit aussi les passerelles qui relient les îlots à l'île (une construction = un îlot relié)
## et les machines de l'île (data/machines.json), chacune sur un emplacement libre (la foreuse sur un
## filon). Les machines sont rangées par paliers : le palier 2 s'ouvre au premier corail rapporté,
## le palier 3 à la première pierre de braise (voir decouvrir). À partir du palier 2, chaque sorte de
## machine s'améliore : vitesse (production plus rapide) et capacité (réserve plus grande) ; le niveau 2
## se paie en matériaux raffinés. Le fourneau (palier 3) fabrique en boucle le raffiné choisi pour lui,
## avec les ingrédients de l'inventaire (voir consommer_fourneau).

const AMELIORATIONS := ["cable", "lanterne", "reservoir", "sac"]
const CONSTRUCTIONS := ["passerelle", "pont", "arche"]
## Ressource qui ouvre chaque palier de machines, la première fois qu'on la rapporte.
const PALIERS := {"corail": 2, "pierre_braise": 3}
const GENRES_AMELIORATION := ["vitesse", "capacite"]

var inventaire: Inventaire
## Niveau installé de chaque amélioration : { "cable": 0, "lanterne": 0, "reservoir": 0 }
var niveaux: Dictionary = {}
## Îlots reliés à l'île par une construction : [ "ilot_est", ... ]
var ilots_relies: Array = []
## Machines construites : { emplacement: machine }, ex. { "ile_ouest": "moulin" }.
var machines: Dictionary = {}
## Palier de machines atteint (1 à 3).
var palier := 1
## Améliorations des machines, par sorte : { "moulin": { "vitesse": 1, "capacite": 0 } }.
var niveaux_machines: Dictionary = {}
## Recette de chaque fourneau : { emplacement: raffiné } (vide : à l'arrêt).
var recettes_fourneau: Dictionary = {}
## Mesures : ressources dépensées à l'atelier et par les fourneaux depuis le début de la partie.
var depenses: Dictionary = {}
var consomme_fourneau: Dictionary = {}

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


## Message affiché sur l'île une fois la construction faite.
func annonce_construction(id: String) -> String:
	return str(_recettes["constructions"][id].get("annonce", "Construit : %s." % nom_construction(id)))


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


## Machines des paliers atteints (celles que l'atelier propose).
func machines_disponibles() -> Array:
	return liste_machines().filter(func(id: String) -> bool: return int(machine(id)["palier"]) <= palier)


## Réglages d'une machine : nom, palier, ressource, recharge_s, plafond, ingredients, effet, ameliorations.
func machine(id: String) -> Dictionary:
	return _machines["machines"][id]


func nom_machine(id: String) -> String:
	return str(machine(id)["nom"])


func sur_filon(id: String) -> bool:
	return bool(machine(id).get("sur_filon", false))


## Vrai pour une machine qui ne produit que pendant les plongées (sonde).
func en_plongee(id: String) -> bool:
	return bool(machine(id).get("en_plongee", false))


## Note les ressources rapportées d'une plongée ; renvoie vrai si un nouveau palier s'ouvre.
func decouvrir(ids: Array) -> bool:
	var avant := palier
	for id: String in ids:
		palier = maxi(palier, int(PALIERS.get(id, 1)))
	return palier > avant


## Palier lu depuis une sauvegarde. Une sauvegarde d'avant les paliers n'en a pas : on le déduit de ce
## qui a déjà coûté du corail ou de la pierre de braise (lanterne, réservoir, passerelle) et de l'inventaire.
func charger_palier(valeur) -> void:
	palier = clampi(int(valeur), 1, 3) if (valeur is float or valeur is int) else 1
	if niveau("lanterne") >= 1 or niveau("reservoir") >= 1 or est_relie("ilot_est"):
		palier = maxi(palier, 2)
	if niveau("lanterne") >= 2:
		palier = maxi(palier, 3)
	var presentes: Array = []
	for id: String in PALIERS:
		if inventaire.quantite(id) > 0:
			presentes.append(id)
	decouvrir(presentes)


# --- Emplacements -------------------------------------------------------------------------------

## Emplacements : [{ id, nom, position, ilot, filon? }], dans l'ordre du fichier de données.
func emplacements() -> Array:
	return _machines["emplacements"]


func emplacement(id: String) -> Dictionary:
	for donnees: Dictionary in emplacements():
		if str(donnees["id"]) == id:
			return donnees
	return {}


## Vrai pour un emplacement de foreuse (un filon de cristal solaire).
func est_filon(id: String) -> bool:
	return emplacement(id).has("filon")


## Un emplacement est utilisable s'il est sur l'île ou sur un îlot relié.
func emplacement_accessible(id: String) -> bool:
	var donnees := emplacement(id)
	if donnees.is_empty():
		return false
	var ilot := str(donnees["ilot"])
	return ilot == "" or est_relie(ilot)


func emplacement_libre(id: String) -> bool:
	return emplacement_accessible(id) and not machines.has(id)


## Emplacements accessibles et libres pour cette machine (sans machine : les emplacements au sol),
## dans l'ordre du fichier de données.
func emplacements_libres(id: String = "") -> Array:
	var filons := id != "" and sur_filon(id)
	var resultat: Array = []
	for donnees: Dictionary in emplacements():
		var lieu := str(donnees["id"])
		if emplacement_libre(lieu) and est_filon(lieu) == filons:
			resultat.append(lieu)
	return resultat


# --- Construction ------------------------------------------------------------------------------

## Nombre de machines « id » construites.
func nombre_machines(id: String) -> int:
	return machines.values().count(id)


func peut_construire_machine(id: String) -> bool:
	return int(machine(id)["palier"]) <= palier and not emplacements_libres(id).is_empty() \
		and manquants(machine(id)["ingredients"]).is_empty()


## Construit la machine sur « cible » si cet emplacement lui convient et est libre, sinon sur le
## premier qui convient. Renvoie l'emplacement choisi (vide si la construction est impossible).
func construire_machine(id: String, cible: String = "") -> String:
	if not peut_construire_machine(id):
		return ""
	var libres := emplacements_libres(id)
	var lieu := cible if libres.has(cible) else str(libres[0])
	_payer(machine(id)["ingredients"])
	machines[lieu] = id
	if machine(id).has("recettes"):
		recettes_fourneau[lieu] = ""
	_appliquer_entrepot()
	return lieu


## Machines lues depuis une sauvegarde : emplacements et machines inconnus ignorés.
## À appeler après charger_ilots (un emplacement d'îlot n'existe que si l'îlot est relié).
func charger_machines(donnees: Dictionary) -> void:
	machines.clear()
	for lieu: String in donnees:
		var id = donnees[lieu]
		if id is String and _machines["machines"].has(id) and emplacement_libre(lieu) \
				and est_filon(lieu) == sur_filon(id):
			machines[lieu] = id
	_appliquer_entrepot()


## Un entrepôt construit relève le plafond de l'inventaire (plusieurs entrepôts ne s'additionnent pas).
func _appliquer_entrepot() -> void:
	var plafond := Inventaire.PLAFOND
	for id: String in machines.values():
		var paliers = machine(id).get("plafond_inventaire", [])
		if paliers is Array and not paliers.is_empty():
			plafond = maxi(plafond, int(paliers[mini(niveau_machine(id, "capacite"), paliers.size() - 1)]))
	inventaire.plafond = plafond
	inventaire.borner()


# --- Améliorations des machines -------------------------------------------------------------

## Sortes de machines qui s'améliorent (le fourneau ne s'améliore pas).
func machines_ameliorables() -> Array:
	return liste_machines().filter(func(id: String) -> bool: return machine(id).has("ameliorations"))


func niveau_machine(id: String, genre: String) -> int:
	return int((niveaux_machines.get(id, {}) as Dictionary).get(genre, 0))


func niveau_machine_max(id: String, genre: String) -> int:
	if not machine(id).has("ameliorations"):
		return 0
	return (machine(id)["ameliorations"].get(genre, []) as Array).size()


## Améliorations proposées pour cette sorte de machine (« vitesse », « capacite » ; l'entrepôt : capacité).
func genres_amelioration(id: String) -> Array:
	if not machine(id).has("ameliorations"):
		return []
	return GENRES_AMELIORATION.filter(func(genre: String) -> bool: return machine(id)["ameliorations"].has(genre))


## Multiplicateur de vitesse ou de réserve à un niveau donné.
func facteur(genre: String, niveau: int) -> float:
	var facteurs: Array = _machines["facteurs"][genre]
	return float(facteurs[clampi(niveau, 0, facteurs.size() - 1)])


## Ingrédients du prochain niveau (vide au niveau maximal).
func prochaine_amelioration_machine(id: String, genre: String) -> Dictionary:
	var niveau := niveau_machine(id, genre)
	if niveau >= niveau_machine_max(id, genre):
		return {}
	return machine(id)["ameliorations"][genre][niveau]


## Possible dès le palier 2, si au moins une machine de cette sorte est construite.
func peut_ameliorer_machine(id: String, genre: String) -> bool:
	var ingredients := prochaine_amelioration_machine(id, genre)
	return palier >= 2 and nombre_machines(id) > 0 and not ingredients.is_empty() \
		and manquants(ingredients).is_empty()


func ameliorer_machine(id: String, genre: String) -> bool:
	if not peut_ameliorer_machine(id, genre):
		return false
	_payer(prochaine_amelioration_machine(id, genre))
	if not niveaux_machines.has(id):
		niveaux_machines[id] = {}
	niveaux_machines[id][genre] = niveau_machine(id, genre) + 1
	_appliquer_entrepot()
	return true


## Secondes par unité produite, vitesse comprise.
func recharge_machine(id: String) -> float:
	var facteurs: Array = _machines["facteurs"]["vitesse"]
	return float(machine(id)["recharge_s"]) / float(facteurs[mini(niveau_machine(id, "vitesse"), facteurs.size() - 1)])


## Réserve d'une machine, capacité comprise.
func plafond_machine(id: String) -> int:
	var facteurs: Array = _machines["facteurs"]["capacite"]
	return int(machine(id)["plafond"]) * int(facteurs[mini(niveau_machine(id, "capacite"), facteurs.size() - 1)])


## Plafond de l'inventaire que donnerait le prochain niveau de l'entrepôt.
func plafond_entrepot_suivant() -> int:
	var paliers: Array = machine("entrepot")["plafond_inventaire"]
	return int(paliers[mini(niveau_machine("entrepot", "capacite") + 1, paliers.size() - 1)])


# --- Fourneau ----------------------------------------------------------------------------------

## Raffinés que le fourneau sait faire, dans l'ordre du fichier de données.
func raffines() -> Array:
	return (machine("fourneau")["recettes"] as Dictionary).keys()


## Ingrédients d'un cycle du fourneau pour ce raffiné.
func recette_raffine(raffine: String) -> Dictionary:
	return machine("fourneau")["recettes"][raffine]


func recette_fourneau(lieu: String) -> String:
	return str(recettes_fourneau.get(lieu, ""))


func choisir_recette_fourneau(lieu: String, raffine: String) -> bool:
	if machines.get(lieu) != "fourneau" or (raffine != "" and not raffines().has(raffine)):
		return false
	recettes_fourneau[lieu] = raffine
	return true


## Un cycle du fourneau : prend les ingrédients dans l'inventaire s'ils y sont (vrai), sinon rien (faux).
func consommer_fourneau(raffine: String) -> bool:
	if raffine == "" or not manquants(recette_raffine(raffine)).is_empty():
		return false
	var ingredients := recette_raffine(raffine)
	for id: String in ingredients:
		inventaire.retirer(id, int(ingredients[id]))
		consomme_fourneau[id] = int(consomme_fourneau.get(id, 0)) + int(ingredients[id])
	return true


## Recettes des fourneaux lues depuis une sauvegarde (à appeler après charger_machines).
func charger_fourneaux(donnees: Dictionary) -> void:
	recettes_fourneau.clear()
	for lieu: String in machines:
		if machines[lieu] == "fourneau":
			var raffine = donnees.get(lieu, "")
			recettes_fourneau[lieu] = raffine if (raffine is String and raffines().has(raffine)) else ""


## Améliorations lues depuis une sauvegarde : sortes et genres inconnus ignorés, niveaux bornés.
func charger_niveaux_machines(donnees: Dictionary) -> void:
	niveaux_machines.clear()
	for id: String in machines_ameliorables():
		var niveaux = donnees.get(id)
		if not niveaux is Dictionary:
			continue
		for genre: String in GENRES_AMELIORATION:
			var valeur = niveaux.get(genre, 0)
			if (valeur is float or valeur is int) and int(valeur) > 0:
				if not niveaux_machines.has(id):
					niveaux_machines[id] = {}
				niveaux_machines[id][genre] = clampi(int(valeur), 0, niveau_machine_max(id, genre))
	_appliquer_entrepot()


# --- Effets des niveaux installés -------------------------------------------------------------

func longueur_cable_m() -> float:
	return _effet("cable", "longueur_m")


func rayon_halo() -> float:
	return _effet("lanterne", "rayon_halo")


func obscurite_max() -> int:
	return int(_effet("lanterne", "obscurite_max"))


func oxygene_max() -> float:
	return _effet("reservoir", "oxygene_max")


func places_sac() -> int:
	return int(_effet("sac", "places"))


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
		depenses[id] = int(depenses.get(id, 0)) + int(ingredients[id])


func _effet(id: String, cle: String) -> float:
	var valeurs: Array = _effets[id][cle]
	return float(valeurs[mini(niveau(id), valeurs.size() - 1)])
