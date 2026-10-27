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

const SEGMENTS_ARC := 32
const RAYON_POINT := 1.5
const ECART_POINTS := 5.0
const VITESSE_PALES := 1.6       # tours d'éolienne (radians par seconde)
const LONGUEUR_PALE := 16.0
const HAUTEUR_MAT := 50.0

const COULEUR_SURVOL := Color(1.0, 1.0, 1.0, 0.7)
const COULEUR_JAUGE := Color("ffffff")
const COULEUR_VIDE := Color(1.0, 1.0, 1.0, 0.35)
const COULEUR_MAT := Color("6d6a80")
const COULEUR_PALE := Color("f4efe6")
const COULEUR_MOYEU := Color("e8b923")
const COULEUR_FILON := Color("ffd34d")
const COULEUR_FILON_BORD := Color("b8860b")
const COULEUR_FILON_VIDE := Color("b9b2a0")
const COULEUR_NUAGE := Color("ffffff")

var id_ressource := ""
var mode := Mode.CLIC
var forme := Forme.NUAGE
var stock := 0
var plafond := 1
var recharge_s := 0.0          # 0 : pas de recharge
var duree_maintien := 1.0
var rayon_clic := 20.0
var derive := 0.0              # vitesse horizontale (nuages), en px/s

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


func _process(delta: float) -> void:
	recharger(delta)
	position.x += derive * delta
	if forme == Forme.EOLIENNE:
		_angle = fmod(_angle + VITESSE_PALES * delta, TAU)
		queue_redraw()


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


func _draw() -> void:
	match forme:
		Forme.EOLIENNE:
			_dessiner_eolienne()
		Forme.FILON:
			_dessiner_filon()
		Forme.NUAGE:
			_dessiner_nuage()
	if en_survol and est_disponible():
		draw_arc(Vector2.ZERO, rayon_clic, 0.0, TAU, SEGMENTS_ARC, COULEUR_SURVOL, 1.0)
	if progres > 0.0:
		draw_arc(Vector2.ZERO, rayon_clic, -PI / 2.0, -PI / 2.0 + TAU * progres, SEGMENTS_ARC, COULEUR_JAUGE, 3.0)


func _dessiner_eolienne() -> void:
	draw_line(Vector2.ZERO, Vector2(0.0, HAUTEUR_MAT), COULEUR_MAT, 2.0)
	for i in 3:
		var direction := Vector2.from_angle(_angle + i * TAU / 3.0)
		draw_line(Vector2.ZERO, direction * LONGUEUR_PALE, COULEUR_PALE, 3.0)
	draw_circle(Vector2.ZERO, 3.0, COULEUR_MOYEU)
	_dessiner_points(Vector2(0.0, -LONGUEUR_PALE - 8.0), COULEUR_PALE)


func _dessiner_filon() -> void:
	var teinte := COULEUR_FILON if est_disponible() else COULEUR_FILON_VIDE
	var grand := PackedVector2Array([Vector2(0, -9), Vector2(5, 0), Vector2(0, 7), Vector2(-5, 0)])
	var petit := PackedVector2Array([Vector2(-7, -3), Vector2(-4, 2), Vector2(-7, 7), Vector2(-10, 2)])
	draw_colored_polygon(petit, teinte.darkened(0.15))
	draw_colored_polygon(grand, teinte)
	grand.append(grand[0])
	draw_polyline(grand, COULEUR_FILON_BORD, 1.0)
	_dessiner_points(Vector2(0.0, -15.0), COULEUR_FILON)


func _dessiner_nuage() -> void:
	draw_circle(Vector2(-12.0, 2.0), 9.0, COULEUR_NUAGE)
	draw_circle(Vector2(0.0, -3.0), 12.0, COULEUR_NUAGE)
	draw_circle(Vector2(12.0, 2.0), 8.0, COULEUR_NUAGE)
	draw_rect(Rect2(-12.0, 2.0, 24.0, 9.0), COULEUR_NUAGE)
	_dessiner_points(Vector2(0.0, 16.0), COULEUR_NUAGE)


## Un point par unité de plafond : plein si disponible, transparent sinon.
func _dessiner_points(centre: Vector2, teinte: Color) -> void:
	for i in plafond:
		var point := centre + Vector2((i - (plafond - 1) / 2.0) * ECART_POINTS, 0.0)
		draw_circle(point, RAYON_POINT, teinte if i < stock else COULEUR_VIDE)
