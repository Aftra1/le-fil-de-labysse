class_name Transition
extends Node2D
## Transition entre l'île et la plongée : la cloche descend du ciel jusqu'à l'océan
## (ou remonte), la caméra la suit à travers 3 calques de nuages en parallaxe.
## Tout est dessiné en code, dans le repère « monde » de DecorCiel :
## l'île occupe y = 0..360, la surface de l'océan est à y = HAUTEUR_CIEL.
## La dernière image de la descente correspond à la première image de la plongée
## (surface à 90 px du haut, cloche au centre en x) : le changement de scène ne se voit pas.
## Un clic ou une touche accélère la fin (DUREE_SAUT) avec un court fondu au noir.

signal terminee

const DUREE := 2.5
const DUREE_SAUT := 0.25
const OPACITE_SAUT := 0.9
const HAUTEUR_ECRAN := 360.0
const LARGEUR_ECRAN := 640.0
const Y_SURFACE_ECRAN_FIN := 90.0  # surface de l'océan dans la première image de la plongée
const BANDE := 6.0
const LONGUEUR_ZONE_1 := 1500.0    # px : même dégradé d'eau que la plongée

# Calques de nuages : facteur de parallaxe, nombre, rayon, opacité
const CALQUES := [
	{ "facteur": 0.3, "nombre": 3, "rayon": 10.0, "opacite": 0.45 },
	{ "facteur": 0.6, "nombre": 6, "rayon": 14.0, "opacite": 0.7 },
	{ "facteur": 1.0, "nombre": 8, "rayon": 20.0, "opacite": 0.85 },
]
const GRAINE_NUAGES := 7

const COULEUR_SURFACE := Color("ffffff")
const COULEUR_CABLE := Color("d8dde6")
const COULEUR_NUAGE := Color("ffffff")

var _actif := false
var _descente := true
var _t := 0.0                    # avancement dans le temps, 0 → 1
var _saut := false
var _t_debut_saut := 0.0
var _avance_saut := 0.0
var _fige := false
var _x_bas := LARGEUR_ECRAN / 2.0
var _ile: Node2D = null
var _eau_haut := Color("5fb4d9")
var _eau_bas := Color("1b4a78")
var _nuages: Array = []          # par calque : liste de Vector2 (repère monde du calque)

@onready var _fond: Node2D = $Fond
@onready var _avant: Node2D = $Avant


func _ready() -> void:
	visible = false
	_fond.z_index = -10
	_avant.z_index = 10
	_fond.draw.connect(_dessiner_fond)
	_avant.draw.connect(_dessiner_avant)
	var zones: Array = Donnees.charger_json("res://data/zones.json")
	_eau_haut = Color.html(str(zones[0]["couleur_haut"]))
	_eau_bas = Color.html(str(zones[0]["couleur_bas"]))
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
	return Vector2(x, lerpf(Ile.POSITION_CLOCHE.y, DecorCiel.HAUTEUR_CIEL, e))


## Centre vertical de la caméra (repère monde) : au départ l'écran de l'île,
## à la fin la cloche est à la surface, à 90 px du haut comme dans la plongée.
func _camera(e: float) -> float:
	var depart := HAUTEUR_ECRAN / 2.0 - Ile.POSITION_CLOCHE.y
	var fin := HAUTEUR_ECRAN / 2.0 - Y_SURFACE_ECRAN_FIN
	return _cloche_monde(e).y + lerpf(depart, fin, e)


func _vers_ecran(y_monde: float, camera: float, facteur: float = 1.0) -> float:
	return y_monde - (camera - HAUTEUR_ECRAN / 2.0) * facteur


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
	if y_monde < DecorCiel.HAUTEUR_CIEL:
		return DecorCiel.couleur(y_monde)
	var t := clampf((y_monde - DecorCiel.HAUTEUR_CIEL) / LONGUEUR_ZONE_1, 0.0, 1.0)
	return _eau_haut.lerp(_eau_bas, t)


func _dessiner_fond() -> void:
	var camera := _camera(_profondeur_visuelle())
	var y := 0.0
	while y < HAUTEUR_ECRAN:
		var y_monde := y + BANDE / 2.0 + camera - HAUTEUR_ECRAN / 2.0
		_fond.draw_rect(Rect2(0.0, y, LARGEUR_ECRAN, BANDE + 1.0), _couleur_monde(y_monde))
		y += BANDE
	var surface := _vers_ecran(DecorCiel.HAUTEUR_CIEL, camera)
	_fond.draw_line(Vector2(0.0, surface), Vector2(LARGEUR_ECRAN, surface), COULEUR_SURFACE, 2.0)
	for calque in 2:
		_dessiner_calque(_fond, calque, camera)


func _dessiner_avant() -> void:
	var e := _profondeur_visuelle()
	var camera := _camera(e)
	var cloche := _cloche_monde(e)
	var cloche_ecran := Vector2(cloche.x, _vers_ecran(cloche.y, camera))
	var attache := Vector2(Ile.ATTACHE_CABLE.x, _vers_ecran(Ile.ATTACHE_CABLE.y, camera))
	_avant.draw_line(attache, cloche_ecran - Vector2(0.0, Cloche.HAUTEUR / 2.0), COULEUR_CABLE, 2.0)
	Cloche.dessiner(_avant, cloche_ecran)
	_dessiner_calque(_avant, 2, camera)
	if _saut:
		var opacite := sin(PI * _avance_saut) * OPACITE_SAUT
		_avant.draw_rect(Rect2(0.0, 0.0, LARGEUR_ECRAN, HAUTEUR_ECRAN), Color(0.0, 0.0, 0.0, opacite))


func _dessiner_calque(toile: Node2D, calque: int, camera: float) -> void:
	var reglage: Dictionary = CALQUES[calque]
	var rayon := float(reglage["rayon"])
	var teinte := Color(COULEUR_NUAGE, float(reglage["opacite"]))
	for centre: Vector2 in _nuages[calque]:
		var ecran := Vector2(centre.x, _vers_ecran(centre.y, camera, float(reglage["facteur"])))
		if ecran.y < -rayon * 2.0 or ecran.y > HAUTEUR_ECRAN + rayon * 2.0:
			continue
		toile.draw_circle(ecran + Vector2(-rayon, rayon * 0.2), rayon * 0.75, teinte)
		toile.draw_circle(ecran, rayon, teinte)
		toile.draw_circle(ecran + Vector2(rayon, rayon * 0.2), rayon * 0.7, teinte)


## Les nuages sont placés pour être hors écran au début et à la fin :
## ils n'apparaissent que pendant le trajet, quel que soit le sens.
func _placer_nuages() -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = GRAINE_NUAGES
	var camera_fin := _camera_fin()
	for reglage: Dictionary in CALQUES:
		var facteur := float(reglage["facteur"])
		var marge := float(reglage["rayon"]) * 2.0
		var y_min := HAUTEUR_ECRAN + marge
		var y_max := (camera_fin - HAUTEUR_ECRAN / 2.0) * facteur - marge
		var liste: Array[Vector2] = []
		for i in int(reglage["nombre"]):
			var y := lerpf(y_min, y_max, (i + hasard.randf_range(0.2, 0.8)) / float(reglage["nombre"]))
			liste.append(Vector2(hasard.randf_range(30.0, LARGEUR_ECRAN - 30.0), y))
		_nuages.append(liste)


func _camera_fin() -> float:
	return DecorCiel.HAUTEUR_CIEL + HAUTEUR_ECRAN / 2.0 - Y_SURFACE_ECRAN_FIN
