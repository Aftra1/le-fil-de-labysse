class_name SourceRessource
extends Node2D
## Une source de ressource sur l'île : éolienne, filon de cristal, nuage, bassin de lumière (îlot)
## ou machine construite sur un emplacement (moulin à vent, filet à nuages, entrepôt, fourneau, sonde)
## ou sur un filon (foreuse solaire).
## Production sous condition : « condition » (si elle est donnée) est appelée avant chaque unité et peut
## refuser (fourneau sans ingrédients) ; la sonde ne produit que pendant les plongées (recharger_plongee).
## Trois façons de récolter :
## - CLIC : un clic = une prise (nuages : « rendement » ouates par prise) ;
## - MAINTIEN : maintenir le clic remplit une jauge, une unité par cycle (filons, bassin) ;
## - RESERVE : la source accumule seule, un clic vide toute la réserve (éolienne, machines).
## Le stock se recharge avec le temps jusqu'au plafond (recharge_s secondes par unité).

enum Mode { CLIC, MAINTIEN, RESERVE }
enum Forme { EOLIENNE, FILON, NUAGE, BASSIN, MOULIN, FILET, FOREUSE, ENTREPOT, FOURNEAU, SONDE }

const VITESSE_PALES := 1.6       # tours d'éolienne (radians par seconde)
const VITESSE_AILES := 1.1       # ailes du moulin, arrêtées quand sa réserve est pleine
## Machines : la position est le centre de la zone cliquable, le sol est en dessous (pixels du monde).
const HAUTEUR_MACHINE := 8
const IMAGES_PAR_SECONDE := 60   # cadence de la physique : les nuages avancent par pas réguliers

# Dessin dans le monde 320x180 (voir VueMonde)
const K := 0.5
const FILON := ArtIle.FILON
const TAILLE_NUAGE := Vector2i(16, 8)
const HAUTEUR_MAT := 25          # pixels du monde, du moyeu au sol
## Réserve affichée en points jusqu'à 10 ; au-delà, une jauge de LARGEUR_JAUGE pixels du monde.
const POINTS_MAX := 10
const LARGEUR_JAUGE := 15

var id_ressource := ""
## Nom affiché dans l'aide (machines) ; vide : le nom de la ressource.
var nom := ""
var mode := Mode.CLIC
var forme := Forme.NUAGE
var stock := 0
## Unités récoltées par prise (nuages : 2 ouates par clic).
var rendement := 1
var plafond := 1
var recharge_s := 0.0          # 0 : pas de recharge
var duree_maintien := 1.0
## Appelée avant chaque unité produite ; renvoie faux pour attendre (vide : toujours possible).
var condition := Callable()
## Sonde : secondes de plongée par unité (0 : la source n'est pas une sonde).
var recharge_plongee_s := 0.0
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
	elif forme == Forme.MOULIN and stock < plafond:
		_angle = fmod(_angle + VITESSE_AILES * delta, TAU)


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
		if condition.is_valid() and not condition.call():
			_accumulateur = recharge_s    # prêt : l'unité suivante part dès que la condition le permet
			return
		_accumulateur -= recharge_s
		stock += 1
		queue_redraw()
	if stock >= plafond:
		_accumulateur = 0.0


## Sonde : production pendant « secondes » de plongée (rien sur l'île ni jeu fermé).
func recharger_plongee(secondes: float) -> void:
	if recharge_plongee_s <= 0.0:
		return
	recharge_s = recharge_plongee_s
	recharger(secondes)
	recharge_s = 0.0


## Vrai si la machine travaille en ce moment (fourneau : recette choisie et réserve pas pleine).
func en_activite() -> bool:
	return stock < plafond and (not condition.is_valid() or _accumulateur < recharge_s)


## État enregistré dans la sauvegarde : stock et recharge en cours.
func etat() -> Dictionary:
	return {"stock": stock, "recharge": _accumulateur}


## Reprend un état sauvegardé, borné : stock 0..plafond, recharge 0..recharge_s.
func restaurer(donnees: Dictionary) -> void:
	var valeur = donnees.get("stock", stock)
	if valeur is float or valeur is int:
		stock = clampi(int(valeur), 0, plafond)
	valeur = donnees.get("recharge", 0.0)
	_accumulateur = clampf(float(valeur), 0.0, recharge_s) if (valeur is float or valeur is int) else 0.0
	if stock >= plafond:
		_accumulateur = 0.0
	queue_redraw()


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
		Forme.BASSIN:
			_dessiner_bassin(toile, p)
		Forme.MOULIN:
			_dessiner_moulin(toile, p)
		Forme.FILET:
			_dessiner_filet(toile, p)
		Forme.FOREUSE:
			_dessiner_foreuse(toile, p)
		Forme.ENTREPOT:
			_dessiner_entrepot(toile, p)
		Forme.FOURNEAU:
			_dessiner_fourneau(toile, p)
		Forme.SONDE:
			_dessiner_sonde(toile, p)
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


## Bassin de lumière : une flaque du lagon creusée dans l'herbe, qui scintille quand elle est pleine.
func _dessiner_bassin(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var y := centre.y
	toile.draw_rect(Rect2(x - 5, y - 1, 11, 4), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 4, y, 9, 2), Palette.couleur("lagon.4" if est_disponible() else "lagon.2"))
	toile.draw_rect(Rect2(x - 4, y + 1, 9, 1), Palette.couleur("lagon.3" if est_disponible() else "lagon.1"))
	if est_disponible():
		var reflet := posmod(int(ArtAbysse.temps() * 4.0), 9)
		toile.draw_rect(Rect2(x - 4 + reflet, y, 1, 1), Palette.couleur("lagon.5"))
	_dessiner_points(toile, centre + Vector2(0, -6), "lagon.5")


## Moulin à vent : tour de bois à deux étages au toit sombre, avec une porte, et quatre grandes ailes de
## toile sur une armature, qui tournent tant qu'il produit (elles s'arrêtent quand la réserve est pleine :
## il est temps de la vider).
func _dessiner_moulin(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var sol := centre.y + HAUTEUR_MACHINE
	toile.draw_rect(Rect2(x - 5, sol, 12, 1), Palette.couleur("herbe.3"))
	for rang in 12:
		var demi := 4 if rang < 6 else 3
		var y := sol - 1 - rang
		toile.draw_rect(Rect2(x - demi - 1, y, demi * 2 + 3, 1), Palette.couleur(ArtIle.CONTOUR))
		toile.draw_rect(Rect2(x - demi, y, demi * 2 + 1, 1), Palette.couleur("terre.3" if rang != 6 else "terre.2"))
		toile.draw_rect(Rect2(x + demi, y, 1, 1), Palette.couleur("terre.2"))
	toile.draw_rect(Rect2(x - 1, sol - 4, 3, 3), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x, sol - 3, 1, 2), Palette.couleur("terre.1"))
	toile.draw_rect(Rect2(x - 1, sol - 10, 2, 2), Palette.couleur("or.4"))
	for rang in 4:
		toile.draw_rect(Rect2(x - 4 + rang, sol - 13 - rang, 9 - rang * 2, 1), Palette.couleur("terre.1"))
	var moyeu := Vector2(x, sol - 13)
	for bras in 4:
		var direction := Vector2.from_angle(_angle + bras * PI / 2.0)
		var cote := direction.orthogonal()
		for d in range(1, 12):
			var point := (moyeu + direction * d).round()
			if d >= 3:
				for largeur in [1.2, 2.2]:
					toile.draw_rect(Rect2((moyeu + direction * d + cote * largeur).round(), Vector2.ONE),
						Palette.couleur("nuage.4" if largeur < 2.0 else "nuage.3"))
			toile.draw_rect(Rect2(point, Vector2.ONE), Palette.couleur("terre.1"))
	toile.draw_rect(Rect2(moyeu, Vector2.ONE), Palette.couleur("or.4"))
	_dessiner_points(toile, centre + Vector2(0, -19), "ciel.4")


## Filet à nuages : deux poteaux, un filet qui ondule au vent et les ouates prises dans ses mailles.
func _dessiner_filet(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var sol := centre.y + HAUTEUR_MACHINE
	toile.draw_rect(Rect2(x - 6, sol, 14, 1), Palette.couleur("herbe.3"))
	for cote: int in [-6, 6]:
		toile.draw_rect(Rect2(x + cote - 1, sol - 12, 3, 12), Palette.couleur(ArtIle.CONTOUR))
		toile.draw_rect(Rect2(x + cote, sol - 11, 1, 11), Palette.couleur("terre.2"))
	toile.draw_rect(Rect2(x - 5, sol - 11, 11, 1), Palette.couleur("nuage.4"))
	var t := ArtAbysse.temps()
	for rang in 7:
		var ecart := roundi(sin(t * 2.0 + rang * 0.6) * (rang / 6.0))
		for colonne in 11:
			if (colonne + rang) % 2 == 0:
				var mx := clampf(x - 5 + colonne + ecart, x - 5, x + 5)
				toile.draw_rect(Rect2(mx, sol - 10 + rang, 1, 1), Palette.couleur("nuage.3"))
	# Ouates prises : de 0 à 4 touffes selon la réserve.
	var touffes := ceili(4.0 * stock / maxf(plafond, 1.0))
	var places := [Vector2(-3, -8), Vector2(2, -6), Vector2(-1, -4), Vector2(3, -9)]
	for i in touffes:
		var coin: Vector2 = Vector2(x, sol) + places[i]
		toile.draw_rect(Rect2(coin, Vector2(2, 2)), Palette.couleur("nuage.4"))
	_dessiner_points(toile, centre + Vector2(0, -12), "nuage.4")


## Foreuse solaire : un chevalet de bois au-dessus du filon, dont la mèche tourne et descend dans le
## cristal tant que la réserve n'est pas pleine.
func _dessiner_foreuse(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var sol := centre.y + HAUTEUR_MACHINE
	Pixel.sprite_ombre(toile, ArtIle.filon(K, true), Vector2(x, sol - 3), Palette.couleur("herbe.3"))
	for rang in 12:
		var ecart := 6 - rang / 3
		toile.draw_rect(Rect2(x - ecart, sol - 1 - rang, 1, 1), Palette.couleur("terre.1"))
		toile.draw_rect(Rect2(x + ecart, sol - 1 - rang, 1, 1), Palette.couleur("terre.1"))
	toile.draw_rect(Rect2(x - 4, sol - 14, 9, 2), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 3, sol - 14, 7, 1), Palette.couleur("metal.2"))
	var actif := stock < plafond
	var t := ArtAbysse.temps()
	var descente := roundi(1.0 + sin(t * 3.0)) if actif else 0
	var bas := sol - 8 + descente
	toile.draw_rect(Rect2(x, sol - 12, 1, bas - (sol - 12)), Palette.couleur("metal.3"))
	var tour := int(t * 12.0) % 2 if actif else 0
	toile.draw_rect(Rect2(x - 1, bas, 3, 2), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 1 + tour, bas, 1, 1), Palette.couleur("metal.3"))
	toile.draw_rect(Rect2(x, bas + 1, 1, 1), Palette.couleur("or.4"))
	_dessiner_points(toile, centre + Vector2(0, -12), "or.4")


## Fourneau : un four de pierre en dôme ; quand il travaille, sa bouche rougeoie et sa cheminée fume.
func _dessiner_fourneau(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var sol := centre.y + HAUTEUR_MACHINE
	toile.draw_rect(Rect2(x - 6, sol, 13, 1), Palette.couleur("herbe.3"))
	var largeurs := [6, 6, 6, 5, 5, 4, 3, 2]
	for rang in largeurs.size():
		var demi: int = largeurs[rang]
		toile.draw_rect(Rect2(x - demi - 1, sol - 1 - rang, demi * 2 + 3, 1), Palette.couleur(ArtIle.CONTOUR))
		toile.draw_rect(Rect2(x - demi, sol - 1 - rang, demi * 2 + 1, 1), Palette.couleur("roche.3" if rang % 3 else "roche.4"))
	toile.draw_rect(Rect2(x + 3, sol - 12, 3, 5), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x + 4, sol - 12, 1, 4), Palette.couleur("roche.2"))
	var actif := en_activite() and condition.is_valid()
	var t := ArtAbysse.temps()
	var braise := "or.5" if actif and int(t * 6.0) % 3 == 0 else ("or.4" if actif else "roche.1")
	toile.draw_rect(Rect2(x - 2, sol - 4, 5, 4), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 1, sol - 3, 3, 3), Palette.couleur(braise))
	if actif:
		var pas := int(t * 3.0)
		for bouffee in 2:
			var montee := posmod(pas + bouffee * 3, 6)
			toile.draw_rect(Rect2(Vector2(x + 4 + posmod(montee, 2), sol - 13 - montee), Vector2.ONE), Palette.couleur("nuage.3"))
	_dessiner_points(toile, centre + Vector2(0, -12), "or.4")


## Sonde de plongée : une potence au bord de l'île ; sa capsule cyan monte et descend au bout du câble.
func _dessiner_sonde(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var sol := centre.y + HAUTEUR_MACHINE
	toile.draw_rect(Rect2(x - 3, sol, 7, 1), Palette.couleur("herbe.3"))
	toile.draw_rect(Rect2(x - 3, sol - 13, 3, 13), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 2, sol - 12, 1, 12), Palette.couleur("terre.2"))
	toile.draw_rect(Rect2(x - 3, sol - 14, 10, 2), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 2, sol - 14, 8, 1), Palette.couleur("metal.2"))
	var bas := sol - 7 + roundi(3.0 * sin(ArtAbysse.temps() * 1.2))
	toile.draw_rect(Rect2(x + 5, sol - 13, 1, bas - (sol - 13)), Palette.couleur("metal.3"))
	toile.draw_rect(Rect2(x + 4, bas, 3, 3), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x + 5, bas + 1, 1, 1), Palette.couleur("cyan.3"))
	_dessiner_points(toile, centre + Vector2(0, -13), "cyan.3")


## Entrepôt : une petite remise de planches au toit sombre, avec une caisse devant la porte.
func _dessiner_entrepot(toile: CanvasItem, centre: Vector2) -> void:
	var x := centre.x
	var sol := centre.y + HAUTEUR_MACHINE
	toile.draw_rect(Rect2(x - 6, sol, 13, 1), Palette.couleur("herbe.3"))
	toile.draw_rect(Rect2(x - 6, sol - 8, 13, 8), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x - 5, sol - 7, 11, 7), Palette.couleur("terre.3"))
	for rang in [sol - 5, sol - 2]:
		toile.draw_rect(Rect2(x - 5, rang, 11, 1), Palette.couleur("terre.2"))
	toile.draw_rect(Rect2(x - 1, sol - 5, 3, 5), Palette.couleur("terre.1"))
	for rang in 4:
		toile.draw_rect(Rect2(x - 7 + rang, sol - 9 - rang, 15 - rang * 2, 1), Palette.couleur("terre.1" if rang < 3 else "or.3"))
	toile.draw_rect(Rect2(x + 4, sol - 3, 4, 3), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(x + 5, sol - 2, 2, 2), Palette.couleur("or.2"))


func _dessiner_filon(toile: CanvasItem, centre: Vector2) -> void:
	Pixel.sprite_ombre(toile, ArtIle.filon(K, est_disponible()), centre, Palette.couleur("herbe.3"))
	_dessiner_points(toile, centre + Vector2(0, -6), "or.4")


func _dessiner_nuage(toile: CanvasItem, centre: Vector2) -> void:
	var ombre := Palette.plus_sombre(ArtIle.couleur_ciel_monde(centre.y))
	Pixel.sprite_ombre(toile, ArtIle.nuage(TAILLE_NUAGE.x, TAILLE_NUAGE.y), centre, ombre)
	_dessiner_points(toile, centre + Vector2(0, 7), "nuage.4")


## Un pixel du monde par unité de plafond, espacés d'un pixel : plein si disponible, sombre sinon.
## Au-delà de POINTS_MAX (réserves améliorées), une petite jauge remplie selon le stock.
func _dessiner_points(toile: CanvasItem, centre: Vector2, couleur: String) -> void:
	if plafond > POINTS_MAX:
		var gauche := (centre - Vector2(floorf(LARGEUR_JAUGE / 2.0), 0.0)).floor()
		toile.draw_rect(Rect2(gauche - Vector2.ONE, Vector2(LARGEUR_JAUGE + 2, 3)), Palette.couleur(ArtIle.CONTOUR))
		toile.draw_rect(Rect2(gauche, Vector2(LARGEUR_JAUGE, 1)), Palette.couleur("roche.2"))
		var plein := ceili(LARGEUR_JAUGE * stock / float(plafond)) if stock > 0 else 0
		toile.draw_rect(Rect2(gauche, Vector2(plein, 1)), Palette.couleur(couleur))
		return
	for i in plafond:
		var point := (centre + Vector2((i - (plafond - 1) / 2.0) * 2.0, 0.0)).floor()
		toile.draw_rect(Rect2(point, Vector2.ONE), Palette.couleur(couleur if i < stock else "roche.2"))
