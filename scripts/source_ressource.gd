class_name SourceRessource
extends Node2D
## Une source de ressource sur l'île : éolienne, filon de cristal ou nuage.
## Trois façons de récolter :
## - CLIC : un clic = une unité (nuages) ;
## - MAINTIEN : maintenir le clic remplit une jauge, une unité par cycle (filons) ;
## - RESERVE : la source accumule seule, un clic vide toute la réserve (éolienne).
## Le stock se recharge avec le temps jusqu'au plafond (recharge_s secondes par unité).

enum Mode { CLIC, MAINTIEN, RESERVE }
enum Forme { EOLIENNE, FILON, NUAGE }

const VITESSE_PALES := 1.6       # tours d'éolienne (radians par seconde)
const IMAGES_PAR_SECONDE := 60   # cadence de la physique : les nuages avancent par pas réguliers

# Dessin dans le monde 320x180 (voir VueMonde)
const K := 0.5
const FILON := ArtIle.FILON
const TAILLE_NUAGE := Vector2i(16, 8)
const HAUTEUR_MAT := 25          # pixels du monde, du moyeu au sol

var id_ressource := ""
var mode := Mode.CLIC
var forme := Forme.NUAGE
var stock := 0
var plafond := 1
var recharge_s := 0.0          # 0 : pas de recharge
var duree_maintien := 1.0
var rayon_clic := 20.0
## Vitesse horizontale (nuages), en px/s (640x360). Elle est arrondie pour que le nuage avance
## d'un pixel du monde toutes les N images de physique exactement : un pas régulier, jamais saccadé.
var derive := 0.0:
	set(valeur):
		derive = valeur
		_images_par_pas = maxi(roundi(IMAGES_PAR_SECONDE * VueMonde.ECHELLE / valeur), 1) if valeur > 0.0 else 0
		_compteur_pas = 0

var progres := 0.0:
	set(valeur):
		if valeur != progres:
			progres = valeur
			queue_redraw()

var en_survol := false:
	set(valeur):
		if valeur != en_survol:
			en_survol = valeur
			queue_redraw()

var _accumulateur := 0.0
var _angle := 0.0
var _images_par_pas := 0
var _compteur_pas := 0


func _process(delta: float) -> void:
	recharger(delta)
	if forme == Forme.EOLIENNE:
		_angle = fmod(_angle + VITESSE_PALES * delta, TAU)


func _physics_process(_delta: float) -> void:
	if _images_par_pas <= 0:
		return
	_compteur_pas += 1
	if _compteur_pas >= _images_par_pas:
		_compteur_pas = 0
		position.x += VueMonde.ECHELLE   # un pixel du monde


## Fait avancer la recharge de « secondes » (aussi utilisé pour rattraper le temps de plongée).
func recharger(secondes: float) -> void:
	if recharge_s <= 0.0:
		return
	if stock >= plafond:
		_accumulateur = 0.0
		return
	_accumulateur += secondes
	while _accumulateur >= recharge_s and stock < plafond:
		_accumulateur -= recharge_s
		stock += 1
		queue_redraw()
	if stock >= plafond:
		_accumulateur = 0.0


func est_disponible() -> bool:
	return stock > 0


func contient(point: Vector2) -> bool:
	return point.distance_to(position) <= rayon_clic


## Retire jusqu'à « nombre » unités ; renvoie la quantité réellement prise.
func prendre(nombre: int) -> int:
	var pris := mini(nombre, stock)
	stock -= pris
	queue_redraw()
	return pris


# --- Dessin dans le monde 320x180 ----------------------------------------------------

func dessiner_monde(toile: CanvasItem) -> void:
	var p := VueMonde.vers_monde(position)
	match forme:
		Forme.EOLIENNE:
			_dessiner_eolienne(toile, p)
		Forme.FILON:
			_dessiner_filon(toile, p)
		Forme.NUAGE:
			_dessiner_nuage(toile, p)
	var rayon := roundi(rayon_clic * K)
	if en_survol and est_disponible():
		Pixel.sprite(toile, Pixel.anneau(rayon, Palette.couleur("nuage.4")), p)
	if progres > 0.0:
		Pixel.sprite(toile, Pixel.jauge(rayon, progres, Palette.couleur("nuage.4")), p)


func _dessiner_eolienne(toile: CanvasItem, moyeu: Vector2) -> void:
	var sol := moyeu.y + HAUTEUR_MAT
	toile.draw_rect(Rect2(moyeu.x + 1, sol - 1, 3, 1), Palette.couleur("herbe.3"))
	toile.draw_rect(Rect2(moyeu.x - 1, moyeu.y, 3, sol - moyeu.y), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(moyeu.x, moyeu.y, 1, sol - moyeu.y - 1), Palette.couleur("terre.2"))
	Pixel.sprite(toile, ArtIle.pales(K, _angle), moyeu)
	_dessiner_points(toile, moyeu + Vector2(0, -10), "nuage.4")


func _dessiner_filon(toile: CanvasItem, centre: Vector2) -> void:
	Pixel.sprite_ombre(toile, ArtIle.filon(K, est_disponible()), centre, Palette.couleur("herbe.3"))
	_dessiner_points(toile, centre + Vector2(0, -6), "or.4")


func _dessiner_nuage(toile: CanvasItem, centre: Vector2) -> void:
	var ombre := Palette.plus_sombre(ArtIle.couleur_ciel_monde(centre.y))
	Pixel.sprite_ombre(toile, ArtIle.nuage(TAILLE_NUAGE.x, TAILLE_NUAGE.y), centre, ombre)
	_dessiner_points(toile, centre + Vector2(0, 7), "nuage.4")


## Un pixel du monde par unité de plafond, espacés d'un pixel : plein si disponible, sombre sinon.
func _dessiner_points(toile: CanvasItem, centre: Vector2, couleur: String) -> void:
	for i in plafond:
		var point := (centre + Vector2((i - (plafond - 1) / 2.0) * 2.0, 0.0)).floor()
		toile.draw_rect(Rect2(point, Vector2.ONE), Palette.couleur(couleur if i < stock else "roche.2"))
