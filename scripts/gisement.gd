class_name Gisement
extends Node2D
## Un gisement de minerai : un petit sprite de cristaux, un stock limité et une jauge de minage.
## Il ne se dessine pas lui-même : la plongée appelle dessiner_monde() dans le monde 320x180.

const RAYON := 7.0
const RAYON_ANNEAU := 12

const CRISTAL := ArtAbysse.CRISTAL
const CORAIL := ArtAbysse.CORAIL

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


func configurer(id_minerai: String, teinte: Color, duree: float, stock_initial: int) -> void:
	minerai = id_minerai
	couleur = teinte
	duree_minage = duree
	stock = stock_initial


## Retire une unité ; le gisement disparaît quand il est épuisé.
func retirer_unite() -> void:
	stock -= 1
	if stock <= 0:
		queue_free()
	else:
		queue_redraw()


## Dessin dans le monde 320x180 (appelé par la plongée) : sprite avec contour bleu nuit et ombre
## d'un ton plus sombre que l'eau, stock en points, anneau et jauge en lueur cyan.
func dessiner_monde(toile: CanvasItem) -> void:
	var p := VueMonde.vers_monde(position)
	Pixel.sprite_ombre(toile, ArtAbysse.gisement(minerai, grise), p, Palette.plus_sombre(ArtAbysse.couleur_eau(p.y)))
	var plein := Palette.couleur("corail.4" if minerai == "corail" else "cyan.3")
	for i in stock:
		var point := (p + Vector2((i - (stock - 1) / 2.0) * 2.0, 6.0)).floor()
		toile.draw_rect(Rect2(point, Vector2.ONE), Palette.couleur("metal.3") if grise else plein)
	var rayon: int = RAYON_ANNEAU / VueMonde.ECHELLE
	if en_evidence and not grise:
		Pixel.sprite(toile, Pixel.anneau(rayon, Palette.couleur("cyan.3")), p)
	if progres > 0.0:
		Pixel.sprite(toile, Pixel.jauge(rayon, progres, Palette.couleur("cyan.3")), p)
