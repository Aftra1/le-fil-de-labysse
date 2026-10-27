class_name Transition
extends Node2D
## Transition entre l'île et la plongée : la cloche descend du ciel jusqu'à l'océan
## (ou remonte), la caméra la suit à travers 3 calques de nuages en parallaxe.
##
## Rendu : deux vues du monde 320x180 (VueMonde) qui partagent la même caméra, l'une sous l'île
## (ciel, nuages lointains, mer), l'autre par-dessus (câble, cloche, nuages proches, fondu).
## Repère « colonne » en 640x360 : l'écran de l'île occupe y = 0..360, la mer est à y = HAUTEUR_MER.
##
## Raccords sans coupure :
## - le ciel est la même colonne de paliers que celle de l'île (ArtIle.dessiner_ciel) ;
## - sous la surface, on appelle le dessin de la plongée elle-même (dive.gd, dessiner_monde) ;
## - la dernière image de la descente est la première de la plongée (cloche en surface, à 90 px
##   du haut) ; la remontée part exactement de la cloche et de la caméra de la plongée.
## Un clic ou une touche accélère la fin (DUREE_SAUT) avec un court fondu tramé.

signal terminee

const DUREE := 2.5
const DUREE_SAUT := 0.25
const NIVEAU_SAUT_MAX := 14       # densité maximale de la trame noire (sur 16)
const ECRAN := Vector2(640.0, 360.0)
const HAUTEUR_MER := ArtIle.HAUTEUR_CIEL * VueMonde.ECHELLE    # 1800 en 640x360
const HAUT_CAMERA_PLONGEE := -90.0    # haut de la vue de la plongée quand la cloche est en surface
const CENTRE_PLONGEE := 320.0         # x de la colonne qui correspond au x = 0 de la plongée

# Calques de nuages : facteur de parallaxe, nombre, taille du sprite (pixels du monde)
const CALQUES := [
	{ "facteur": 0.3, "nombre": 3, "taille": Vector2i(10, 5) },
	{ "facteur": 0.6, "nombre": 6, "taille": Vector2i(14, 7) },
	{ "facteur": 1.0, "nombre": 8, "taille": Vector2i(22, 11) },
]
const GRAINE_NUAGES := 7
const COULEUR_CABLE := "metal.3"
const SEUIL_SURFACE_MONDE := 3.0      # cloche « en surface » (même seuil que la plongée, en pixels du monde)
const COULEUR_SAUT := "abysse.0"

var _actif := false
var _descente := true
var _t := 0.0                    # avancement dans le temps, 0 → 1
var _saut := false
var _t_debut_saut := 0.0
var _avance_saut := 0.0
var _fige := false
var _ile: Node2D = null
var _plongee: Node2D = null
var _cloche_bas := Vector2.ZERO  # position de la cloche dans la plongée (640x360)
var _decalage_camera_bas := 0.0  # écart de la caméra de la plongée par rapport à sa vue de surface
var _nuages: Array = []          # par calque : liste de Vector2 (repère colonne, 640x360)
var _fond := VueMonde.new()
var _avant := VueMonde.new()


func _ready() -> void:
	visible = false
	_fond.name = "Fond"
	_fond.z_index = -10
	_fond.dessiner = _dessiner_fond
	add_child(_fond)
	_avant.name = "Avant"
	_avant.z_index = 10
	_avant.transparent = true
	_avant.dessiner = _dessiner_avant
	add_child(_avant)
	_placer_nuages()


func est_active() -> bool:
	return _actif


## descente : île → océan ; sinon océan → île.
## plongee : la scène de plongée (dessinée sous la surface) ; cloche_bas : position de sa cloche
## (640x360) ; haut_camera_bas : haut de sa vue (pour une remontée qui part de la vue exacte).
func lancer(descente: bool, ile: Node2D, plongee: Node2D = null, cloche_bas: Vector2 = Vector2.ZERO,
		haut_camera_bas: float = HAUT_CAMERA_PLONGEE) -> void:
	_descente = descente
	_ile = ile
	_plongee = plongee
	_cloche_bas = cloche_bas
	_decalage_camera_bas = haut_camera_bas - HAUT_CAMERA_PLONGEE
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


## Temps restant avant la fin (en secondes), y compris quand la transition est passée.
func temps_restant() -> float:
	if _saut:
		return (1.0 - _avance_saut) * DUREE_SAUT
	return (1.0 - _t) * DUREE


## Temps écoulé depuis le début, à la vitesse normale (un saut l'accélère).
func temps_ecoule() -> float:
	return _t * DUREE


## Décalage d'écran (0 ou 1 px) de la grille du monde dans l'image actuelle.
func decalage_ecran() -> Vector2i:
	return _fond.decalage_ecran()


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


## e : 0 = vue de l'île, 1 = vue de la plongée en surface.
func _profondeur_visuelle() -> float:
	var lisse := smoothstep(0.0, 1.0, _t)
	return lisse if _descente else 1.0 - lisse


## Cloche dans la colonne (640x360) : du ponton de l'île à sa position dans la plongée.
func _cloche(e: float) -> Vector2:
	var bas := Vector2(CENTRE_PLONGEE, HAUTEUR_MER) + _cloche_bas
	return Ile.POSITION_CLOCHE.lerp(bas, e)


## Haut de la vue (640x360, entier) : au départ l'écran de l'île ; à la fin, la vue de la plongée.
func _haut_camera(e: float) -> float:
	# Écart entre le haut de la vue et la cloche : la cloche en bas de l'écran de l'île au départ,
	# à 90 px sous le haut de la vue à l'arrivée (comme dans la plongée).
	var ecart := lerpf(-Ile.POSITION_CLOCHE.y, HAUT_CAMERA_PLONGEE, e)
	return roundf(Ile.POSITION_CLOCHE.lerp(Vector2(CENTRE_PLONGEE, HAUTEUR_MER), e).y + ecart + _decalage_camera_bas * e)


func _appliquer() -> void:
	var haut := _haut_camera(_profondeur_visuelle())
	_fond.camera = Vector2(0.0, haut)
	_avant.camera = Vector2(0.0, haut)
	if is_instance_valid(_ile):
		_ile.position.y = -haut


# --- Dessin (pixels du monde de la colonne : 640x360 / 2) ---------------------------------

func _dessiner_fond(toile: Node2D) -> void:
	var vue := _fond.vue_monde()
	var mer := float(ArtIle.HAUTEUR_CIEL)
	if vue.position.y < mer:
		ArtIle.dessiner_ciel(toile, Rect2(vue.position, Vector2(vue.size.x, minf(mer - vue.position.y, vue.size.y))), 0, 0)
	if vue.end.y > mer - 3.0 and is_instance_valid(_plongee):
		# Sous la surface : le décor de la plongée elle-même, recalé sur la colonne.
		var origine := Vector2(ArtAbysse.DECALAGE_COLONNE)
		toile.draw_set_transform(origine)
		_plongee.dessiner_monde(toile, Rect2(vue.position - origine, vue.size), false, false)
		toile.draw_set_transform(Vector2.ZERO)
	for calque in 2:
		_dessiner_calque(toile, calque)


func _dessiner_avant(toile: Node2D) -> void:
	var cloche := VueMonde.vers_monde(_cloche(_profondeur_visuelle()))
	var dans_plongee := cloche - Vector2(ArtAbysse.DECALAGE_COLONNE)
	var texture := ArtIle.cloche(0.5, ArtAbysse.contour_cloche(dans_plongee.y))
	var haut_cloche := cloche.y - ceilf(texture.get_height() / 2.0)
	var attache := VueMonde.vers_monde(Ile.ATTACHE_CABLE)
	# Câble : vertical sous le treuil, puis droit vers la cloche. Quand la cloche est à la surface,
	# il descend jusqu'à la surface puis rejoint la cloche, exactement comme dans la plongée.
	var mer := float(ArtIle.HAUTEUR_CIEL)
	var coude := Vector2(attache.x, mer if cloche.y >= mer - SEUIL_SURFACE_MONDE else haut_cloche)
	toile.draw_rect(Rect2(attache.x, attache.y, 1, coude.y - attache.y + 1), Palette.couleur(COULEUR_CABLE))
	if coude != Vector2(cloche.x, haut_cloche):
		Pixel.ligne(toile, coude, Vector2(cloche.x, haut_cloche), Palette.couleur(COULEUR_CABLE))
	Pixel.sprite_ombre(toile, texture, cloche, Palette.plus_sombre(ArtAbysse.couleur_fond(dans_plongee)))
	_dessiner_calque(toile, 2)
	if _saut:
		var niveau := roundi(sin(PI * _avance_saut) * NIVEAU_SAUT_MAX)
		if niveau > 0:
			toile.draw_texture_rect(Pixel.trame(niveau, Palette.couleur(COULEUR_SAUT)), _avant.vue_monde(), true)


## Un calque de nuages : position à l'écran = y - haut × facteur, ramenée au pixel du monde.
func _dessiner_calque(toile: Node2D, calque: int) -> void:
	var reglage: Dictionary = CALQUES[calque]
	var taille: Vector2i = reglage["taille"]
	var facteur := float(reglage["facteur"])
	var haut := _fond.camera.y
	var texture := ArtIle.nuage(taille.x, taille.y)
	for centre: Vector2 in _nuages[calque]:
		var ecran_y := centre.y - haut * facteur
		if ecran_y < -taille.y * 2.0 or ecran_y > ECRAN.y + taille.y * 2.0:
			continue
		var monde := VueMonde.vers_monde(Vector2(centre.x, ecran_y + haut))
		Pixel.sprite_ombre(toile, texture, monde, Palette.plus_sombre(ArtIle.couleur_ciel_monde(monde.y)))


## Les nuages sont placés pour être hors écran au début et à la fin :
## ils n'apparaissent que pendant le trajet, quel que soit le sens.
func _placer_nuages() -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = GRAINE_NUAGES
	var haut_fin := HAUT_CAMERA_PLONGEE + HAUTEUR_MER
	for reglage: Dictionary in CALQUES:
		var facteur := float(reglage["facteur"])
		var marge := float((reglage["taille"] as Vector2i).y) * 4.0
		var y_min := ECRAN.y + marge
		var y_max := haut_fin * facteur - marge
		var liste: Array[Vector2] = []
		for i in int(reglage["nombre"]):
			var y := lerpf(y_min, y_max, (i + hasard.randf_range(0.2, 0.8)) / float(reglage["nombre"]))
			liste.append(Vector2(hasard.randf_range(40.0, ECRAN.x - 40.0), y))
		_nuages.append(liste)
