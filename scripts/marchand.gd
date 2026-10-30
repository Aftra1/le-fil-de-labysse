class_name Marchand
extends RefCounted
## Le vieux marchand de vent (data/marchand.json) : son dirigeable passe au-dessus de l'île environ toutes
## les 4 min de jeu (île et plongée comptées, pas le jeu fermé) et reste 60 s. S'il arrive pendant une
## plongée, il attend le retour sur l'île et reste alors ses 60 s ; s'il était déjà là, il ne repart jamais
## pendant une plongée : au retour, il reste encore au moins 20 s (« reste_au_retour_s »).
## À chaque passage, il propose 3 échanges tirés parmi ceux du palier atteint (chacun une fois) et dit une
## réplique (une par visite, dans l'ordre). Il ne rachète que des surplus (surtout les ouates du filet)
## contre des ressources de la surface : jamais un minerai de l'abysse ni ce qui en est fait (« interdits »),
## pour qu'aucun échange ne remplace une plongée. Aucun échange n'est obligatoire, rien n'est perdu
## si on le manque. Il appartient à la partie (gardé par l'atelier, enregistré dans la sauvegarde).

## Secondes avant le prochain passage (0 : il arrive dès qu'on est sur l'île).
var attente := 0.0
## Secondes qu'il reste encore au-dessus de l'île (0 : il n'est pas là).
var restant := 0.0
## Échanges proposés pendant ce passage, et ceux déjà faits.
var offres: Array = []
var faits: Array = []
## Passages déjà commencés (la réplique suit ce compte).
var visites := 0
## Mesures : ressources données au marchand et reçues de lui depuis le début de la partie.
var vendu: Dictionary = {}
var recu: Dictionary = {}

var _donnees: Dictionary = {}
var _hasard := RandomNumberGenerator.new()


func _init() -> void:
	_donnees = Donnees.charger_json("res://data/marchand.json")
	attente = float(_donnees["premier_passage_s"])
	_hasard.randomize()


# --- Réglages ----------------------------------------------------------------------------------

func duree() -> float:
	return float(_donnees["duree_s"])


func intervalle() -> float:
	return float(_donnees["intervalle_s"])


## Tous les échanges : [{ id, palier, donne, recoit }], dans l'ordre du fichier de données.
func echanges() -> Array:
	return _donnees["echanges"]


func echange(id: String) -> Dictionary:
	for donnees: Dictionary in echanges():
		if str(donnees["id"]) == id:
			return donnees
	return {}


## Ce que le marchand ne donne jamais (minerais de l'abysse et ce qui en est fait).
func interdits() -> Array:
	return _donnees["interdits"]


func repliques() -> Array:
	return _donnees["repliques"]


## Réplique du passage en cours (ou du dernier).
func replique() -> String:
	if visites <= 0:
		return ""
	return str(repliques()[(visites - 1) % repliques().size()])


# --- Passages ----------------------------------------------------------------------------------

func est_present() -> bool:
	return restant > 0.0


## Secondes depuis son arrivée (pour l'animation du dirigeable).
func temps_present() -> float:
	return duree() - restant if est_present() else 0.0


## Fait avancer le temps de « secondes ». Sur l'île : il arrive quand l'attente est finie, puis repart à
## la fin de son passage ; hors de l'île (plongée) : l'attente avance sans jamais le faire arriver, et son
## passage aussi, sans le faire partir (il reste au moins « reste_au_retour_s » pour le retour).
## Renvoie « arrivee », « depart » ou une chaîne vide.
func avancer(secondes: float, sur_ile: bool, palier: int) -> String:
	if est_present():
		if not sur_ile:
			restant = maxf(restant - secondes, minf(float(_donnees["reste_au_retour_s"]), restant))
			return ""
		restant -= secondes
		if restant > 0.0:
			return ""
		restant = 0.0
		attente = intervalle()
		offres.clear()
		faits.clear()
		return "depart"
	attente = maxf(attente - secondes, 0.0)
	if sur_ile and attente <= 0.0:
		arriver(palier)
		return "arrivee"
	return ""


## Début d'un passage : offres tirées parmi les échanges du palier (complétées par les paliers d'avant
## s'il en manque), et réplique suivante.
func arriver(palier: int) -> void:
	restant = duree()
	attente = 0.0
	visites += 1
	faits.clear()
	offres.clear()
	var nombre := int(_donnees["offres_par_passage"])
	for niveau in range(palier, 0, -1):
		var possibles: Array = []
		for donnees: Dictionary in echanges():
			if int(donnees["palier"]) == niveau:
				possibles.append(str(donnees["id"]))
		while not possibles.is_empty() and offres.size() < nombre:
			offres.append(possibles.pop_at(_hasard.randi_range(0, possibles.size() - 1)))
		if offres.size() >= nombre:
			break


# --- Échanges -----------------------------------------------------------------------------------

## Vrai si cet échange est proposé maintenant, pas encore fait, payable et rangeable dans l'inventaire.
func peut_echanger(id: String, inventaire: Inventaire) -> bool:
	if not est_present() or not offres.has(id) or faits.has(id):
		return false
	var donnees := echange(id)
	for ressource: String in donnees["donne"]:
		if inventaire.quantite(ressource) < int(donnees["donne"][ressource]):
			return false
	for ressource: String in donnees["recoit"]:
		var rendu := int(donnees["donne"].get(ressource, 0))
		if inventaire.place(ressource) + rendu < int(donnees["recoit"][ressource]):
			return false
	return true


func echanger(id: String, inventaire: Inventaire) -> bool:
	if not peut_echanger(id, inventaire):
		return false
	var donnees := echange(id)
	for ressource: String in donnees["donne"]:
		inventaire.retirer(ressource, int(donnees["donne"][ressource]))
		vendu[ressource] = int(vendu.get(ressource, 0)) + int(donnees["donne"][ressource])
	for ressource: String in donnees["recoit"]:
		inventaire.ajouter(ressource, int(donnees["recoit"][ressource]))
		recu[ressource] = int(recu.get(ressource, 0)) + int(donnees["recoit"][ressource])
	faits.append(id)
	return true


# --- Sauvegarde --------------------------------------------------------------------------------

func vers_dictionnaire() -> Dictionary:
	return {"attente": attente, "restant": restant, "offres": offres.duplicate(), "faits": faits.duplicate(),
		"visites": visites}


## Marchand lu depuis une sauvegarde : valeurs bornées, échanges inconnus ignorés. Sans données (sauvegarde
## d'avant le marchand), il passe pour la première fois après l'attente habituelle.
func charger(donnees: Dictionary) -> void:
	var premier := float(_donnees["premier_passage_s"])
	attente = _nombre(donnees.get("attente"), premier, 0.0, maxf(intervalle(), premier))
	restant = _nombre(donnees.get("restant"), 0.0, 0.0, duree())
	visites = int(_nombre(donnees.get("visites"), 0.0, 0.0, 1e6))
	offres.clear()
	faits.clear()
	for cle: String in ["offres", "faits"]:
		var liste = donnees.get(cle, [])
		if liste is Array:
			for id in liste:
				if id is String and not echange(id).is_empty():
					(offres if cle == "offres" else faits).append(id)
	if est_present() and offres.is_empty():
		restant = 0.0
		attente = 0.0


func _nombre(valeur, defaut: float, minimum: float, maximum: float) -> float:
	if not (valeur is float or valeur is int):
		return defaut
	return clampf(float(valeur), minimum, maximum)
