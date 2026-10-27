class_name Gisement
extends Node2D
## Un gisement de minerai : un petit sprite de cristaux, un stock limité et une jauge de minage.

const RAYON := 7.0
const RAYON_ANNEAU := 12
const ECART_POINTS := 3.0

const CRISTAL: PackedStringArray = [
	".....k.....",
	"....kCk....",
	"....kCk....",
	".k..kCck...",
	"kCk.kCck.k.",
	"kCckkCckkCk",
	"kCckCcckCck",
	".kckCcckcck",
	".kcckcckck.",
	"..kkkkkkk..",
]
const COULEURS_CRISTAL := { "k": "lagon_profond", "c": "cyan", "C": "cyan_clair" }
const CORAIL: PackedStringArray = [
	".v...v...v.",
	".L...L..vL.",
	"vL..vL..L..",
	".Lv.L..vL..",
	"..LvL.vL...",
	"...LLvL....",
	"....LLv....",
	"....vL.....",
	"...fvvf....",
	"..ffffff...",
]
const COULEURS_CORAIL := { "v": "violet", "L": "violet_lumineux", "f": "violet_fonce" }
const COULEURS_GRISEES := {
	"k": "ardoise", "c": "lavande_fonce", "C": "lavande", "v": "lavande_fonce", "L": "lavande", "f": "ardoise",
}

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


func _draw() -> void:
	var dessin: PackedStringArray = CORAIL if minerai == "corail" else CRISTAL
	var couleurs: Dictionary = COULEURS_CORAIL if minerai == "corail" else COULEURS_CRISTAL
	Pixel.sprite(self, Pixel.motif(dessin, COULEURS_GRISEES if grise else couleurs), Vector2.ZERO)
	# Un point par unité restante
	var teinte := Palette.couleur("lavande") if grise else couleur
	for i in stock:
		Pixel.rect(self, Rect2(Vector2((i - (stock - 1) / 2.0) * ECART_POINTS, RAYON + 2.0).floor(), Vector2.ONE), teinte)
	if en_evidence and not grise:
		Pixel.sprite(self, Pixel.anneau(RAYON_ANNEAU, Palette.couleur("blanc")), Vector2.ZERO)
	if progres > 0.0:
		Pixel.sprite(self, Pixel.jauge(RAYON_ANNEAU, progres, Palette.couleur("blanc")), Vector2.ZERO)
