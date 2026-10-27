class_name Gisement
extends Node2D
## Un gisement de minerai : un cercle coloré, un stock limité et une jauge de minage.

const RAYON := 7.0
const RAYON_ANNEAU := 12.0
const EPAISSEUR_ANNEAU := 1.0
const EPAISSEUR_JAUGE := 3.0
const SEGMENTS_ARC := 32
const COULEUR_GRISE := Color("5a6270")
const COULEUR_ANNEAU := Color(1.0, 1.0, 1.0, 0.5)
const COULEUR_JAUGE := Color("ffffff")

var minerai := ""
var couleur := Color.WHITE
var duree_minage := 1.0
var stock := 0

## Avancement du minage de l'unité en cours (0 à 1).
var progres := 0.0:
	set(valeur):
		if valeur != progres:
			progres = valeur
			queue_redraw()

## Vrai quand la cloche est à portée.
var en_evidence := false:
	set(valeur):
		if valeur != en_evidence:
			en_evidence = valeur
			queue_redraw()

## Vrai quand le sac est plein (le gisement est inutilisable).
var grise := false:
	set(valeur):
		if valeur != grise:
			grise = valeur
			queue_redraw()


func configurer(id_minerai: String, donnees: Dictionary, stock_initial: int) -> void:
	minerai = id_minerai
	couleur = Color.html(str(donnees["couleur"]))
	duree_minage = float(donnees["duree_minage"])
	stock = stock_initial


## Retire une unité ; le gisement disparaît quand il est épuisé.
func retirer_unite() -> void:
	stock -= 1
	if stock <= 0:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var teinte := COULEUR_GRISE if grise else couleur
	draw_circle(Vector2.ZERO, RAYON, teinte)
	draw_arc(Vector2.ZERO, RAYON, 0.0, TAU, SEGMENTS_ARC, teinte.darkened(0.4), 1.0)
	# Un petit point par unité restante
	for i in stock:
		draw_circle(Vector2((i - (stock - 1) / 2.0) * 4.0, RAYON + 4.0), 1.0, teinte)
	if en_evidence and not grise:
		draw_arc(Vector2.ZERO, RAYON_ANNEAU, 0.0, TAU, SEGMENTS_ARC, COULEUR_ANNEAU, EPAISSEUR_ANNEAU)
	if progres > 0.0:
		draw_arc(Vector2.ZERO, RAYON_ANNEAU, -PI / 2.0, -PI / 2.0 + TAU * progres, SEGMENTS_ARC, COULEUR_JAUGE, EPAISSEUR_JAUGE)
