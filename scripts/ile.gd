class_name Ile
extends Node2D
## L'île flottante : récolte à la souris (vent, nuages, cristaux solaires), inventaire,
## et départ en plongée en cliquant sur la cloche (ou E / Espace).
## Les sources se rechargent avec le temps, y compris pendant la plongée (voir rattraper()).

signal plongee_demandee

const POSITION_CLOCHE := Vector2(320.0, 318.0)
const ATTACHE_CABLE := Vector2(320.0, 288.0)
const ZONE_CLOCHE := Vector2(16.0, 18.0)      # demi-taille de la zone cliquable
const BANDE_CIEL := 6.0                       # le dégradé du ciel est dessiné par bandes
const DUREE_EFFET := 0.8
const MONTEE_EFFET := 18.0

# Formes de l'île (coordonnées écran)
const DESSOUS := [
	Vector2(140, 200), Vector2(500, 200), Vector2(470, 232), Vector2(420, 262), Vector2(360, 282),
	Vector2(320, 288), Vector2(280, 282), Vector2(220, 262), Vector2(170, 232),
]
const DESSUS := [Vector2(140, 200), Vector2(500, 200), Vector2(493, 208), Vector2(147, 208)]
const CENTRE_SOLEIL := Vector2(560.0, 58.0)

const COULEUR_ROCHE := Color("9a93b5")
const COULEUR_ROCHE_SOMBRE := Color("7a7397")
const COULEUR_DESSUS := Color("f4efe6")
const COULEUR_BORD := Color("e8b923")
const COULEUR_SOLEIL := Color("ffe08a")
const COULEUR_TREUIL := Color("4a4660")
const COULEUR_CABLE := Color("d8dde6")
const COULEUR_SURVOL := Color(1.0, 1.0, 1.0, 0.8)
const COULEUR_EFFET := Color("ffffff")
const COULEUR_EFFET_CONTOUR := Color("2a3550")

var cloche_visible := true:
	set(valeur):
		cloche_visible = valeur
		queue_redraw()

var _reglages: Dictionary = {}
var _eolienne: SourceRessource
var _filons: Array[SourceRessource] = []
var _souris := Vector2(-100.0, -100.0)
var _survol_cloche := false
var _survol: SourceRessource = null      # source sous la souris
var _maintien: SourceRessource = null
var _progres_maintien := 0.0
var _attente_nuage := 0.0
var _hasard := RandomNumberGenerator.new()

@onready var _nuages: Node2D = $Nuages
@onready var _sources: Node2D = $Sources
@onready var _effets: Node2D = $Effets
@onready var _interface: InterfaceIle = $HUD
@onready var _panneau: PanneauInventaire = $Inventaire


func _ready() -> void:
	_hasard.randomize()
	_reglages = Donnees.charger_json("res://data/ile.json")
	_creer_sources()
	for i in int(_reglages["nuages"]["minimum"]) + 1:
		_creer_nuage(_hasard.randf_range(60.0, 580.0))
	_interface.bouton_inventaire.pressed.connect(_panneau.basculer)
	_interface.rafraichir_inventaire()


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement is InputEventMouse:
		_souris = (evenement as InputEventMouse).position
	if evenement.is_action_pressed("inventaire"):
		_panneau.basculer()
		get_viewport().set_input_as_handled()
	elif evenement.is_action_pressed("pause"):
		if _panneau.est_ouvert():
			_panneau.fermer()
		else:
			get_tree().quit()
		get_viewport().set_input_as_handled()
	elif _panneau.est_ouvert():
		return
	elif evenement.is_action_pressed("clic"):
		_mettre_a_jour_survol()
		_clic()
		get_viewport().set_input_as_handled()
	elif evenement.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		plongee_demandee.emit()


func _process(delta: float) -> void:
	_gerer_nuages(delta)
	_mettre_a_jour_survol()
	_gerer_maintien(delta)
	_interface.definir_aide(_texte_aide())


# --- Récolte ----------------------------------------------------------------

func _clic() -> void:
	if _survol_cloche:
		plongee_demandee.emit()
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
		and not _panneau.est_ouvert()
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
	var pris := source.prendre(mini(nombre, place))
	Game.inventaire.ajouter(source.id_ressource, pris)
	_afficher_gain(source.position, pris)
	_interface.rafraichir_inventaire()
	if source.forme == SourceRessource.Forme.NUAGE and not source.est_disponible():
		source.queue_free()


func _afficher_gain(lieu: Vector2, nombre: int) -> void:
	var etiquette := Label.new()
	etiquette.text = "+%d" % nombre
	etiquette.position = lieu + Vector2(-8.0, -30.0)
	etiquette.add_theme_font_size_override("font_size", 12)
	etiquette.add_theme_color_override("font_color", COULEUR_EFFET)
	etiquette.add_theme_color_override("font_outline_color", COULEUR_EFFET_CONTOUR)
	etiquette.add_theme_constant_override("outline_size", 3)
	_effets.add_child(etiquette)
	var animation := etiquette.create_tween().set_parallel()
	animation.tween_property(etiquette, "position:y", etiquette.position.y - MONTEE_EFFET, DUREE_EFFET)
	animation.tween_property(etiquette, "modulate:a", 0.0, DUREE_EFFET)
	animation.chain().tween_callback(etiquette.queue_free)


func _souris_sur_cloche() -> bool:
	return cloche_visible and absf(_souris.x - POSITION_CLOCHE.x) <= ZONE_CLOCHE.x \
			and absf(_souris.y - POSITION_CLOCHE.y) <= ZONE_CLOCHE.y


func _source_sous_souris() -> SourceRessource:
	for conteneur: Node2D in [_nuages, _sources]:
		for enfant in conteneur.get_children():
			var source := enfant as SourceRessource
			if source != null and not source.is_queued_for_deletion() and source.contient(_souris):
				return source
	return null


func _mettre_a_jour_survol() -> void:
	var sur_cloche := not _panneau.est_ouvert() and _souris_sur_cloche()
	var survol: SourceRessource = null
	if not _panneau.est_ouvert() and not sur_cloche:
		survol = _source_sous_souris()
	if sur_cloche != _survol_cloche:
		_survol_cloche = sur_cloche
		queue_redraw()
	if survol != _survol:
		if is_instance_valid(_survol):
			_survol.en_survol = false
		_survol = survol
		if _survol != null:
			_survol.en_survol = true
	var cliquable := _survol_cloche or (_survol != null and _survol.est_disponible())
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if cliquable else Input.CURSOR_ARROW)


func _texte_aide() -> String:
	if _survol_cloche:
		return "Plonger : clic sur la cloche (ou E / Espace)"
	if _survol != null:
		var source := _survol
		var nom := Game.nom_ressource(source.id_ressource)
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
	_panneau.fermer()
	_interface.visible = false
	cloche_visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	process_mode = Node.PROCESS_MODE_DISABLED


## Appelé à la fin de la remontée : rattrape la recharge, range le butin, annonce le résultat.
func arriver(temps_plongee: float, gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	position = Vector2.ZERO
	cloche_visible = true
	_interface.visible = true
	rattraper(temps_plongee)

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


func _total(butin: Dictionary) -> int:
	var total := 0
	for id: String in butin:
		total += int(butin[id])
	return total


func _unites(nombre: int) -> String:
	return "%d unité" % nombre if nombre <= 1 else "%d unités" % nombre


func _sauvees(nombre: int) -> String:
	return "%d sauvée" % nombre if nombre <= 1 else "%d sauvées" % nombre


# --- Dessin -------------------------------------------------------------------

func _draw() -> void:
	var y := 0.0
	while y < 360.0:
		draw_rect(Rect2(0.0, y, 640.0, BANDE_CIEL + 1.0), DecorCiel.couleur(y + BANDE_CIEL / 2.0))
		y += BANDE_CIEL
	draw_circle(CENTRE_SOLEIL, 26.0, Color(COULEUR_SOLEIL, 0.3))
	draw_circle(CENTRE_SOLEIL, 18.0, COULEUR_SOLEIL)
	Ile.dessiner_ile(self, cloche_visible)
	if cloche_visible and _survol_cloche:
		draw_rect(Rect2(POSITION_CLOCHE - ZONE_CLOCHE, ZONE_CLOCHE * 2.0), COULEUR_SURVOL, false, 1.0)


## Corps de l'île, treuil et (si demandé) câble et cloche amarrée.
static func dessiner_ile(toile: CanvasItem, avec_cloche: bool, decalage: Vector2 = Vector2.ZERO) -> void:
	var dessous := PackedVector2Array()
	for point: Vector2 in DESSOUS:
		dessous.append(point + decalage)
	toile.draw_colored_polygon(dessous, COULEUR_ROCHE)
	var ombre := PackedVector2Array([
		Vector2(220, 262) + decalage, Vector2(280, 282) + decalage, Vector2(320, 288) + decalage,
		Vector2(360, 282) + decalage, Vector2(420, 262) + decalage, Vector2(320, 270) + decalage,
	])
	toile.draw_colored_polygon(ombre, COULEUR_ROCHE_SOMBRE)
	var dessus := PackedVector2Array()
	for point: Vector2 in DESSUS:
		dessus.append(point + decalage)
	toile.draw_colored_polygon(dessus, COULEUR_DESSUS)
	toile.draw_line(Vector2(140, 200) + decalage, Vector2(500, 200) + decalage, COULEUR_BORD, 2.0)
	toile.draw_rect(Rect2(Vector2(312, 282) + decalage, Vector2(16, 8)), COULEUR_TREUIL)
	if avec_cloche:
		var haut_cloche := POSITION_CLOCHE + decalage - Vector2(0.0, Cloche.HAUTEUR / 2.0)
		toile.draw_line(ATTACHE_CABLE + decalage, haut_cloche, COULEUR_CABLE, 2.0)
		Cloche.dessiner(toile, POSITION_CLOCHE + decalage)
