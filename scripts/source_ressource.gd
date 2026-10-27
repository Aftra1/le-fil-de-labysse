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

const ECART_POINTS := 4.0
const VITESSE_PALES := 1.6       # tours d'éolienne (radians par seconde)
const LONGUEUR_PALE := 13.0
const HAUTEUR_MAT := 50
const TAILLE_NUAGE := Vector2i(32, 16)

const FILON: PackedStringArray = [
	"....d....",
	"...djd...",
	"...djd...",
	"..djOd...",
	"..djOd.d.",
	"d.djOddjd",
	"djdjOdjOd",
	"djdOOdOOd",
	"dOdOOdOdd",
	".ddOOddd.",
	".ddddddd.",
]
const COULEURS_FILON := { "d": "or_fonce", "O": "or", "j": "or_clair" }
const COULEURS_FILON_VIDE := { "d": "lavande_fonce", "O": "lavande", "j": "lavande" }

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
		Pixel.sprite(self, Pixel.anneau(int(rayon_clic), Palette.couleur("blanc")), Vector2.ZERO)
	if progres > 0.0:
		Pixel.sprite(self, Pixel.jauge(int(rayon_clic), progres, Palette.couleur("blanc")), Vector2.ZERO)


func _dessiner_eolienne() -> void:
	Pixel.rect(self, Rect2(0, 0, 1, HAUTEUR_MAT), Palette.couleur("ardoise"))
	Pixel.rect(self, Rect2(1, 2, 1, HAUTEUR_MAT - 2), Palette.couleur("lavande_fonce"))
	for i in 3:
		var direction := Vector2.from_angle(_angle + i * TAU / 3.0)
		Pixel.ligne(self, Vector2.ZERO, direction * LONGUEUR_PALE, Palette.couleur("blanc"))
	Pixel.rect(self, Rect2(-1, -1, 3, 3), Palette.couleur("or"))
	_dessiner_points(Vector2(0.0, -LONGUEUR_PALE - 6.0), Palette.couleur("blanc"))


func _dessiner_filon() -> void:
	Pixel.sprite(self, Pixel.motif(FILON, COULEURS_FILON if est_disponible() else COULEURS_FILON_VIDE), Vector2.ZERO)
	_dessiner_points(Vector2(0.0, -10.0), Palette.couleur("or"))


func _dessiner_nuage() -> void:
	Pixel.sprite(self, Pixel.nuage(TAILLE_NUAGE.x, TAILLE_NUAGE.y, Palette.couleur("blanc"), Palette.couleur("nacre")), Vector2.ZERO)
	_dessiner_points(Vector2(0.0, TAILLE_NUAGE.y / 2.0 + 3.0), Palette.couleur("blanc"))


## Un point de 2x2 px par unité de plafond : plein si disponible, lavande sinon.
func _dessiner_points(centre: Vector2, teinte: Color) -> void:
	for i in plafond:
		var point := centre + Vector2((i - (plafond - 1) / 2.0) * ECART_POINTS, 0.0)
		Pixel.rect(self, Rect2(point.floor() - Vector2.ONE, Vector2(2, 2)), teinte if i < stock else Palette.couleur("lavande"))
