class_name Transition
extends Node2D
## Transition entre l'île et la plongée : la cloche descend du ciel jusqu'à l'océan
## (ou remonte), la caméra la suit à travers 3 calques de nuages en parallaxe.
## Tout est dessiné en code, dans le repère « monde » de Decor :
## l'île occupe y = 0..360, la surface de l'océan est à y = HAUTEUR_CIEL.
## La dernière image de la descente correspond à la première image de la plongée
## (surface à 90 px du haut, cloche au centre en x) : le changement de scène ne se voit pas.
## Un clic ou une touche accélère la fin (DUREE_SAUT) avec un court fondu au noir tramé.
## Rendu pixel art : paliers de couleur tramés, nuages et cloche en sprites, positions entières.

signal terminee

const DUREE := 2.5
const DUREE_SAUT := 0.25
const NIVEAU_SAUT_MAX := 14       # densité maximale de la trame noire (sur 16)
const HAUTEUR_ECRAN := 360.0
const LARGEUR_ECRAN := 640.0
const Y_SURFACE_ECRAN_FIN := 90.0  # surface de l'océan dans la première image de la plongée
const PIXELS_PAR_METRE := 10.0

# Calques de nuages : facteur de parallaxe, nombre, taille du sprite, couleurs (palette)
const CALQUES := [
	{ "facteur": 0.3, "nombre": 3, "taille": Vector2i(18, 9), "couleur": "blanc", "ombre": "ciel_3" },
	{ "facteur": 0.6, "nombre": 6, "taille": Vector2i(26, 13), "couleur": "blanc", "ombre": "ciel_3" },
	{ "facteur": 1.0, "nombre": 8, "taille": Vector2i(40, 20), "couleur": "blanc", "ombre": "nacre" },
]
const GRAINE_NUAGES := 7

# Couleurs : noms de la palette
const COULEUR_SURFACE := "blanc"
const COULEUR_SOUS_SURFACE := "nacre"
const COULEUR_CABLE := "ardoise"
const COULEUR_SAUT := "noir"

var _actif := false
var _descente := true
var _t := 0.0                    # avancement dans le temps, 0 → 1
var _saut := false
var _t_debut_saut := 0.0
var _avance_saut := 0.0
var _fige := false
var _x_bas := LARGEUR_ECRAN / 2.0
var _ile: Node2D = null
var _zones: Array = []
var _nuages: Array = []          # par calque : liste de Vector2 (repère monde du calque)

@onready var _fond: Node2D = $Fond
@onready var _avant: Node2D = $Avant


func _ready() -> void:
	visible = false
	_fond.z_index = -10
	_avant.z_index = 10
	_fond.draw.connect(_dessiner_fond)
	_avant.draw.connect(_dessiner_avant)
	Pixel.activer_motifs(_fond)
	Pixel.activer_motifs(_avant)
	_zones = Donnees.charger_json("res://data/zones.json")
	_placer_nuages()


func est_active() -> bool:
	return _actif


## descente : île → océan ; sinon océan → île. x_bas : position x (écran) de la cloche côté océan.
func lancer(descente: bool, ile: Node2D, x_bas: float = LARGEUR_ECRAN / 2.0) -> void:
	_descente = descente
	_ile = ile
	_x_bas = x_bas
	_t = 0.0
	_saut = false
	_fige = false
	_actif = true
	visible = true
	_appliquer()


## Fige la transition à un instant donné (0 → 1), pour les captures d'écran.
func afficher_image(avancement: float) -> void:
	_fige = true
	_t = clampf(avancement, 0.0, 1.0)
	_appliquer()


func reprendre() -> void:
	_fige = false


func _unhandled_input(evenement: InputEvent) -> void:
	if not _actif or _saut:
		return
	var appui: bool = (evenement is InputEventKey and evenement.pressed and not evenement.is_echo()) \
			or (evenement is InputEventMouseButton and evenement.pressed)
	if appui:
		passer()
		get_viewport().set_input_as_handled()


## Passe la transition : la fin est jouée en DUREE_SAUT avec un fondu.
func passer() -> void:
	if not _actif or _saut:
		return
	_saut = true
	_t_debut_saut = _t
	_avance_saut = 0.0


func _process(delta: float) -> void:
	if not _actif or _fige:
		return
	if _saut:
		_avance_saut = minf(_avance_saut + delta / DUREE_SAUT, 1.0)
		_t = lerpf(_t_debut_saut, 1.0, _avance_saut)
	else:
		_t = minf(_t + delta / DUREE, 1.0)
	_appliquer()
	if _t >= 1.0:
		_actif = false
		visible = false
		terminee.emit()


## e : 0 = vue de l'île, 1 = vue de l'océan (première image de la plongée).
func _profondeur_visuelle() -> float:
	var lisse := smoothstep(0.0, 1.0, _t)
	return lisse if _descente else 1.0 - lisse


func _cloche_monde(e: float) -> Vector2:
	var x := lerpf(Ile.POSITION_CLOCHE.x, _x_bas, e)
	return Vector2(x, lerpf(Ile.POSITION_CLOCHE.y, Decor.HAUTEUR_CIEL, e))


## Centre vertical de la caméra (repère monde), arrondi au pixel : au départ l'écran de l'île,
## à la fin la cloche est à la surface, à 90 px du haut comme dans la plongée.
func _camera(e: float) -> float:
	var depart := HAUTEUR_ECRAN / 2.0 - Ile.POSITION_CLOCHE.y
	var fin := HAUTEUR_ECRAN / 2.0 - Y_SURFACE_ECRAN_FIN
	return roundf(_cloche_monde(e).y + lerpf(depart, fin, e))


func _vers_ecran(y_monde: float, camera: float, facteur: float = 1.0) -> float:
	return roundf(y_monde - (camera - HAUTEUR_ECRAN / 2.0) * facteur)


func _appliquer() -> void:
	# La transition dessine en coordonnées écran : on neutralise une éventuelle caméra restée active.
	get_viewport().canvas_transform = Transform2D.IDENTITY
	var camera := _camera(_profondeur_visuelle())
	if is_instance_valid(_ile):
		_ile.position.y = _vers_ecran(0.0, camera)
	_fond.queue_redraw()
	_avant.queue_redraw()


# --- Dessin ---------------------------------------------------------------------

func _couleur_monde(y_monde: float) -> Color:
	if y_monde < Decor.HAUTEUR_CIEL:
		return Decor.couleur_ciel(y_monde)
	return Decor.couleur_eau(_zones, y_monde - Decor.HAUTEUR_CIEL, PIXELS_PAR_METRE)


func _dessiner_fond() -> void:
	var camera := _camera(_profondeur_visuelle())
	var decalage := int(camera - HAUTEUR_ECRAN / 2.0)
	Pixel.bandes(_fond, 0.0, LARGEUR_ECRAN, 0.0, HAUTEUR_ECRAN, decalage, _couleur_monde)
	var surface := _vers_ecran(Decor.HAUTEUR_CIEL, camera)
	Pixel.rect(_fond, Rect2(0.0, surface - 1.0, LARGEUR_ECRAN, 1.0), Palette.couleur(COULEUR_SURFACE))
	Pixel.rect(_fond, Rect2(0.0, surface, LARGEUR_ECRAN, 1.0), Palette.couleur(COULEUR_SOUS_SURFACE))
	for calque in 2:
		_dessiner_calque(_fond, calque, camera)


func _dessiner_avant() -> void:
	var e := _profondeur_visuelle()
	var camera := _camera(e)
	var cloche := _cloche_monde(e)
	var cloche_ecran := Vector2(cloche.x, _vers_ecran(cloche.y, camera)).round()
	var attache := Vector2(Ile.ATTACHE_CABLE.x, _vers_ecran(Ile.ATTACHE_CABLE.y, camera))
	var haut_cloche := cloche_ecran.y - Cloche.HAUTEUR / 2.0
	if attache.x == cloche_ecran.x:
		var debut := maxf(attache.y, -1.0)
		Pixel.rect(_avant, Rect2(attache.x, debut, 1.0, maxf(haut_cloche - debut, 0.0)), Palette.couleur(COULEUR_CABLE))
	else:
		Pixel.ligne(_avant, attache, Vector2(cloche_ecran.x, haut_cloche), Palette.couleur(COULEUR_CABLE))
	Cloche.dessiner(_avant, cloche_ecran)
	_dessiner_calque(_avant, 2, camera)
	if _saut:
		var niveau := roundi(sin(PI * _avance_saut) * NIVEAU_SAUT_MAX)
		if niveau > 0:
			_avant.draw_texture_rect(Pixel.trame(niveau, Palette.couleur(COULEUR_SAUT)),
				Rect2(0.0, 0.0, LARGEUR_ECRAN, HAUTEUR_ECRAN), true)


func _dessiner_calque(toile: Node2D, calque: int, camera: float) -> void:
	var reglage: Dictionary = CALQUES[calque]
	var taille: Vector2i = reglage["taille"]
	var texture := Pixel.nuage(taille.x, taille.y, Palette.couleur(str(reglage["couleur"])),
		Palette.couleur(str(reglage["ombre"])))
	for centre: Vector2 in _nuages[calque]:
		var ecran := Vector2(centre.x, _vers_ecran(centre.y, camera, float(reglage["facteur"])))
		if ecran.y < -taille.y or ecran.y > HAUTEUR_ECRAN + taille.y:
			continue
		Pixel.sprite(toile, texture, ecran)


## Les nuages sont placés pour être hors écran au début et à la fin :
## ils n'apparaissent que pendant le trajet, quel que soit le sens.
func _placer_nuages() -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = GRAINE_NUAGES
	var camera_fin := _camera_fin()
	for reglage: Dictionary in CALQUES:
		var facteur := float(reglage["facteur"])
		var marge := float((reglage["taille"] as Vector2i).y)
		var y_min := HAUTEUR_ECRAN + marge
		var y_max := (camera_fin - HAUTEUR_ECRAN / 2.0) * facteur - marge
		var liste: Array[Vector2] = []
		for i in int(reglage["nombre"]):
			var y := lerpf(y_min, y_max, (i + hasard.randf_range(0.2, 0.8)) / float(reglage["nombre"]))
			liste.append(Vector2(hasard.randf_range(30.0, LARGEUR_ECRAN - 30.0), y))
		_nuages.append(liste)


func _camera_fin() -> float:
	return Decor.HAUTEUR_CIEL + HAUTEUR_ECRAN / 2.0 - Y_SURFACE_ECRAN_FIN
