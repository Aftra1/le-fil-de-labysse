class_name Ile
extends Node2D
## L'île flottante : récolte à la souris (vent, nuages, cristaux solaires), inventaire,
## atelier (cabane : clic ou C) et départ en plongée en cliquant sur la cloche (ou E / Espace).
## Deux îlots isolés (data/ile.json) : à droite, l'îlot de l'est, relié par la passerelle de nuage (son
## bassin de lumière donne alors du cristal de lagon, maintien du clic comme les filons) ; en haut à
## gauche, l'îlot du nord, relié par le pont suspendu (deux emplacements de machine). Un clic sur un
## îlot isolé ouvre l'atelier, onglet Construction.
## Machines (data/machines.json) : un clic sur un emplacement libre ouvre l'atelier, onglet Machines ;
## une machine construite produit seule jusqu'à sa réserve et un clic vide la réserve (comme l'éolienne).
## La foreuse solaire se pose sur un filon, qui ne se récolte plus à la main ; l'entrepôt ne produit
## rien (il relève le plafond de l'inventaire). Le premier corail rapporté ouvre le palier 2, la première
## pierre de braise le palier 3 : le fourneau (un clic récupère sa réserve et ouvre le choix du raffiné qu'il
## fabrique en boucle avec les ingrédients de l'inventaire) et la sonde (qui ne produit qu'en plongée).
## Les sources se rechargent avec le temps, y compris pendant la plongée (voir rattraper()).
## Le marchand de vent (Marchand, data/marchand.json) passe de temps en temps : son dirigeable arrive par la
## droite, reste 60 s au-dessus de l'île et repart ; un clic dessus ouvre ses échanges (PanneauMarchand).
## Échap ferme un panneau ouvert ; sinon il remonte à la scène principale (menu pause).
## Rendu : le monde est dessiné en 320x180 (VueMonde, affiché ×2) ; la logique reste en 640x360.

signal plongee_demandee
## Une fabrication ou une installation à l'atelier : la scène principale sauvegarde.
signal partie_modifiee

const POSITION_CLOCHE := Vector2(320.0, 318.0)
const ATTACHE_CABLE := Vector2(320.0, 288.0)
const ZONE_CLOCHE := Vector2(16.0, 18.0)      # demi-taille de la zone cliquable
const POSITION_CABANE := Vector2(470.0, 183.0)
const ZONE_CABANE := Vector2(18.0, 16.0)
const DUREE_EFFET := 0.8
const MONTEE_EFFET := 18.0

const K := 0.5   # échelle du monde (320x180) par rapport aux positions du jeu (640x360)
const SONS_RECOLTE := {
	SourceRessource.Forme.NUAGE: "nuage", SourceRessource.Forme.EOLIENNE: "vent",
	SourceRessource.Forme.FILON: "cristal", SourceRessource.Forme.BASSIN: "bassin",
	SourceRessource.Forme.MOULIN: "machine", SourceRessource.Forme.FILET: "machine",
	SourceRessource.Forme.FOREUSE: "foreuse", SourceRessource.Forme.FOURNEAU: "fourneau",
	SourceRessource.Forme.SONDE: "sonde",
}
const FORMES_MACHINES := {
	"moulin": SourceRessource.Forme.MOULIN, "filet": SourceRessource.Forme.FILET,
	"foreuse": SourceRessource.Forme.FOREUSE, "entrepot": SourceRessource.Forme.ENTREPOT,
	"fourneau": SourceRessource.Forme.FOURNEAU, "sonde": SourceRessource.Forme.SONDE,
}
const ZONE_EMPLACEMENT := Vector2(12.0, 16.0)   # demi-taille, centrée 16 px au-dessus du sol
const RAYON_MACHINE := 16.0
## Dirigeable du marchand : position d'arrêt (640x360), demi-taille de la zone cliquable, durée du vol
## d'arrivée et de départ (il glisse depuis le bord droit de l'écran et y repart).
const POSITION_MARCHAND := Vector2(548.0, 116.0)
const ZONE_MARCHAND := Vector2(26.0, 18.0)
const DUREE_VOL := 4.0
const DEPART_MARCHAND_X := 700.0

var cloche_visible := true

var _reglages: Dictionary = {}
var _eolienne: SourceRessource
var _filons: Array[SourceRessource] = []
var _bassin: SourceRessource            # dans _sources seulement une fois l'îlot relié
var _survol_ilot := ""                   # îlot isolé sous la souris
var _survol_emplacement := ""            # emplacement libre sous la souris
var _machines: Dictionary = {}           # emplacement -> SourceRessource
var _souris := Vector2(-100.0, -100.0)
var _survol_cloche := false
var _survol_cabane := false
var _survol_marchand := false
var _survol: SourceRessource = null      # source sous la souris
var _maintien: SourceRessource = null
var _progres_maintien := 0.0
var _attente_nuage := 0.0
var _hasard := RandomNumberGenerator.new()

var _monde := VueMonde.new()

@onready var _nuages: Node2D = $Nuages
@onready var _sources: Node2D = $Sources
@onready var _effets: Node2D = $Effets
@onready var _interface: InterfaceIle = $HUD
@onready var _panneau: PanneauInventaire = $Inventaire
@onready var _atelier: PanneauAtelier = $Atelier
var _carnet := PanneauCarnet.new()
var _marchand := PanneauMarchand.new()


func _ready() -> void:
	_monde.name = "Monde"
	_monde.dessiner = _dessiner_monde
	# La vue continue de se redessiner quand l'île est figée (départ en plongée : la cloche part).
	_monde.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_monde)
	move_child(_monde, 0)
	_hasard.randomize()
	_reglages = Donnees.charger_json("res://data/ile.json")
	_creer_sources()
	for i in int(_reglages["nuages"]["minimum"]) + 1:
		_creer_nuage(_hasard.randf_range(60.0, 580.0))
	_carnet.name = "Carnet"
	add_child(_carnet)
	_marchand.name = "Marchand"
	add_child(_marchand)
	_marchand.echange_fait.connect(_sur_echange)
	_interface.bouton_inventaire.pressed.connect(_basculer_inventaire)
	_interface.bouton_carnet.pressed.connect(basculer_carnet)
	_atelier.fabrique.connect(_sur_fabrication)
	_interface.rafraichir_inventaire()


## Le bassin (îlot non relié) et les filons sous une foreuse, hors de l'arbre, sont libérés avec l'île.
func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_PREDELETE:
		return
	for source: SourceRessource in _filons + [_bassin]:
		if is_instance_valid(source) and source.get_parent() == null:
			source.free()


## Un seul panneau ouvert à la fois (inventaire, atelier, carnet ou marchand).
func panneau_ouvert() -> bool:
	return _panneau.est_ouvert() or _atelier.est_ouvert() or _carnet.est_ouvert() or _marchand.est_ouvert()


func _fermer_panneaux() -> void:
	_panneau.fermer()
	_atelier.fermer()
	_carnet.fermer()
	_marchand.fermer()


func _basculer_inventaire() -> void:
	_atelier.fermer()
	_carnet.fermer()
	_marchand.fermer()
	_panneau.basculer()


func _basculer_atelier() -> void:
	_panneau.fermer()
	_carnet.fermer()
	_marchand.fermer()
	_atelier.basculer()


## Carnet de collection (K ou le bouton « Carnet »).
func basculer_carnet() -> void:
	_panneau.fermer()
	_atelier.fermer()
	_marchand.fermer()
	_carnet.basculer()


## Échanges du marchand (clic sur son dirigeable, tant qu'il est là).
func ouvrir_marchand() -> void:
	_fermer_panneaux()
	_marchand.ouvrir()


## genre : « composant », « amelioration » ou « construction » (voir PanneauAtelier.fabrique).
func _sur_fabrication(id: String, genre: String) -> void:
	var atelier := Game.atelier
	match genre:
		"amelioration":
			_interface.annoncer("Installé : %s (niveau %d)" % [atelier.nom_amelioration(id), atelier.niveau(id)])
			Son.jouer("installation")
		"construction":
			actualiser_ilot()
			_interface.annoncer(atelier.annonce_construction(id))
			Son.jouer("construction")
		"machine":
			actualiser_machines()
			var lieu := _atelier.dernier_emplacement
			_interface.annoncer("Construit : %s. %s" % [atelier.nom_machine(id), _conseil_machine(id, lieu)])
			Son.jouer("construction")
		"fourneau":
			var lieu := _atelier.fourneau_lieu
			_vider_fourneau(lieu)
			actualiser_machines()
			_interface.annoncer("Fourneau à l'arrêt." if id == "" else "Fourneau : %s en boucle." % Game.nom_ressource(id).to_lower())
			Son.jouer("fourneau")
		"machine_amelioration":
			actualiser_machines()
			_interface.annoncer("Amélioré : %s (%s)" % [atelier.nom_machine(id),
				"vitesse" if _atelier.mode == "vitesse" else "réserve"])
			Son.jouer("installation")
		_:
			_interface.annoncer("Fabriqué : %s" % Game.nom_ressource(id))
			Son.jouer("fabrication")
	_interface.rafraichir_inventaire()
	partie_modifiee.emit()


## Ce que l'annonce dit après la construction d'une machine.
func _conseil_machine(id: String, lieu: String) -> String:
	if machine(lieu) != null and machine(lieu).forme == SourceRessource.Forme.ENTREPOT:
		return "L'inventaire garde maintenant jusqu'à %d de chaque ressource." % Game.inventaire.plafond
	if id == "fourneau" and Game.atelier.nombre_machines("fourneau") == 1:
		return "Un clic dessus choisit son raffiné. Un deuxième fourneau en ferait un autre en même temps."
	if id == "fourneau":
		return "Un clic dessus choisit son raffiné."
	return "Un clic dessus récupère sa production."


## Un échange chez le marchand : annonce de ce qui est reçu, son et sauvegarde.
func _sur_echange(id: String) -> void:
	var recu := PackedStringArray()
	var donnees := Game.atelier.marchand.echange(id)
	for ressource: String in donnees["recoit"]:
		recu.append("%s ×%d" % [Game.nom_ressource(ressource), int(donnees["recoit"][ressource])])
	_interface.annoncer("Échangé : %s." % " + ".join(recu))
	Son.jouer("echange")
	_interface.rafraichir_inventaire()
	partie_modifiee.emit()


## Temps du marchand sur l'île : arrivée (annonce et corne) et départ (son panneau se ferme).
func _avancer_marchand(secondes: float) -> void:
	var evenement := Game.atelier.marchand.avancer(secondes, true, Game.atelier.palier)
	if evenement == "arrivee":
		_interface.annoncer("Le marchand de vent est là : clic sur son dirigeable pour échanger.", 6.0)
		Son.jouer("marchand")
	elif evenement == "depart":
		_marchand.fermer()
		_interface.annoncer("Le marchand de vent repart. Il repassera plus tard.")


## Position du dirigeable (640x360) : il glisse depuis le bord droit, se balance doucement, puis y repart.
func position_marchand() -> Vector2:
	var marchand := Game.atelier.marchand
	var vol := minf(marchand.temps_present(), marchand.restant) / DUREE_VOL
	var x := lerpf(DEPART_MARCHAND_X, POSITION_MARCHAND.x, smoothstep(0.0, 1.0, clampf(vol, 0.0, 1.0)))
	var balancement := roundf(sin(ArtAbysse.temps() * 1.4)) * 2.0
	return Vector2(roundf(x / 2.0) * 2.0, POSITION_MARCHAND.y + balancement)


func _souris_sur_marchand() -> bool:
	if not Game.atelier.marchand.est_present():
		return false
	var centre := position_marchand()
	return absf(_souris.x - centre.x) <= ZONE_MARCHAND.x and absf(_souris.y - centre.y) <= ZONE_MARCHAND.y


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement is InputEventMouse:
		_souris = (evenement as InputEventMouse).position
	if evenement.is_action_pressed("inventaire"):
		_basculer_inventaire()
		get_viewport().set_input_as_handled()
	elif evenement.is_action_pressed("atelier"):
		_basculer_atelier()
		get_viewport().set_input_as_handled()
	elif evenement.is_action_pressed("carnet"):
		basculer_carnet()
		get_viewport().set_input_as_handled()
	elif evenement.is_action_pressed("pause") and panneau_ouvert():
		_fermer_panneaux()
		get_viewport().set_input_as_handled()
	elif panneau_ouvert():
		return
	elif evenement.is_action_pressed("clic"):
		_mettre_a_jour_survol()
		_clic()
		get_viewport().set_input_as_handled()
	elif evenement.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		plongee_demandee.emit()


func _process(delta: float) -> void:
	_avancer_marchand(delta)
	_interface.marquer_carnet(Game.atelier.carnet.a_voir != "")
	_gerer_nuages(delta)
	_mettre_a_jour_survol()
	_gerer_maintien(delta)
	_interface.definir_aide(_texte_aide())


# --- Récolte ----------------------------------------------------------------

func _clic() -> void:
	if _survol_cloche:
		plongee_demandee.emit()
	elif _survol_cabane:
		_basculer_atelier()
	elif _survol_marchand:
		ouvrir_marchand()
	elif _survol_ilot != "":
		_panneau.fermer()
		_atelier.ouvrir()
		_atelier.choisir_onglet("construction")
		for id: String in Atelier.CONSTRUCTIONS:
			if Game.atelier.ilot_de(id) == _survol_ilot:
				_atelier.selectionner(id)
	elif _survol_emplacement != "":
		_panneau.fermer()
		_atelier.ouvrir_machines(_survol_emplacement)
	elif _survol != null and _survol.forme == SourceRessource.Forme.FOURNEAU:
		_recolter(_survol, _survol.stock)
		_panneau.fermer()
		_atelier.ouvrir_fourneau(str(_survol.get_meta("lieu")))
	elif _survol != null:
		match _survol.mode:
			SourceRessource.Mode.CLIC:
				_recolter(_survol, 1)
			SourceRessource.Mode.RESERVE:
				_recolter(_survol, _survol.stock)


func _gerer_maintien(delta: float) -> void:
	var cible := _survol
	var actif := (
		cible != null
		and cible.mode == SourceRessource.Mode.MAINTIEN
		and cible.est_disponible()
		and not panneau_ouvert()
		and Input.is_action_pressed("clic")
	)
	if not actif:
		_arreter_maintien()
		return
	if cible != _maintien:
		_arreter_maintien()
		_maintien = cible
	_progres_maintien += delta / cible.duree_maintien
	cible.progres = minf(_progres_maintien, 1.0)
	if _progres_maintien >= 1.0:
		_progres_maintien = 0.0
		cible.progres = 0.0
		_recolter(cible, 1)


## Remet la jauge à zéro : seule l'unité en cours est perdue.
func _arreter_maintien() -> void:
	if is_instance_valid(_maintien):
		_maintien.progres = 0.0
	_maintien = null
	_progres_maintien = 0.0


func _recolter(source: SourceRessource, nombre: int) -> void:
	if nombre <= 0 or not source.est_disponible():
		return
	var place := Game.inventaire.place(source.id_ressource)
	if place <= 0:
		_interface.annoncer("Inventaire plein : %s" % Game.nom_ressource(source.id_ressource))
		return
	var prises := source.prendre(mini(nombre, ceili(float(place) / source.rendement)))
	var pris := Game.inventaire.ajouter(source.id_ressource, prises * source.rendement)
	_afficher_gain(source.position, pris)
	Son.jouer(SONS_RECOLTE[source.forme])
	_interface.rafraichir_inventaire()
	if source.forme == SourceRessource.Forme.NUAGE and not source.est_disponible():
		source.queue_free()


func _afficher_gain(lieu: Vector2, nombre: int) -> void:
	var etiquette := Label.new()
	etiquette.text = "+%d" % nombre
	etiquette.position = (lieu + Vector2(-8.0, -30.0)).round()
	Pixel.texte(etiquette, "nuage.4", ArtIle.CONTOUR)
	_effets.add_child(etiquette)
	# Pas de fondu (il créerait des couleurs hors palette) : le texte monte au pixel près, puis disparaît.
	var animation := etiquette.create_tween()
	animation.tween_method(func(y: float) -> void: etiquette.position.y = roundf(y),
		etiquette.position.y, etiquette.position.y - MONTEE_EFFET, DUREE_EFFET)
	animation.tween_callback(etiquette.queue_free)


func _souris_sur_cloche() -> bool:
	return cloche_visible and absf(_souris.x - POSITION_CLOCHE.x) <= ZONE_CLOCHE.x \
			and absf(_souris.y - POSITION_CLOCHE.y) <= ZONE_CLOCHE.y


## Source sous la souris dans ce conteneur (sources fixes et machines, ou nuages).
func _source_sous_souris(conteneur: Node2D) -> SourceRessource:
	for enfant in conteneur.get_children():
		var source := enfant as SourceRessource
		if source != null and not source.is_queued_for_deletion() and source.contient(_souris):
			return source
	return null


func _mettre_a_jour_survol() -> void:
	var sur_cloche := not panneau_ouvert() and _souris_sur_cloche()
	var sur_cabane := not panneau_ouvert() and not sur_cloche \
		and absf(_souris.x - POSITION_CABANE.x) <= ZONE_CABANE.x and absf(_souris.y - POSITION_CABANE.y) <= ZONE_CABANE.y
	# Priorité du clic : cloche, cabane, dirigeable du marchand, sources fixes et machines, îlot isolé,
	# emplacement libre ; un nuage qui passe devant ne prend le clic que si rien d'autre n'est sous la souris.
	var sur_marchand := not panneau_ouvert() and not sur_cloche and not sur_cabane and _souris_sur_marchand()
	_survol_marchand = sur_marchand
	var libre := not panneau_ouvert() and not sur_cloche and not sur_cabane and not sur_marchand
	var survol: SourceRessource = _source_sous_souris(_sources) if libre else null
	_survol_cloche = sur_cloche
	_survol_cabane = sur_cabane
	_survol_ilot = ""
	if libre and survol == null:
		_survol_ilot = _ilot_isole_sous_souris()
	_survol_emplacement = ""
	if libre and survol == null and _survol_ilot == "":
		_survol_emplacement = _emplacement_sous_souris()
	if libre and survol == null and _survol_ilot == "" and _survol_emplacement == "":
		survol = _source_sous_souris(_nuages)
	if survol != _survol:
		if is_instance_valid(_survol):
			_survol.en_survol = false
		_survol = survol
		if _survol != null:
			_survol.en_survol = true
	var cliquable := _survol_cloche or _survol_cabane or _survol_marchand or _survol_ilot != "" or _survol_emplacement != "" \
		or (_survol != null and _survol.est_disponible())
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if cliquable else Input.CURSOR_ARROW)


func _texte_aide() -> String:
	if _survol_cloche:
		return "Plonger : clic sur la cloche (ou E / Espace)"
	if _survol_cabane:
		return "Atelier : clic sur la cabane (ou C)"
	if _survol_marchand:
		return "Marchand de vent : clic pour échanger (il repart dans %d s)" % ceili(Game.atelier.marchand.restant)
	if _survol_ilot != "":
		return str(_ilot(_survol_ilot)["aide"])
	if _survol_emplacement != "":
		return "Emplacement libre : clic pour construire une machine"
	if _survol != null:
		var source := _survol
		var nom := source.nom if source.nom != "" else Game.nom_ressource(source.id_ressource)
		if source.forme == SourceRessource.Forme.ENTREPOT:
			return "%s : jusqu'à %d de chaque ressource" % [nom, Game.inventaire.plafond]
		if source.forme == SourceRessource.Forme.FOURNEAU:
			return _aide_fourneau(source)
		if source.forme == SourceRessource.Forme.SONDE and not source.est_disponible():
			return "%s : produit pendant les plongées" % nom
		if not source.est_disponible():
			return "%s : se recharge avec le temps" % nom
		match source.mode:
			SourceRessource.Mode.CLIC:
				return "%s : clic pour récolter" % nom
			SourceRessource.Mode.MAINTIEN:
				return "%s : maintiens le clic" % nom
			SourceRessource.Mode.RESERVE:
				return "%s : clic pour tout récupérer (%d)" % [nom, source.stock]
	return "Clique sur la cloche (ou E) pour plonger"


# --- Création des sources -----------------------------------------------------

func _creer_sources() -> void:
	var reglage: Dictionary = _reglages["eolienne"]
	_eolienne = _nouvelle_source(reglage, SourceRessource.Mode.RESERVE, SourceRessource.Forme.EOLIENNE)
	_eolienne.position = _vecteur(reglage["position"])
	_eolienne.rayon_clic = 22.0
	_sources.add_child(_eolienne)

	reglage = _reglages["filons"]
	for position_filon: Array in reglage["positions"]:
		var filon := _nouvelle_source(reglage, SourceRessource.Mode.MAINTIEN, SourceRessource.Forme.FILON)
		filon.position = _vecteur(position_filon)
		filon.duree_maintien = float(reglage["duree_maintien"])
		filon.rayon_clic = 13.0
		_sources.add_child(filon)
		_filons.append(filon)

	reglage = _ilot("ilot_est")["bassin"]
	_bassin = _nouvelle_source(reglage, SourceRessource.Mode.MAINTIEN, SourceRessource.Forme.BASSIN)
	_bassin.position = _vecteur(reglage["position"])
	_bassin.duree_maintien = float(reglage["duree_maintien"])
	_bassin.rayon_clic = 13.0
	actualiser_ilot()


# --- Machines et emplacements ------------------------------------------------------

## Crée les machines construites à l'atelier (et retire celles qui n'y sont plus : nouvelle partie),
## applique leurs améliorations, et retire de l'île les filons couverts par une foreuse.
func actualiser_machines() -> void:
	var atelier := Game.atelier
	for lieu: String in _machines.keys():
		if atelier.machines.get(lieu) != _machines[lieu].get_meta("machine"):
			_machines[lieu].queue_free()
			_sources.remove_child(_machines[lieu])
			_machines.erase(lieu)
	for lieu: String in atelier.machines:
		var id: String = atelier.machines[lieu]
		if not _machines.has(lieu):
			var source := SourceRessource.new()
			source.id_ressource = str(atelier.machine(id)["ressource"])
			source.nom = atelier.nom_machine(id)
			source.mode = SourceRessource.Mode.RESERVE
			source.forme = FORMES_MACHINES[id]
			source.rayon_clic = RAYON_MACHINE
			source.position = centre_emplacement(lieu)
			source.set_meta("machine", id)
			source.set_meta("lieu", lieu)
			_sources.add_child(source)
			_machines[lieu] = source
		var machine_ile: SourceRessource = _machines[lieu]
		machine_ile.plafond = atelier.plafond_machine(id)
		if atelier.en_plongee(id):
			machine_ile.recharge_plongee_s = atelier.recharge_machine(id)
			machine_ile.recharge_s = 0.0
		else:
			machine_ile.recharge_s = atelier.recharge_machine(id)
		if id == "fourneau":
			var raffine := atelier.recette_fourneau(lieu)
			machine_ile.id_ressource = raffine
			machine_ile.condition = _cycle_fourneau.bind(raffine)
	for donnees: Dictionary in atelier.emplacements():
		if donnees.has("filon"):
			var filon := _filons[int(donnees["filon"])]
			var couvert := atelier.machines.has(str(donnees["id"]))
			if couvert and filon.get_parent() != null:
				_sources.remove_child(filon)
			elif not couvert and filon.get_parent() == null:
				_sources.add_child(filon)


## Un cycle du fourneau : ingrédients pris dans l'inventaire, dont l'affichage suit.
func _cycle_fourneau(raffine: String) -> bool:
	if not Game.atelier.consommer_fourneau(raffine):
		return false
	_interface.rafraichir_inventaire()
	if _atelier.est_ouvert():
		_atelier.rafraichir()
	return true


## Avant un changement de recette : la réserve du fourneau (l'ancien raffiné) passe dans l'inventaire.
func _vider_fourneau(lieu: String) -> void:
	var fourneau := machine(lieu)
	if fourneau != null and fourneau.stock > 0 and fourneau.id_ressource != "":
		Game.inventaire.ajouter(fourneau.id_ressource, fourneau.prendre(fourneau.stock))


func _aide_fourneau(fourneau: SourceRessource) -> String:
	if fourneau.id_ressource == "":
		return "Fourneau à l'arrêt : clic pour choisir le raffiné"
	var nom := Game.nom_ressource(fourneau.id_ressource).to_lower()
	if fourneau.stock > 0:
		return "Fourneau (%s) : clic pour récupérer %d et changer de recette" % [nom, fourneau.stock]
	if not fourneau.en_activite():
		return "Fourneau (%s) : il manque des ingrédients dans l'inventaire" % nom
	return "Fourneau : %s en cours (clic pour changer)" % nom


## Machine posée sur un emplacement (null s'il est libre).
func machine(lieu: String) -> SourceRessource:
	return _machines.get(lieu)


## Centre de la zone cliquable d'un emplacement (640x360), au-dessus du sol.
func centre_emplacement(lieu: String) -> Vector2:
	return _vecteur(Game.atelier.emplacement(lieu)["position"]) - Vector2(0.0, ZONE_EMPLACEMENT.y)


func _emplacement_sous_souris() -> String:
	for lieu: String in Game.atelier.emplacements_libres():
		var centre := centre_emplacement(lieu)
		if absf(_souris.x - centre.x) <= ZONE_EMPLACEMENT.x and absf(_souris.y - centre.y) <= ZONE_EMPLACEMENT.y:
			return lieu
	return ""


# --- Îlot ---------------------------------------------------------------------------

## Réglages d'un îlot (data/ile.json).
func _ilot(id: String) -> Dictionary:
	for donnees: Dictionary in _reglages["ilots"]:
		if str(donnees["id"]) == id:
			return donnees
	return {}


func ilot_relie(id: String = "ilot_est") -> bool:
	return Game.atelier.est_relie(id)


## Le bassin n'existe sur l'île (récolte, recharge, dessin) que si l'îlot de l'est est relié.
func actualiser_ilot() -> void:
	var relie := ilot_relie("ilot_est")
	if relie and _bassin.get_parent() == null:
		_sources.add_child(_bassin)
	elif not relie and _bassin.get_parent() != null:
		_sources.remove_child(_bassin)


func bassin() -> SourceRessource:
	return _bassin


## Centre de la zone de survol d'un îlot (640x360).
func centre_ilot(id: String = "ilot_est") -> Vector2:
	return _vecteur(_ilot(id)["position"]) + Vector2(0.0, 18.0)


## Îlot non relié sous la souris (vide s'il n'y en a pas).
func _ilot_isole_sous_souris() -> String:
	for donnees: Dictionary in _reglages["ilots"]:
		var id := str(donnees["id"])
		var zone := _vecteur(donnees["zone"])
		var centre := centre_ilot(id)
		if not ilot_relie(id) and absf(_souris.x - centre.x) <= zone.x and absf(_souris.y - centre.y) <= zone.y:
			return id
	return ""


func _nouvelle_source(reglage: Dictionary, mode: SourceRessource.Mode, forme: SourceRessource.Forme) -> SourceRessource:
	var source := SourceRessource.new()
	source.id_ressource = str(reglage["ressource"])
	source.mode = mode
	source.forme = forme
	source.plafond = int(reglage["plafond"])
	source.stock = int(reglage["stock_initial"])
	source.recharge_s = float(reglage["recharge_s"])
	return source


func _vecteur(valeur: Array) -> Vector2:
	return Vector2(float(valeur[0]), float(valeur[1]))


# --- Nuages -------------------------------------------------------------------

func _gerer_nuages(delta: float) -> void:
	for enfant in _nuages.get_children():
		if (enfant as Node2D).position.x > 680.0:
			enfant.queue_free()
	_attente_nuage += delta
	_completer_nuages()


func _completer_nuages() -> void:
	var reglage: Dictionary = _reglages["nuages"]
	var nombre := _nombre_nuages()
	# Jamais moins que le minimum : on en fait apparaître tout de suite dans l'écran.
	while nombre < int(reglage["minimum"]):
		_creer_nuage(_hasard.randf_range(60.0, 580.0))
		nombre += 1
	# Ensuite, un nouveau nuage arrive par la gauche toutes les « apparition_s » secondes.
	if nombre >= int(reglage["maximum"]):
		_attente_nuage = 0.0
	elif _attente_nuage >= float(reglage["apparition_s"]):
		_attente_nuage = 0.0
		_creer_nuage(-30.0)


func _nombre_nuages() -> int:
	var nombre := 0
	for enfant in _nuages.get_children():
		if not enfant.is_queued_for_deletion():
			nombre += 1
	return nombre


func _creer_nuage(x: float) -> void:
	var reglage: Dictionary = _reglages["nuages"]
	var nuage := SourceRessource.new()
	nuage.id_ressource = str(reglage["ressource"])
	nuage.mode = SourceRessource.Mode.CLIC
	nuage.forme = SourceRessource.Forme.NUAGE
	nuage.plafond = int(reglage["prises"])
	nuage.rendement = int(reglage.get("ouates_par_prise", 1))
	nuage.stock = nuage.plafond
	nuage.rayon_clic = 22.0
	nuage.derive = _hasard.randf_range(float(reglage["vitesse_min"]), float(reglage["vitesse_max"]))
	nuage.position = Vector2(x, _hasard.randf_range(float(reglage["y_min"]), float(reglage["y_max"])))
	_nuages.add_child(nuage)


# --- Départ et retour ---------------------------------------------------------

## Appelé au lancement de la descente : l'île se fige et la cloche part avec la transition.
func preparer_depart() -> void:
	_arreter_maintien()
	for effet in _effets.get_children():
		effet.queue_free()
	_fermer_panneaux()
	_interface.visible = false
	cloche_visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	process_mode = Node.PROCESS_MODE_DISABLED


## L'île redevient active (fin de remontée, ou retour à l'écran titre depuis une plongée).
func reprendre() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	position = Vector2.ZERO
	visible = true
	cloche_visible = true
	_interface.visible = true


## Interface de l'île cachée sous l'écran titre (le décor reste visible).
func afficher_interface(afficher: bool) -> void:
	_interface.visible = afficher
	if not afficher:
		_fermer_panneaux()
		_arreter_maintien()


## Appelé à la fin de la remontée : rattrape la recharge, range le butin, annonce le résultat.
func arriver(temps_plongee: float, gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
	reprendre()
	rattraper(temps_plongee)
	# Le temps de plongée compte pour le passage du marchand (s'il arrive, il attend le retour sur l'île).
	Game.atelier.marchand.avancer(temps_plongee, false, Game.atelier.palier)
	for lieu: String in _machines:
		(_machines[lieu] as SourceRessource).recharger_plongee(temps_plongee)

	var refuse := Game.inventaire.ajouter_tout(gardees)
	var nb_gardees := _total(gardees) - _total(refuse)
	var nb_perdues := _total(perdues)
	if urgence and nb_perdues > 0:
		_interface.annoncer("Tu as perdu %s ! %s." % [_unites(nb_perdues), _sauvees(nb_gardees)])
	elif urgence and nb_gardees > 0:
		_interface.annoncer("Remontée d'urgence : rien de perdu, %s." % _sauvees(nb_gardees))
	elif urgence:
		_interface.annoncer("Remontée d'urgence : la cloche est de retour.")
	elif nb_gardees > 0:
		_interface.annoncer("Butin rangé : %s." % _unites(nb_gardees))
	if not refuse.is_empty():
		_interface.annoncer("Inventaire plein : %s laissée(s) à l'abysse." % _unites(_total(refuse)))
	if Game.atelier.decouvrir(gardees.keys()):
		var noms: Array = []
		for id: String in Game.atelier.liste_machines():
			if int(Game.atelier.machine(id)["palier"]) == Game.atelier.palier:
				noms.append(Game.atelier.nom_machine(id).to_lower())
		var liste := ", ".join(PackedStringArray(noms.slice(0, -1))) + " et " + str(noms[-1]) if noms.size() > 1 \
			else "".join(PackedStringArray(noms))
		var texte := "Palier %d : %s à l'atelier, onglet Machines." % [Game.atelier.palier, liste]
		# Après l'annonce du butin (ou de la perte), pour ne pas la cacher.
		if _interface.texte_annonce() == "":
			_interface.annoncer(texte)
		else:
			get_tree().create_timer(InterfaceIle.DUREE_ANNONCE).timeout.connect(_interface.annoncer.bind(texte))
	_interface.rafraichir_inventaire()


## Fait avancer la recharge des sources comme si « secondes » s'étaient écoulées sur l'île.
func rattraper(secondes: float) -> void:
	for enfant in _sources.get_children():
		(enfant as SourceRessource).recharger(secondes)
	var reglage: Dictionary = _reglages["nuages"]
	var nouveaux := int((_attente_nuage + secondes) / float(reglage["apparition_s"]))
	_attente_nuage = 0.0
	for i in mini(nouveaux, int(reglage["maximum"]) - _nombre_nuages()):
		_creer_nuage(_hasard.randf_range(60.0, 580.0))


# --- Sauvegarde ------------------------------------------------------------------------

## État des sources fixes (les nuages ne sont pas sauvegardés : ils réapparaissent seuls).
func etat_sources() -> Dictionary:
	var filons: Array = []
	for filon in _filons:
		filons.append(filon.etat())
	var machines := {}
	for lieu: String in _machines:
		machines[lieu] = _machines[lieu].etat()
	return {"eolienne": _eolienne.etat(), "filons": filons, "bassin": _bassin.etat(), "machines": machines}


## Reprend l'état sauvegardé des sources ; ce qui manque ou est faux garde la valeur de départ.
func restaurer_sources(donnees: Dictionary) -> void:
	reinitialiser_sources()
	if donnees.get("eolienne") is Dictionary:
		_eolienne.restaurer(donnees["eolienne"])
	var filons = donnees.get("filons")
	if filons is Array:
		for i in mini((filons as Array).size(), _filons.size()):
			if filons[i] is Dictionary:
				_filons[i].restaurer(filons[i])
	if donnees.get("bassin") is Dictionary:
		_bassin.restaurer(donnees["bassin"])
	actualiser_ilot()
	actualiser_machines()
	var machines = donnees.get("machines")
	if machines is Dictionary:
		for lieu: String in _machines:
			if machines.get(lieu) is Dictionary:
				_machines[lieu].restaurer(machines[lieu])
	queue_redraw()


## Sources remises à leur stock de départ (nouvelle partie).
func reinitialiser_sources() -> void:
	_eolienne.restaurer({"stock": int(_reglages["eolienne"]["stock_initial"]), "recharge": 0.0})
	for filon in _filons:
		filon.restaurer({"stock": int(_reglages["filons"]["stock_initial"]), "recharge": 0.0})
	_bassin.restaurer({"stock": int(_ilot("ilot_est")["bassin"]["stock_initial"]), "recharge": 0.0})
	actualiser_ilot()
	actualiser_machines()
	for lieu: String in _machines:
		_machines[lieu].restaurer({"stock": 0, "recharge": 0.0})
	_interface.rafraichir_inventaire()


func _total(butin: Dictionary) -> int:
	var total := 0
	for id: String in butin:
		total += int(butin[id])
	return total


func _unites(nombre: int) -> String:
	return "%d unité" % nombre if nombre <= 1 else "%d unités" % nombre


func _sauvees(nombre: int) -> String:
	return "%d sauvée" % nombre if nombre <= 1 else "%d sauvées" % nombre


# --- Dessin du monde (320x180) --------------------------------------------------------

func _dessiner_monde(toile: Node2D) -> void:
	toile.draw_texture(ArtIle.fond_ile(K), Vector2.ZERO)
	for enfant in _nuages.get_children():
		if not enfant.is_queued_for_deletion():
			(enfant as SourceRessource).dessiner_monde(toile)
	_dessiner_marchand(toile)
	_dessiner_cabane(toile)
	_dessiner_ilots(toile)
	_dessiner_emplacements(toile)
	for enfant in _sources.get_children():
		(enfant as SourceRessource).dessiner_monde(toile)
	if cloche_visible:
		var cloche := VueMonde.vers_monde(POSITION_CLOCHE)
		var texture := ArtIle.cloche(K)
		var haut := floorf(cloche.y - texture.get_height() / 2.0)
		var attache := VueMonde.vers_monde(ATTACHE_CABLE)
		toile.draw_rect(Rect2(attache.x, attache.y, 1, haut - attache.y + 1), Palette.couleur("metal.3"))
		Pixel.sprite_ombre(toile, texture, cloche, Palette.plus_sombre(ArtIle.couleur_ciel_monde(cloche.y)))
		if _survol_cloche:
			var zone := (ZONE_CLOCHE * K).round()
			Pixel.cadre(toile, Rect2(cloche - zone, zone * 2.0 + Vector2.ONE), Palette.couleur("nuage.4"))


## Dirigeable du marchand (devant les nuages, derrière les îlots) et son hélice qui tourne.
func _dessiner_marchand(toile: Node2D) -> void:
	if not Game.atelier.marchand.est_present():
		return
	var centre := VueMonde.vers_monde(position_marchand())
	var texture := ArtIle.dirigeable()
	Pixel.sprite_ombre(toile, texture, centre, Palette.plus_sombre(ArtIle.couleur_ciel_monde(centre.y)))
	var coin := (centre - texture.get_size() / 2.0).floor()
	var moyeu := coin + Vector2(texture.get_width(), 6)
	toile.draw_rect(Rect2(moyeu - Vector2(1, 0), Vector2(2, 1)), Palette.couleur(ArtIle.CONTOUR))
	var tour := int(ArtAbysse.temps() * 10.0) % 2
	var pale := Rect2(moyeu + Vector2(1, -2), Vector2(1, 5)) if tour == 0 else Rect2(moyeu + Vector2(0, 0), Vector2(3, 1))
	toile.draw_rect(pale, Palette.couleur("metal.3"))
	if _survol_marchand:
		var zone := (ZONE_MARCHAND * K).round()
		Pixel.cadre(toile, Rect2(centre - zone, zone * 2.0 + Vector2.ONE), Palette.couleur("nuage.4"))


## Cabane de l'atelier : fenêtre allumée et fumée qui monte quand une fabrication est possible.
func _dessiner_cabane(toile: Node2D) -> void:
	var centre := VueMonde.vers_monde(POSITION_CABANE)
	var possible := _fabrication_possible()
	var texture := ArtIle.cabane(possible)
	Pixel.sprite_ombre(toile, texture, centre, Palette.couleur("herbe.3"))
	if possible:
		var cheminee := (centre - texture.get_size() / 2.0).floor() + Vector2(12, -1)
		var pas := int(ArtAbysse.temps() * 3.0)
		for bouffee in 2:
			var montee := posmod(pas + bouffee * 3, 6)
			toile.draw_rect(Rect2(cheminee + Vector2(posmod(montee, 2), -montee), Vector2.ONE), Palette.couleur("nuage.3"))
	if _survol_cabane:
		var zone := (ZONE_CABANE * K).round()
		Pixel.cadre(toile, Rect2(centre - zone, zone * 2.0 + Vector2.ONE), Palette.couleur("nuage.4"))


## Îlots (assombris tant qu'ils ne sont pas reliés), puis leur passerelle ou leur pont, ou des
## pointillés or à leur place.
func _dessiner_ilots(toile: Node2D) -> void:
	for donnees: Dictionary in _reglages["ilots"]:
		_dessiner_ilot(toile, donnees)


func _dessiner_ilot(toile: Node2D, donnees: Dictionary) -> void:
	var id := str(donnees["id"])
	var relie := ilot_relie(id)
	var texture := ArtIle.ilot(relie)
	var haut := VueMonde.vers_monde(_vecteur(donnees["position"]))
	var coin := haut - Vector2(floorf(texture.get_width() / 2.0), 1.0)
	var ombre := Palette.plus_sombre(ArtIle.couleur_ciel_monde(coin.y + texture.get_height() / 2.0))
	toile.draw_texture(Pixel.silhouette(texture, ombre), coin + Vector2.ONE)
	toile.draw_texture(texture, coin)
	var bouts: Array = donnees["passerelle"]
	var a := VueMonde.vers_monde(_vecteur(bouts[0]))
	var b := VueMonde.vers_monde(_vecteur(bouts[1]))
	# Un point par pixel du monde le long du plus grand écart (passerelle horizontale ou pont en pente).
	var longueur := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in longueur + 1:
		var t := float(i) / longueur
		var y := roundf(lerpf(a.y, b.y, t) + 3.0 * sin(PI * t))
		var x := roundf(lerpf(a.x, b.x, t))
		if not relie:
			if i % 2 == 0:
				toile.draw_rect(Rect2(x, y, 1, 1), Palette.couleur("or.3"))
			continue
		# Planches (deux tons alternés), rambarde en fil de nuage, poteaux tous les 7 pixels ;
		# l'arche de braise : pierres sombres veinées d'or, rambarde de braise.
		var arche := str(donnees.get("style", "")) == "arche"
		var planche := ("roche.2" if i % 3 != 0 else "or.3") if arche else ("terre.3" if i % 3 != 0 else "terre.2")
		toile.draw_rect(Rect2(x, y, 1, 1), Palette.couleur(planche))
		toile.draw_rect(Rect2(x, y + 1, 1, 1), Palette.couleur(ArtIle.CONTOUR))
		toile.draw_rect(Rect2(x, y - 3, 1, 1), Palette.couleur("or.4" if arche else "nuage.4"))
		if i % 7 == 0:
			toile.draw_rect(Rect2(x, y - 3, 1, 3), Palette.couleur("roche.1" if arche else "terre.1"))
	if _survol_ilot == id:
		var zone := (_vecteur(donnees["zone"]) * K).round()
		Pixel.cadre(toile, Rect2(VueMonde.vers_monde(centre_ilot(id)) - zone, zone * 2.0 + Vector2.ONE), Palette.couleur("nuage.4"))


## Emplacements libres : une dalle de pierre et, au-dessus, la silhouette en pointillés or d'une machine.
func _dessiner_emplacements(toile: Node2D) -> void:
	for lieu: String in Game.atelier.emplacements_libres():
		var sol := VueMonde.vers_monde(_vecteur(Game.atelier.emplacement(lieu)["position"]))
		toile.draw_rect(Rect2(sol.x - 4, sol.y - 1, 9, 2), Palette.couleur(ArtIle.CONTOUR))
		toile.draw_rect(Rect2(sol.x - 3, sol.y - 1, 7, 1), Palette.couleur("roche.4"))
		for i in 10:
			if i % 2 == 0:
				toile.draw_rect(Rect2(sol.x - 4, sol.y - 3 - i, 1, 1), Palette.couleur("or.3"))
				toile.draw_rect(Rect2(sol.x + 4, sol.y - 3 - i, 1, 1), Palette.couleur("or.3"))
		for i in range(-2, 3, 2):
			toile.draw_rect(Rect2(sol.x + i, sol.y - 12, 1, 1), Palette.couleur("or.3"))
		if lieu == _survol_emplacement:
			var zone := (ZONE_EMPLACEMENT * K).round()
			Pixel.cadre(toile, Rect2(VueMonde.vers_monde(centre_emplacement(lieu)) - zone, zone * 2.0 + Vector2.ONE),
				Palette.couleur("nuage.4"))


func _fabrication_possible() -> bool:
	var atelier := Game.atelier
	for id: String in atelier.machines_disponibles():
		if atelier.peut_construire_machine(id):
			return true
		for genre: String in Atelier.GENRES_AMELIORATION:
			if atelier.machine(id).has("ameliorations") and atelier.peut_ameliorer_machine(id, genre):
				return true
	for id: String in Atelier.CONSTRUCTIONS:
		if atelier.peut_construire(id):
			return true
	for id: String in atelier.composants():
		if atelier.peut_fabriquer(id):
			return true
	for id: String in Atelier.AMELIORATIONS:
		if atelier.peut_ameliorer(id):
			return true
	return false

