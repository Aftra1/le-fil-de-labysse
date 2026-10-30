class_name Carnet
extends RefCounted
## Carnet de collection : les trouvailles rares de l'abysse (data/trouvailles.json) et les machines déjà
## construites. Quatre pages : Perles du Lagon, Fossiles des Coraux, Reliques de la Faille (6 trouvailles
## chacune) et Machines (une case par sorte de machine). Une page complète donne un bonus durable.
## Le carnet appartient à la partie (gardé par l'atelier, enregistré dans la sauvegarde).

const PAGES_TROUVAILLES := ["lagon", "coraux", "faille"]

## Trouvailles découvertes, dans l'ordre de découverte.
var trouvees: Array = []
## Sortes de machines construites au moins une fois.
var machines_vues: Array = []
## Dernière trouvaille pas encore regardée dans le carnet (vide : rien de nouveau).
var a_voir := ""

var _donnees: Dictionary = {}
var _machines: Array = []


func _init() -> void:
	_donnees = Donnees.charger_json("res://data/trouvailles.json")
	_machines = (Donnees.charger_json("res://data/machines.json")["machines"] as Dictionary).keys()


# --- Contenu ---------------------------------------------------------------------------

## Pages : [{ id, titre, bonus, … }], dans l'ordre d'affichage.
func pages() -> Array:
	return _donnees["pages"]


func page(id: String) -> Dictionary:
	for donnees: Dictionary in pages():
		if str(donnees["id"]) == id:
			return donnees
	return {}


## Identifiants des cases d'une page (trouvailles de la zone, ou sortes de machines).
func cases(id_page: String) -> Array:
	if id_page == "machines":
		return _machines
	var resultat: Array = []
	for donnees: Dictionary in _donnees["trouvailles"]:
		if str(donnees["zone"]) == id_page:
			resultat.append(str(donnees["id"]))
	return resultat


## Réglages d'une trouvaille : { id, zone, nom, description } (vide si elle est inconnue).
func trouvaille(id: String) -> Dictionary:
	for donnees: Dictionary in _donnees["trouvailles"]:
		if str(donnees["id"]) == id:
			return donnees
	return {}


func chance_par_zone() -> float:
	return float(_donnees["chance_par_zone"])


func duree_minage() -> float:
	return float(_donnees["duree_minage"])


# --- Progression -------------------------------------------------------------------------

func a_trouve(id: String) -> bool:
	return trouvees.has(id)


## Note une trouvaille ; renvoie vrai si elle est nouvelle.
func trouver(id: String) -> bool:
	if trouvaille(id).is_empty() or trouvees.has(id):
		return false
	trouvees.append(id)
	a_voir = id
	return true


func voir_machine(id: String) -> void:
	if _machines.has(id) and not machines_vues.has(id):
		machines_vues.append(id)


## Trouvailles de cette zone pas encore découvertes.
func restantes(zone: String) -> Array:
	return cases(zone).filter(func(id: String) -> bool: return not trouvees.has(id))


func est_dans_carnet(id_page: String, id: String) -> bool:
	return machines_vues.has(id) if id_page == "machines" else trouvees.has(id)


func remplies(id_page: String) -> int:
	return cases(id_page).filter(func(id: String) -> bool: return est_dans_carnet(id_page, id)).size()


func page_complete(id_page: String) -> bool:
	return remplies(id_page) == cases(id_page).size()


## Pourcentage du carnet rempli (trouvailles et machines), arrondi à l'entier inférieur.
func pourcentage() -> int:
	var total := 0
	var faites := 0
	for donnees: Dictionary in pages():
		total += cases(str(donnees["id"])).size()
		faites += remplies(str(donnees["id"]))
	return floori(100.0 * faites / maxf(total, 1.0))


# --- Bonus des pages complètes ------------------------------------------------------------

## Vitesse de minage dans une zone (page de ses trouvailles complète : ×1,25).
func facteur_minage(zone: String) -> float:
	return float(page(zone).get("minage", 1.0)) if page_complete(zone) else 1.0


## Consommation d'air dans une zone (page de la Faille complète : ×0,8 dans la Faille).
func facteur_oxygene(zone: String) -> float:
	return float(page(zone).get("oxygene", 1.0)) if page_complete(zone) else 1.0


## Places de sac en plus (page des perles complète : +1).
func places_sac_bonus() -> int:
	for donnees: Dictionary in pages():
		if donnees.has("sac") and page_complete(str(donnees["id"])):
			return int(donnees["sac"])
	return 0


## Vitesse de production des machines (page des machines complète : ×1,1).
func facteur_machines() -> float:
	return float(page("machines").get("machines", 1.0)) if page_complete("machines") else 1.0


# --- Sauvegarde --------------------------------------------------------------------------------

func vers_dictionnaire() -> Dictionary:
	return {"trouvailles": trouvees.duplicate(), "machines": machines_vues.duplicate(), "a_voir": a_voir}


## Carnet lu depuis une sauvegarde : identifiants inconnus et doublons ignorés.
func charger(donnees: Dictionary) -> void:
	trouvees.clear()
	machines_vues.clear()
	var liste = donnees.get("trouvailles", [])
	if liste is Array:
		for id in liste:
			if id is String:
				trouver(id)
	liste = donnees.get("machines", [])
	if liste is Array:
		for id in liste:
			if id is String:
				voir_machine(id)
	var nouvelle = donnees.get("a_voir", "")
	a_voir = nouvelle if nouvelle is String and trouvees.has(nouvelle) else ""
