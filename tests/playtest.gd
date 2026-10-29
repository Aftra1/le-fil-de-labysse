extends SceneTree
## Playtest robot : joue une partie entière comme un joueur, avec de vrais évènements clavier et
## souris (Input.parse_input_event), sans téléporter la cloche ni toucher à l'inventaire.
##
## Déroulé : écran titre → Nouvelle partie → récolte sur l'île → plongées (minage du cristal de lagon)
## → fils de nuage → câble tressé → moulin à vent (clic sur un emplacement libre) → plongées dans la
## Forêt de coraux (le premier corail ouvre le palier 2) → lanterne → filet à nuages → réservoir → sac à 12 places →
## pont suspendu (îlot du nord) → foreuse solaire sur un filon → passerelle → entrepôt → … → lanterne 2 →
## palier 3 : fourneau (le robot règle sa recette d'un clic sur le fourneau selon le raffiné qui manque, et
## l'arrête quand rien ne manque) → sonde → arche de braise (100 vents : entrepôt) → sac à 16 places →
## niveaux 2 du moulin, de la foreuse et du filet → entrepôt à 499.
## Mesures d'économie : origine de chaque ressource (machines, sources de l'île, plongées, fourneau) et où elle
## est dépensée (atelier, fourneau).
## passerelle de nuage → réservoir et câble de niveau 2 → plongées dans la Faille volcanique
## (pierre de braise) → lanterne de niveau 2 → récolte du bassin de lumière sur l'îlot.
##
## Conduite de la cloche : touches ZQSD (physiques) avec l'inertie du jeu ; le robot relâche les
## touches à la distance de freinage, mine en maintenant E, et remonte quand l'oxygène restant
## couvre tout juste la remontée plus une marge (comme un joueur qui surveille sa jauge).
##
## Deux profils (-- --profil=parfait ou --profil=humain) :
## - parfait : connaît la position de tous les gisements, réagit à chaque image, freine au pixel près ;
## - humain : ne voit que les gisements à l'écran et éclairés (hors de l'obscurité, ou dans le halo
##   de la lanterne), explore la zone en zigzag pour les trouver, ne réagit que toutes les 0,3 à 0,6 s,
##   estime mal ses distances de freinage, garde une marge d'air plus grande et va moins vite à la souris.
##
## Mesures (temps de jeu, 60 images par seconde) écrites dans le fichier passé après « -- » :
##   godot --headless --path . --fixed-fps 60 --script res://tests/playtest.gd -- --profil=humain --sortie=<fichier.json>
## Les machines sont vidées d'un clic quand leur ressource manque (avant l'éolienne et les nuages).
## Mode vidéo (séquence courte avec les machines, pour Movie Maker) : -- --video
## Voir tests/playtest.sh et docs/playtest.md.

const IPS := 60.0                         # images de physique par seconde
const SAUVEGARDE := "user://playtest_sauvegarde.json"
const DUREE_MAX_S := 3600.0               # garde-fou : une partie ne doit pas dépasser une heure
const ATTENTE_SIGNALEE_S := 10.0          # attentes « sans rien à faire » rapportées

# Conduite de la cloche (mêmes valeurs que scripts/bell.gd)
const VITESSE_CLOCHE := 110.0
const FREINAGE := 120.0

## Réglages des deux profils. geste : déplacer la souris vers une cible ; clic : durée d'un clic ;
## reflexion : lecture avant de cliquer dans un menu ; reaction : intervalle entre deux décisions en
## plongée [min, max] ; erreur_freinage : erreur sur la distance de freinage estimée (±) ;
## marge_oxygene : air gardé en réserve à l'arrivée en surface ; blocage : abandon d'une cible si on
## ne s'en approche plus ; connait_gisements : voit tous les gisements, même hors de l'écran ;
## distance_minage : distance à laquelle on maintient E (le jeu le permet à 28 px et l'affiche) ;
## approche_douce : près de la cible (APPROCHE px), on n'accélère plus au-delà de VITESSE_APPROCHE,
## comme un joueur qui tapote les touches pour se placer.
const PROFILS := {
	"parfait": {
		"geste": 0.25, "clic": 0.12, "reflexion": 0.4, "reaction": [0.0, 0.0], "erreur_freinage": 0.0,
		"marge_oxygene": 8.0, "blocage": 6.0, "connait_gisements": true, "lecture_butin": 1.0,
		"distance_minage": 18.0, "approche_douce": false,
	},
	"humain": {
		"geste": 0.5, "clic": 0.2, "reflexion": 1.0, "reaction": [0.3, 0.6], "erreur_freinage": 0.4,
		"marge_oxygene": 25.0, "blocage": 10.0, "connait_gisements": false, "lecture_butin": 2.0,
		"distance_minage": 24.0, "approche_douce": true,
	},
}
const ECART_VISEE := 6.0                  # le joueur humain vise à quelques pixels près
const APPROCHE := 70.0
const VITESSE_APPROCHE := 35.0

# Objectifs, dans l'ordre où un joueur les poursuit : [genre, id, niveau visé]
const OBJECTIFS := [
	["amelioration", "cable", 1],
	["machine", "moulin", 1],
	["amelioration", "lanterne", 1],
	["machine", "filet", 1],
	["amelioration", "reservoir", 1],
	["amelioration", "sac", 1],
	["construction", "pont", 1],
	["machine", "foreuse", 1],
	["construction", "passerelle", 1],
	["machine", "entrepot", 1],
	["amelioration", "reservoir", 2],
	["amelioration", "cable", 2],
	["amelioration_machine", "moulin", "vitesse", 1],
	["amelioration_machine", "foreuse", "capacite", 1],
	["amelioration", "lanterne", 2],
	["machine", "fourneau", 1],
	["machine", "sonde", 1],
	["construction", "arche", 1],
	["amelioration", "sac", 2],
	["amelioration_machine", "moulin", "vitesse", 2],
	["amelioration_machine", "moulin", "capacite", 1],
	["amelioration_machine", "moulin", "capacite", 2],
	["amelioration_machine", "foreuse", "capacite", 2],
	["amelioration_machine", "filet", "vitesse", 1],
	["amelioration_machine", "filet", "vitesse", 2],
	["amelioration_machine", "entrepot", "capacite", 1],
]
const MINERAIS := ["pierre_braise", "corail", "cristal_lagon"]   # du plus profond au moins profond
## Le robot ne réunit que les ressources des quelques prochains objectifs (comme un joueur qui avance pas
## à pas), pas celles de toute la partie d'un coup.
const HORIZON_OBJECTIFS := 3

var _video := false
var _sortie := ""
var _nom_profil := "parfait"
var _profil: Dictionary = PROFILS["parfait"]
var _hasard := RandomNumberGenerator.new()
var _zones: Array = []
var _game: Node
var _jeu: Node
var _ile: Node
var _atelier_ui: Node
var _ile_script: GDScript

var _images := 0
var _temps := {"titre": 0, "ile": 0, "transition": 0, "plongee": 0}
var _touches_appuyees := {}
var _plongees: Array = []
var _attentes: Array = []                 # [debut_s, duree_s, raison]
var _debut_attente := -1.0
var _raison_attente := ""
var _evenements: Array = []               # [temps_s, texte]
var _manques := {}                        # ressource -> secondes passées à l'attendre sur l'île
var _fabrications := {}                   # id -> nombre
var _bassin_recolte := 0
var _machines_construites: Array = []     # [temps_s, machine, emplacement]
var _machines_recolte := {}               # ressource -> unités récoltées sur les machines
var _paliers := {1: 0.0}                  # palier -> temps (s) où il s'ouvre
var _ile_recolte := {}                    # ressource -> unités récoltées sur les sources de l'île
var _plongee_recolte := {}                # ressource -> unités rapportées des plongées
var _fourneau_recolte := {}               # raffiné -> unités récupérées au fourneau
var _inventaire_max := {}                 # ressource -> plus haute quantité vue (au-delà de 99 : grâce à l'entrepôt)


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--video":
			_video = true
		elif argument.begins_with("--sortie="):
			_sortie = argument.trim_prefix("--sortie=")
		elif argument.begins_with("--profil="):
			_nom_profil = argument.trim_prefix("--profil=")
	_profil = PROFILS[_nom_profil]
	_hasard.randomize()
	_zones = Donnees.charger_json("res://data/zones.json")
	_lancer()


func _lancer() -> void:
	await process_frame
	_game = root.get_node("Game")
	_ile_script = load("res://scripts/ile.gd")
	Sauvegarde.chemin = SAUVEGARDE
	_effacer_sauvegarde()
	if _video:
		_preparer_sauvegarde_video()
	_jeu = load("res://scenes/jeu.tscn").instantiate()
	_jeu.action_quitter = func() -> void: pass
	root.add_child(_jeu)
	_ile = _jeu.get_node("Ile")
	_atelier_ui = _ile.get_node("Atelier")
	await _attendre(1.0)

	if _video:
		# Écran titre : Continuer (partie préparée, voir _preparer_sauvegarde_video)
		await _cliquer(_centre(_jeu.get_node("EcranTitre").bouton_continuer))
		_noter("Continuer")
		await _sequence_video()
	else:
		# Écran titre : Nouvelle partie (pas de sauvegarde, donc pas de confirmation)
		await _cliquer(_centre(_jeu.get_node("EcranTitre").bouton_nouvelle))
		_noter("Nouvelle partie")
		await _partie_complete()
	_relacher_tout()
	_effacer_sauvegarde()
	await _couper_son_et_quitter(0)


# --- Partie complète ------------------------------------------------------------------

func _partie_complete() -> void:
	while _secondes() < DUREE_MAX_S:
		await _fabriquer_tout()
		if _objectifs_restants().is_empty():
			break
		var besoins := _besoins()
		var a_fait := await _gerer_fourneaux()
		a_fait = await _recolter_utile(besoins) or a_fait
		besoins = _besoins()
		if _plongee_utile(besoins):
			_fin_attente()
			await _plonger(besoins)
			continue
		if a_fait:
			_fin_attente()
		else:
			_debut_attente_si_besoin(besoins)
			await _attendre(0.5)
			_compter_manques(besoins, 0.5)
	_fin_attente()
	_noter("Toutes les améliorations et la passerelle sont installées")
	await _recolter_bassin()
	_ecrire_mesures()


## Matières premières encore nécessaires pour les prochains objectifs (inventaire déduit).
func _besoins() -> Dictionary:
	var atelier: Atelier = _game.atelier
	var inventaire: Inventaire = _game.inventaire
	var composants := {}
	var brut := {}
	for objectif: Array in _objectifs_proches():
		var ingredients := _ingredients_objectif(objectif)
		for id: String in ingredients:
			if atelier.composants().has(id):
				composants[id] = int(composants.get(id, 0)) + int(ingredients[id])
			elif not atelier.raffines().has(id):
				brut[id] = int(brut.get(id, 0)) + int(ingredients[id])
	# Raffinés : ce qui manque (inventaire et réserves des fourneaux déduits) se compte en ingrédients.
	var raffines := _raffines_manquants()
	for id: String in raffines:
		var recette := atelier.recette_raffine(id)
		for ingredient: String in recette:
			brut[ingredient] = int(brut.get(ingredient, 0)) + int(raffines[id]) * int(recette[ingredient])
	for id: String in composants:
		var manque := int(composants[id]) - inventaire.quantite(id)
		if manque <= 0:
			continue
		var recette := atelier.ingredients_composant(id)
		for ingredient: String in recette:
			brut[ingredient] = int(brut.get(ingredient, 0)) + manque * int(recette[ingredient])
	var resultat := {}
	for id: String in brut:
		var manque := int(brut[id]) - inventaire.quantite(id)
		if manque > 0:
			resultat[id] = manque
	return resultat


## Raffinés encore à fabriquer pour les prochains objectifs : { raffiné: nombre }, dans l'ordre des objectifs.
func _raffines_manquants() -> Dictionary:
	var atelier: Atelier = _game.atelier
	var voulus := {}
	for objectif: Array in _objectifs_proches():
		var ingredients := _ingredients_objectif(objectif)
		for id: String in ingredients:
			if atelier.raffines().has(id):
				voulus[id] = int(voulus.get(id, 0)) + int(ingredients[id])
	var resultat := {}
	for id: String in voulus:
		var manque: int = int(voulus[id]) - _game.inventaire.quantite(id) - _en_reserve_fourneaux(id)
		if manque > 0:
			resultat[id] = manque
	return resultat


func _en_reserve_fourneaux(raffine: String) -> int:
	var total := 0
	for lieu: String in _game.atelier.recettes_fourneau:
		var fourneau: SourceRessource = _ile.machine(lieu)
		if fourneau != null and fourneau.id_ressource == raffine:
			total += fourneau.stock
	return total


## Fourneaux : un clic récupère la réserve si ce raffiné sert, et règle la recette sur le premier raffiné
## qui manque (ou les arrête quand plus rien ne manque, pour ne pas gaspiller).
func _gerer_fourneaux() -> bool:
	var a_fait := false
	var manquants := _raffines_manquants()
	var voulu: String = "" if manquants.is_empty() else str(manquants.keys()[0])
	for lieu: String in _game.atelier.recettes_fourneau.keys():
		var fourneau: SourceRessource = _ile.machine(lieu)
		var actuel: String = _game.atelier.recette_fourneau(lieu)
		var a_vider: bool = fourneau.stock > 0 and (_besoin_raffine(actuel) or voulu != actuel)
		if not a_vider and voulu == actuel:
			continue
		_fin_attente()
		var avant: int = _game.inventaire.quantite(actuel) if actuel != "" else 0
		await _deplacer_souris(fourneau.position)
		await _cliquer(fourneau.position)
		if actuel != "":
			_fourneau_recolte[actuel] = int(_fourneau_recolte.get(actuel, 0)) + _game.inventaire.quantite(actuel) - avant
		await _attendre(_profil["reflexion"])
		if voulu != actuel:
			for bouton in _atelier_ui._liste.get_children():
				if bouton.get_meta("id") == voulu:
					await _cliquer(_centre(bouton))
			await _cliquer(_centre(_atelier_ui._bouton))
			_noter("Fourneau : %s" % ("arrêt" if voulu == "" else voulu))
		await _touche(KEY_ESCAPE)
		await _attendre(_profil["geste"])
		a_fait = true
	return a_fait


func _besoin_raffine(raffine: String) -> bool:
	if raffine == "":
		return false
	for objectif: Array in _objectifs_restants():
		if _ingredients_objectif(objectif).has(raffine):
			return true
	return false


func _objectifs_proches() -> Array:
	return _objectifs_restants().slice(0, HORIZON_OBJECTIFS)


func _objectifs_restants() -> Array:
	var atelier: Atelier = _game.atelier
	var restants: Array = []
	for objectif: Array in OBJECTIFS:
		var fait := false
		match objectif[0]:
			"amelioration":
				fait = atelier.niveau(objectif[1]) >= int(objectif[2])
			"machine":
				fait = atelier.nombre_machines(objectif[1]) >= int(objectif[2])
			"amelioration_machine":
				fait = atelier.niveau_machine(objectif[1], objectif[2]) >= int(objectif[3])
			_:
				fait = atelier.est_construite(objectif[1])
		if not fait:
			restants.append(objectif)
	return restants


func _ingredients_objectif(objectif: Array) -> Dictionary:
	var atelier: Atelier = _game.atelier
	if objectif[0] == "amelioration":
		return atelier.recette_niveau(objectif[1], int(objectif[2]))["ingredients"]
	if objectif[0] == "machine":
		return atelier.machine(objectif[1])["ingredients"]
	if objectif[0] == "amelioration_machine":
		return atelier.machine(objectif[1])["ameliorations"][objectif[2]][int(objectif[3]) - 1]
	return atelier.ingredients_construction(objectif[1])


## Plonger si une ressource de l'abysse manque et qu'elle est atteignable avec le câble actuel.
func _plongee_utile(besoins: Dictionary) -> bool:
	for minerai: String in MINERAIS:
		if besoins.has(minerai) and _atteignable(minerai, _game.atelier.longueur_cable_m() * 10.0):
			return true
	return false


## Zone (data/zones.json) où l'on trouve ce minerai.
func _zone_de(minerai: String) -> Dictionary:
	for zone: Dictionary in _zones:
		if zone["minerai"] == minerai:
			return zone
	return {}


## Vrai si des gisements de ce minerai peuvent se trouver à portée de minage avec ce câble (px).
func _atteignable(minerai: String, limite_px: float) -> bool:
	# Prudence : pas de Faille sans le réservoir de 200 (avec 150, le retour du fond est trop juste).
	if minerai == "pierre_braise" and _game.atelier.oxygene_max() < 200.0:
		return false
	var zone := _zone_de(minerai)
	return limite_px + 24.0 > float(zone.get("gisements_des_m", zone["debut_m"])) * 10.0


# --- Île : récolte -------------------------------------------------------------------

## Récolte ce qui sert aux objectifs et qui est disponible ; vrai si quelque chose a été fait.
func _recolter_utile(besoins: Dictionary) -> bool:
	var a_fait := false
	# Machines d'abord : un clic vide toute leur réserve.
	for lieu: String in _game.atelier.machines:
		var machine: SourceRessource = _ile.machine(lieu)
		# Comme un joueur : on vide une machine dont la ressource manque, ou qui est pleine (elle s'arrête).
		if machine != null and machine.forme != SourceRessource.Forme.FOURNEAU and machine.stock > 0 \
				and (_besoins().has(machine.id_ressource) or machine.stock >= machine.plafond) \
				and _game.inventaire.place(machine.id_ressource) > 0:
			var avant: int = _game.inventaire.quantite(machine.id_ressource)
			await _cliquer(machine.position)
			_machines_recolte[machine.id_ressource] = int(_machines_recolte.get(machine.id_ressource, 0)) \
				+ _game.inventaire.quantite(machine.id_ressource) - avant
			a_fait = true
	var eolienne: SourceRessource = _ile._eolienne
	if besoins.has("vent") and eolienne.stock > 0:
		var vent_avant: int = _game.inventaire.quantite("vent")
		await _cliquer(eolienne.position)
		_compter(_ile_recolte, "vent", _game.inventaire.quantite("vent") - vent_avant)
		a_fait = true
	if _besoins().has("cristal_solaire"):
		for filon: SourceRessource in _ile._filons:
			# Un filon couvert par une foreuse n'est plus sur l'île : on vide la foreuse à la place.
			if filon.get_parent() != null and filon.stock > 0 and _besoins().has("cristal_solaire"):
				var solaire_avant: int = _game.inventaire.quantite("cristal_solaire")
				await _maintenir_sur(filon, "cristal_solaire")
				_compter(_ile_recolte, "cristal_solaire", _game.inventaire.quantite("cristal_solaire") - solaire_avant)
				a_fait = true
	# Îlot relié : le bassin de lumière donne du cristal de lagon sans plonger.
	var bassin: SourceRessource = _ile.bassin()
	if _ile.ilot_relie() and bassin.stock > 0 and _besoins().has("cristal_lagon"):
		var avant: int = _game.inventaire.quantite("cristal_lagon")
		await _maintenir_sur(bassin, "cristal_lagon")
		_bassin_recolte += _game.inventaire.quantite("cristal_lagon") - avant
		_compter(_ile_recolte, "cristal_lagon", _game.inventaire.quantite("cristal_lagon") - avant)
		a_fait = true
	var essais := 0
	while _besoins().has("nuage") and essais < 30:
		var nuage := _nuage_visible()
		if nuage == null:
			break
		var nuage_avant: int = _game.inventaire.quantite("nuage")
		await _cliquer_nuage(nuage)
		_compter(_ile_recolte, "nuage", _game.inventaire.quantite("nuage") - nuage_avant)
		essais += 1
		a_fait = true
	return a_fait


func _compter(compteur: Dictionary, id: String, nombre: int) -> void:
	if nombre > 0:
		compteur[id] = int(compteur.get(id, 0)) + nombre


func _nuage_visible() -> SourceRessource:
	var meilleur: SourceRessource = null
	for enfant in _ile.get_node("Nuages").get_children():
		var nuage := enfant as SourceRessource
		if nuage == null or nuage.is_queued_for_deletion() or nuage.stock <= 0:
			continue
		if nuage.position.x < 40.0 or nuage.position.x > 600.0:
			continue
		# Caché sous le bouton « Inventaire » : un clic ouvrirait l'inventaire (un joueur attend qu'il passe).
		if (_ile.get_node("HUD").bouton_inventaire as Control).get_global_rect().grow(4.0).has_point(nuage.position):
			continue
		if meilleur == null or nuage.position.x > meilleur.position.x:
			meilleur = nuage
	return meilleur


## Clique un nuage jusqu'à l'épuiser (ou jusqu'à ne plus en avoir besoin), en suivant sa dérive.
func _cliquer_nuage(nuage: SourceRessource) -> void:
	await _deplacer_souris(nuage.position)
	while is_instance_valid(nuage) and not nuage.is_queued_for_deletion() and nuage.stock > 0 \
			and _besoins().has("nuage") and nuage.position.x < 600.0:
		await _cliquer(nuage.position, false)


func _maintenir_sur(source: SourceRessource, id: String) -> void:
	await _deplacer_souris(source.position)
	_bouton_souris(source.position, true)
	var limite := 0
	while source.stock > 0 and _besoins().has(id) and limite < int(IPS * 10.0):
		await _image()
		limite += 1
	_bouton_souris(source.position, false)
	await _attendre(_profil["clic"])


func _recolter_bassin() -> void:
	var bassin: SourceRessource = _ile.bassin()
	var avant: int = _game.inventaire.quantite("cristal_lagon")
	await _deplacer_souris(bassin.position)
	_bouton_souris(bassin.position, true)
	await _attendre(1.2)
	_bouton_souris(bassin.position, false)
	await _attendre(_profil["clic"])
	_bassin_recolte += _game.inventaire.quantite("cristal_lagon") - avant
	_noter("Bassin de lumière récolté : %d cristaux de lagon au total" % _bassin_recolte)


# --- Île : atelier ---------------------------------------------------------------------

## Ouvre l'atelier (touche C) et fabrique / installe / construit tout ce qui sert à l'objectif en cours.
func _fabriquer_tout() -> void:
	var plan := _prochaine_fabrication()
	if plan.is_empty():
		return
	_fin_attente()
	if plan[0] == "machines" and plan.size() == 2 and not _game.atelier.emplacements_libres().is_empty():
		# Comme un joueur : clic sur un emplacement libre, l'atelier s'ouvre sur l'onglet Machines
		# (la foreuse ira quand même sur un filon).
		var libre: String = _game.atelier.emplacements_libres()[0]
		await _deplacer_souris(_ile.centre_emplacement(libre))
		await _cliquer(_ile.centre_emplacement(libre))
	else:
		await _touche(KEY_C)
	await _attendre(_profil["reflexion"])
	while not plan.is_empty() and _atelier_ui.est_ouvert():
		var onglet: String = plan[0]
		var id: String = plan[1]
		if _atelier_ui.onglet != onglet:
			await _cliquer(_centre(_atelier_ui._onglets[onglet]))
		for bouton in _atelier_ui._liste.get_children():
			if bouton.get_meta("id") == id and _atelier_ui.selection != id:
				await _cliquer(_centre(bouton))
		var mode: String = plan[2] if plan.size() > 2 else "construire"
		if onglet == "machines" and _atelier_ui.mode != mode:
			await _cliquer(_centre(_atelier_ui._boutons_modes[mode]))
		await _attendre(_profil["reflexion"])
		var avant := str(_game.inventaire.vers_dictionnaire())
		await _cliquer(_centre(_atelier_ui._bouton))
		if str(_game.inventaire.vers_dictionnaire()) == avant:
			_noter("Atelier : %s n'a pas pu se faire" % id)   # garde-fou : jamais de boucle sans fin
			break
		_fabrications[id] = int(_fabrications.get(id, 0)) + 1
		if onglet == "machines" and mode == "construire":
			_machines_construites.append([_secondes(), id, _atelier_ui.dernier_emplacement])
		_noter("Atelier : %s" % id)
		plan = _prochaine_fabrication()
	if _atelier_ui.est_ouvert():
		await _touche(KEY_ESCAPE)
	await _attendre(_profil["geste"])


## [onglet, id] de la prochaine fabrication utile, ou [] s'il n'y a rien à faire.
## L'objectif en cours passe d'abord ; les suivants seulement s'ils ne prennent rien à celui-ci.
func _prochaine_fabrication() -> Array:
	var atelier: Atelier = _game.atelier
	var restants := _objectifs_restants()
	for i in restants.size():
		var objectif: Array = restants[i]
		if objectif[0] == "amelioration" and atelier.niveau(objectif[1]) == int(objectif[2]) - 1 \
				and atelier.peut_ameliorer(objectif[1]):
			return ["ameliorations", objectif[1]]
		if objectif[0] == "construction" and atelier.peut_construire(objectif[1]):
			return ["construction", objectif[1]]
		if objectif[0] == "machine" and atelier.peut_construire_machine(objectif[1]):
			return ["machines", objectif[1]]
		if objectif[0] == "amelioration_machine" and atelier.peut_ameliorer_machine(objectif[1], objectif[2]) \
				and atelier.niveau_machine(objectif[1], objectif[2]) == int(objectif[3]) - 1:
			return ["machines", objectif[1], objectif[2]]
		var ingredients := _ingredients_objectif(objectif)
		for id: String in ingredients:
			if atelier.composants().has(id) and _game.inventaire.quantite(id) < int(ingredients[id]) \
					and atelier.peut_fabriquer(id) and (i == 0 or not _prend_a_l_objectif(id, restants[0])):
				return ["composants", id]
	return []


## Vrai si fabriquer ce composant consomme une ressource encore nécessaire à l'objectif en cours.
func _prend_a_l_objectif(composant: String, objectif: Array) -> bool:
	var atelier: Atelier = _game.atelier
	var ingredients := _ingredients_objectif(objectif)
	for id: String in atelier.ingredients_composant(composant):
		if ingredients.has(id):
			return true
		for sous: String in ingredients:
			if atelier.composants().has(sous) and atelier.ingredients_composant(sous).has(id):
				return true
	return false


# --- Plongée ---------------------------------------------------------------------------

func _plonger(besoins: Dictionary) -> void:
	var cloche_ile: Vector2 = _ile_script.POSITION_CLOCHE
	var debut := _secondes()
	await _cliquer(cloche_ile)
	_noter("Plongée %d : départ (besoins %s)" % [_plongees.size() + 1, str(besoins)])
	while _jeu.etat != 2:
		await _image()
	var plongee: Node = _jeu.plongee()
	var mesure := {
		"numero": _plongees.size() + 1, "debut_s": debut, "profondeur_max_m": 0.0, "oxygene_fin": -1.0,
		"oxygene_max": plongee.oxygene_max, "urgence": false, "gardees": {}, "perdues": {},
		"cable_m": _game.atelier.longueur_cable_m(), "duree_sous_eau_s": 0.0, "exploration_s": 0.0,
		"gisements_vus": 0,
	}
	plongee.retour_ile.connect(func(gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
		mesure["oxygene_fin"] = plongee.oxygene
		mesure["gardees"] = gardees
		mesure["perdues"] = perdues
		mesure["urgence"] = urgence)
	var debut_eau := _secondes()
	_marque_video("sous_l_eau")
	await _conduire(plongee, besoins, mesure)
	_marque_video("surface")
	mesure["duree_sous_eau_s"] = _secondes() - debut_eau
	_relacher_tout()
	while _jeu.etat != 0:
		await _image()
	mesure["duree_totale_s"] = _secondes() - debut
	_plongees.append(mesure)
	for id: String in mesure["gardees"]:
		_compter(_plongee_recolte, id, int(mesure["gardees"][id]))
	if not _paliers.has(_game.atelier.palier):
		_paliers[_game.atelier.palier] = _secondes()
		_noter("Palier %d ouvert" % _game.atelier.palier)
	_noter("Plongée %d : retour, %s gardé(s), oxygène %.0f/%.0f%s" % [mesure["numero"], str(mesure["gardees"]),
		mesure["oxygene_fin"], mesure["oxygene_max"], " (REMONTÉE AUTOMATIQUE)" if mesure["urgence"] else ""])
	await _attendre(_profil["lecture_butin"])   # le joueur lit l'annonce du butin


## Conduite de la cloche jusqu'au retour en surface. Les décisions (touches, cible, remontée) sont
## prises toutes les 0,3 à 0,6 s pour le joueur humain, à chaque image pour le robot parfait ;
## entre deux décisions, les touches restent dans leur état.
func _conduire(plongee: Node, besoins: Dictionary, mesure: Dictionary) -> void:
	var cloche: CharacterBody2D = plongee.get_node("Bell")
	var cible: Node2D = null
	var meilleure_distance := INF
	var temps_sans_progres := 0.0
	var abandonnees: Array = []
	var vus: Array = []                     # gisements aperçus pendant cette plongée
	var remonter := false
	var prochaine_decision := 0.0
	var derniere_decision := 0.0
	var en_exploration := false
	var exploration := {"rang": -1, "sens": 1.0}
	while _jeu.etat == 2:
		mesure["profondeur_max_m"] = maxf(mesure["profondeur_max_m"], cloche.position.y / 10.0)
		# Fin de la descente accélérée au montage : arrivée dans la Faille, ou premier coup de minage.
		if _video and not mesure.has("video_fond") and (cloche.position.y >= 2900.0 or Input.is_physical_key_pressed(KEY_E)):
			mesure["video_fond"] = true
			_marque_video("fond")
		if _video and remonter and not mesure.has("video_remontee"):
			mesure["video_remontee"] = true
			_marque_video("remontee")
		if en_exploration:
			mesure["exploration_s"] += 1.0 / IPS
		_regarder(plongee, cloche, vus)
		mesure["gisements_vus"] = vus.size()
		if _secondes() < prochaine_decision:
			await _image()
			continue
		var reaction: Array = _profil["reaction"]
		var ecoule := _secondes() - derniere_decision
		derniere_decision = _secondes()
		prochaine_decision = _secondes() + _hasard.randf_range(reaction[0], reaction[1])
		en_exploration = false
		var sac: Dictionary = plongee._sac.compter()
		var voulus := _voulus(besoins, sac)
		if not remonter:
			remonter = plongee._sac.est_plein() or voulus.is_empty() \
				or plongee.oxygene < _oxygene_pour_remonter(cloche.position.y) + _temps_vers(cloche, cible) * _conso_a(cloche.position.y)
		if remonter:
			_touche_maintenue(KEY_E, false)
			# La plongée ne compte qu'après être descendu sous 10 m : sinon, on y descend d'abord.
			var but_y := -40.0 if plongee._armee else 140.0
			_diriger(cloche, Vector2(cloche.position.x, but_y))
			await _image()
			continue
		if cible == null or not is_instance_valid(cible) or cible.is_queued_for_deletion() \
				or not voulus.has(cible.minerai):
			_touche_maintenue(KEY_E, false)
			cible = _choisir_gisement(plongee, cloche, voulus, abandonnees, vus)
			meilleure_distance = INF
			temps_sans_progres = 0.0
			if cible == null:
				# Rien de connu : le joueur humain explore ; le robot parfait n'a plus rien à chercher.
				var point := _point_exploration(plongee, cloche, voulus, exploration)
				if point == Vector2.INF:
					remonter = true
				else:
					en_exploration = true
					_diriger(cloche, point)
				await _image()
				continue
		var distance := cloche.position.distance_to(cible.position)
		if distance < meilleure_distance - 1.0:
			meilleure_distance = distance
			temps_sans_progres = 0.0
		else:
			temps_sans_progres += ecoule
		if distance < 60.0:
			mesure["proche_s"] = float(mesure.get("proche_s", 0.0)) + ecoule
		if distance <= float(_profil["distance_minage"]) or (Input.is_physical_key_pressed(KEY_E) and distance <= 26.0):
			_diriger(cloche, cloche.position)   # lâcher les flèches, la cloche se stabilise en minant
			_touche_maintenue(KEY_E, true)
			temps_sans_progres = 0.0
		else:
			_touche_maintenue(KEY_E, false)
			_diriger(cloche, cible.position)
			if temps_sans_progres > float(_profil["blocage"]):
				abandonnees.append(cible)
				cible = null
		await _image()
	_touche_maintenue(KEY_E, false)


## Gisements visibles à l'écran et éclairés : hors de l'obscurité, ou dans le halo de la lanterne.
func _regarder(plongee: Node, cloche: Node2D, vus: Array) -> void:
	var haut: float = plongee._camera.y
	var rayon: float = (_game.atelier.rayon_halo() + ArtAbysse.ANNEAU_HALO) * 2.0   # monde ×2 → 640x360
	for enfant in plongee.get_node("Gisements").get_children():
		if enfant.is_queued_for_deletion() or vus.has(enfant):
			continue
		var y: float = enfant.position.y
		if y < haut or y > haut + 360.0:
			continue
		var sombre := ArtAbysse.niveau_obscurite(y / 10.0, _game.atelier.obscurite_max()) > 0
		if sombre and cloche.position.distance_to(enfant.position) > rayon:
			continue
		vus.append(enfant)


## Prochain point de l'exploration en zigzag (rangées horizontales de plus en plus profondes) dans la
## bande où l'on trouve le minerai voulu ; Vector2.INF quand toute la bande a été parcourue.
func _point_exploration(plongee: Node, cloche: Node2D, voulus: Dictionary, etat: Dictionary) -> Vector2:
	if _profil["connait_gisements"]:
		return Vector2.INF
	var minerai := ""
	for candidat: String in MINERAIS:
		if voulus.has(candidat) and _atteignable(candidat, plongee.limite_px):
			minerai = candidat
			break
	if minerai == "":
		return Vector2.INF
	var zone := _zone_de(minerai)
	var haut := float(zone.get("gisements_des_m", zone["debut_m"])) * 10.0
	var bas := minf(float(zone["fin_m"]) * 10.0, plongee.limite_px)
	var sombre := ArtAbysse.niveau_obscurite(haut / 10.0, _game.atelier.obscurite_max()) > 0
	var ecart: float = (_game.atelier.rayon_halo() * 2.0 + 20.0) * 1.6 if sombre else 260.0
	if etat["rang"] < 0:
		etat["rang"] = 0
		etat["sens"] = -1.0 if cloche.position.x > 0.0 else 1.0
	var y: float = haut + 40.0 + ecart * float(etat["rang"])
	if y > bas + 20.0:
		return Vector2.INF
	var but := Vector2(240.0 * float(etat["sens"]), minf(y, bas))
	if cloche.position.distance_to(but) < 40.0:
		etat["rang"] = int(etat["rang"]) + 1
		etat["sens"] = -float(etat["sens"])
	return but


## Minerais encore voulus pendant cette plongée : { id: nombre }.
func _voulus(besoins: Dictionary, sac: Dictionary) -> Dictionary:
	var voulus := {}
	for id: String in MINERAIS:
		var manque := int(besoins.get(id, 0)) - int(sac.get(id, 0))
		# Même prudence qu'au départ : pas de pierre de braise sans le réservoir de 200.
		if manque > 0 and (id != "pierre_braise" or _game.atelier.oxygene_max() >= 200.0):
			voulus[id] = manque
	return voulus


## Gisement voulu le plus proche, atteignable avec le câble ; le minerai le plus profond passe d'abord.
## Le joueur humain ne choisit que parmi les gisements qu'il a aperçus.
func _choisir_gisement(plongee: Node, cloche: Node2D, voulus: Dictionary, abandonnees: Array, vus: Array) -> Node2D:
	var limite: float = plongee.limite_px + 24.0
	var connus: Array = plongee.get_node("Gisements").get_children() if _profil["connait_gisements"] else vus
	for minerai: String in MINERAIS:
		if not voulus.has(minerai):
			continue
		var meilleur: Node2D = null
		for enfant in connus:
			if not is_instance_valid(enfant) or enfant.is_queued_for_deletion() or enfant.minerai != minerai \
					or abandonnees.has(enfant):
				continue
			if enfant.position.y > limite:
				continue
			if meilleur == null or cloche.position.distance_to(enfant.position) < cloche.position.distance_to(meilleur.position):
				meilleur = enfant
		if meilleur != null:
			return meilleur
	return null


## Oxygène qu'un joueur prudent garde pour remonter d'ici (consommation de chaque zone + marge).
func _oxygene_pour_remonter(y: float) -> float:
	var besoin := 1.0 + float(_profil["marge_oxygene"])
	for zone: Dictionary in _zones:
		var dedans := clampf(y, float(zone["debut_m"]) * 10.0, float(zone["fin_m"]) * 10.0) - float(zone["debut_m"]) * 10.0
		besoin += dedans / VITESSE_CLOCHE * 1.2 * float(zone["conso_oxygene"])   # 1,2 : CONSOMMATION_PAR_S de dive.gd
	return besoin


## Consommation d'air par seconde à cette profondeur (px).
func _conso_a(y: float) -> float:
	for zone: Dictionary in _zones:
		if y < float(zone["fin_m"]) * 10.0:
			return 1.2 * float(zone["conso_oxygene"])
	return 1.2 * float(_zones[-1]["conso_oxygene"])


func _temps_vers(cloche: Node2D, cible: Variant) -> float:
	if cible == null or not is_instance_valid(cible) or (cible as Node2D).is_queued_for_deletion():
		return 0.0
	return cloche.position.distance_to((cible as Node2D).position) / VITESSE_CLOCHE + 1.0


## Appuie sur les touches de direction pour aller vers « but », en relâchant à la distance de freinage.
func _diriger(cloche: CharacterBody2D, but: Vector2) -> void:
	if float(_profil["erreur_freinage"]) > 0.0 and but != cloche.position:
		but += Vector2(_hasard.randf_range(-ECART_VISEE, ECART_VISEE), _hasard.randf_range(-ECART_VISEE, ECART_VISEE))
	var ecart := but - cloche.position
	var vitesse := cloche.velocity
	_touche_maintenue(KEY_D, _pousser(ecart.x, vitesse.x))
	_touche_maintenue(KEY_A, _pousser(-ecart.x, -vitesse.x))
	_touche_maintenue(KEY_S, _pousser(ecart.y, vitesse.y))
	_touche_maintenue(KEY_W, _pousser(-ecart.y, -vitesse.y))


## Vrai s'il faut pousser dans ce sens : encore loin, et pas déjà assez vite pour arriver en glissant.
func _pousser(distance: float, vitesse: float) -> bool:
	if distance <= 4.0:
		return false
	if _profil["approche_douce"] and distance < APPROCHE and vitesse > VITESSE_APPROCHE:
		return false
	var freinage := maxf(vitesse, 0.0) * maxf(vitesse, 0.0) / (2.0 * FREINAGE)
	var erreur := float(_profil["erreur_freinage"])
	freinage *= 1.0 + _hasard.randf_range(-erreur, erreur)
	return distance > freinage + 4.0


# --- Séquence vidéo (environ 40 s) -----------------------------------------------------

## Partie préparée pour la vidéo : câble de 450 m, réservoir de niveau 1 seulement (150 : l'air devient
## juste en remontant de la Faille, on entend les bips), lanterne de niveau 1, îlot relié, deux lentilles et
## deux pierres de braise déjà en poche (il en faut quatre pour la lanterne de niveau 2).
func _preparer_sauvegarde_video() -> void:
	Sauvegarde.ecrire({
		"inventaire": {"vent": 150, "nuage": 20, "cristal_solaire": 30, "cristal_lagon": 4, "corail": 3,
			"pierre_braise": 3, "lingot_solaire": 4, "nacre": 3, "verre_lagon": 3},
		"ameliorations": {"cable": 2, "lanterne": 2, "reservoir": 2, "sac": 1},
		"ilots": ["ilot_est", "ilot_nord"],
		"machines": {"ile_ouest": "moulin", "ile_centre": "filet", "filon_2": "foreuse", "nord_est": "entrepot",
			"nord_ouest": "fourneau", "ilot_est": "sonde"},
		"palier": 3,
		"fourneaux": {"nord_ouest": ""},
		"ile": {"machines": {"ile_ouest": {"stock": 5, "recharge": 0.0}, "ile_centre": {"stock": 6, "recharge": 0.0},
			"filon_2": {"stock": 4, "recharge": 0.0}}},
	})


## Séquence vidéo (avec le son) : le palier 3. Un clic sur le fourneau ouvre son panneau : lingot solaire en
## boucle ; il rougeoie et fume en prenant cristaux et vent dans l'inventaire ; atelier : l'arche de braise
## (100 vents, grâce à l'entrepôt) relie l'îlot du couchant, puis le sac de plongée à 16 places ; plongée dans
## le Lagon de lumière ; au retour, la sonde a pêché du cristal de lagon et le fourneau a produit des lingots.
## Les trajets verticaux sont repérés (lignes « VIDEO ») pour être accélérés au montage (tests/playtest.sh).
func _sequence_video() -> void:
	await _attendre(2.5)
	var fourneau: SourceRessource = _ile.machine("nord_ouest")
	await _deplacer_souris(fourneau.position)
	await _cliquer(fourneau.position)
	await _attendre(1.0)
	for bouton in _atelier_ui._liste.get_children():
		if bouton.get_meta("id") == "lingot_solaire":
			await _cliquer(_centre(bouton))
	await _attendre(1.5)
	await _cliquer(_centre(_atelier_ui._bouton))
	await _attendre(1.0)
	await _touche(KEY_ESCAPE)
	await _attendre(4.0)
	await _touche(KEY_C)
	await _attendre(0.8)
	await _cliquer(_centre(_atelier_ui._onglets["construction"]))
	for bouton in _atelier_ui._liste.get_children():
		if bouton.get_meta("id") == "arche":
			await _cliquer(_centre(bouton))
	await _attendre(1.8)
	await _cliquer(_centre(_atelier_ui._bouton))
	await _attendre(1.0)
	await _cliquer(_centre(_atelier_ui._onglets["ameliorations"]))
	for bouton in _atelier_ui._liste.get_children():
		if bouton.get_meta("id") == "sac":
			await _cliquer(_centre(bouton))
	await _attendre(1.5)
	await _cliquer(_centre(_atelier_ui._bouton))
	await _attendre(1.0)
	await _touche(KEY_C)
	await _attendre(2.5)
	await _plonger({"cristal_lagon": 16})
	await _attendre(1.5)
	await _cliquer(_ile.machine("ilot_est").position)
	await _attendre(1.0)
	await _cliquer(fourneau.position)
	await _attendre(1.5)
	await _touche(KEY_ESCAPE)
	await _attendre(2.5)


## Repère de montage pour la vidéo (temps de jeu = temps du film).
func _marque_video(nom: String) -> void:
	if _video:
		print("VIDEO %s %.3f" % [nom, _secondes()])


# --- Mesures ---------------------------------------------------------------------------

func _debut_attente_si_besoin(besoins: Dictionary) -> void:
	if _debut_attente < 0.0:
		_debut_attente = _secondes()
		_raison_attente = "en attente de : %s" % ", ".join(PackedStringArray(besoins.keys()))


func _fin_attente() -> void:
	if _debut_attente < 0.0:
		return
	var duree := _secondes() - _debut_attente
	if duree > ATTENTE_SIGNALEE_S:
		_attentes.append([_debut_attente, duree, _raison_attente])
	_debut_attente = -1.0


func _compter_manques(besoins: Dictionary, duree: float) -> void:
	for id: String in besoins:
		_manques[id] = float(_manques.get(id, 0.0)) + duree


func _noter(texte: String) -> void:
	_evenements.append([_secondes(), texte])
	print("[%7.1f s] %s" % [_secondes(), texte])


func _ecrire_mesures() -> void:
	var mesures := {
		"profil": _nom_profil,
		"duree_totale_s": _secondes(),
		"temps_s": {
			"titre": _temps["titre"] / IPS, "ile": _temps["ile"] / IPS,
			"transition": _temps["transition"] / IPS, "plongee": _temps["plongee"] / IPS,
		},
		"plongees": _plongees,
		"attentes": _attentes,
		"manques_s": _manques,
		"inventaire_final": _game.inventaire.vers_dictionnaire(),
		"fabrications": _fabrications,
		"ameliorations": _game.atelier.niveaux,
		"ilots": _game.atelier.ilots_relies,
		"bassin_recolte": _bassin_recolte,
		"machines_construites": _machines_construites,
		"machines_recolte": _machines_recolte,
		"paliers_s": _paliers,
		"origine": {"machines": _machines_recolte, "ile": _ile_recolte, "plongees": _plongee_recolte,
			"fourneau": _fourneau_recolte},
		"depenses_atelier": _game.atelier.depenses,
		"consomme_fourneau": _game.atelier.consomme_fourneau,
		"inventaire_max": _inventaire_max,
		"niveaux_machines": _game.atelier.niveaux_machines,
		"evenements": _evenements,
		"termine": _objectifs_restants().is_empty(),
	}
	print("MESURES " + JSON.stringify(mesures))
	if _sortie != "":
		var fichier := FileAccess.open(_sortie, FileAccess.WRITE)
		fichier.store_string(JSON.stringify(mesures, "\t"))
		fichier.close()


# --- Temps et entrées ------------------------------------------------------------------

func _secondes() -> float:
	return _images / IPS


func _image() -> void:
	await physics_frame
	_images += 1
	var cle := "ile"
	if _jeu.get_node("EcranTitre").est_ouvert():
		cle = "titre"
	elif _jeu.etat == 1 or _jeu.etat == 3:
		cle = "transition"
	elif _jeu.etat == 2:
		cle = "plongee"
	_temps[cle] += 1
	if _images % 30 == 0:
		var quantites: Dictionary = _game.inventaire.vers_dictionnaire()
		for id: String in quantites:
			_inventaire_max[id] = maxi(int(_inventaire_max.get(id, 0)), int(quantites[id]))


func _attendre(duree: float) -> void:
	for i in maxi(roundi(duree * IPS), 1):
		await _image()


func _vers_fenetre(point: Vector2) -> Vector2:
	return root.get_final_transform() * point


func _centre(controle: Control) -> Vector2:
	return controle.get_global_rect().get_center()


func _deplacer_souris(point: Vector2) -> void:
	var mouvement := InputEventMouseMotion.new()
	mouvement.position = _vers_fenetre(point)
	mouvement.global_position = mouvement.position
	Input.parse_input_event(mouvement)
	await _attendre(_profil["geste"])


func _bouton_souris(point: Vector2, appuye: bool) -> void:
	var bouton := InputEventMouseButton.new()
	bouton.button_index = MOUSE_BUTTON_LEFT
	bouton.pressed = appuye
	bouton.position = _vers_fenetre(point)
	bouton.global_position = bouton.position
	Input.parse_input_event(bouton)


func _cliquer(point: Vector2, avec_geste: bool = true) -> void:
	if avec_geste:
		await _deplacer_souris(point)
	else:
		var mouvement := InputEventMouseMotion.new()
		mouvement.position = _vers_fenetre(point)
		mouvement.global_position = mouvement.position
		Input.parse_input_event(mouvement)
		await _image()
	_bouton_souris(point, true)
	await _attendre(_profil["clic"] / 2.0)
	_bouton_souris(point, false)
	await _attendre(_profil["clic"] / 2.0)


## Appui bref sur une touche physique.
func _touche(code: Key) -> void:
	_touche_maintenue(code, true)
	await _attendre(0.08)
	_touche_maintenue(code, false)
	await _attendre(0.05)


## Maintient ou relâche une touche physique (un évènement seulement quand l'état change).
func _touche_maintenue(code: Key, appuye: bool) -> void:
	if bool(_touches_appuyees.get(code, false)) == appuye:
		return
	_touches_appuyees[code] = appuye
	var evenement := InputEventKey.new()
	evenement.physical_keycode = code
	evenement.pressed = appuye
	Input.parse_input_event(evenement)


func _relacher_tout() -> void:
	for code: Key in _touches_appuyees.keys():
		_touche_maintenue(code, false)


func _effacer_sauvegarde() -> void:
	var base := SAUVEGARDE.get_basename()
	for chemin: String in [SAUVEGARDE, base + ".bak", base + ".tmp", base + ".corrompue.json"]:
		if FileAccess.file_exists(chemin):
			DirAccess.remove_absolute(chemin)


## Coupe le son quelques images avant de quitter (le serveur audio relâche alors ses lectures).
func _couper_son_et_quitter(code: int) -> void:
	root.get_node("Son").arreter()
	for i in 10:
		await process_frame
		OS.delay_msec(20)   # le mixage audio tourne en temps réel, à côté des images
	quit(code)
