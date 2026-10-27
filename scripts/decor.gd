class_name Decor
extends RefCounted
## Dégradés du décor en paliers de la palette, partagés par l'île, la transition et la plongée
## pour que les scènes s'enchaînent sans saut de couleur.
## Repère « monde » du ciel : y = 0 en haut de l'écran de l'île, y = HAUTEUR_CIEL à la surface de l'océan.

const HAUTEUR_CIEL := 1800.0

## Paliers du ciel : [y de début, couleur]. Le ciel de la plongée (au ras de l'eau) est le dernier.
const PALIERS_CIEL := [[0.0, "ciel_1"], [130.0, "ciel_2"], [420.0, "ciel_3"], [1300.0, "nacre"]]
const CIEL_SURFACE := "nacre"


static func couleur_ciel(y_monde: float) -> Color:
	var nom: String = PALIERS_CIEL[0][1]
	for palier: Array in PALIERS_CIEL:
		if y_monde >= float(palier[0]):
			nom = palier[1]
	return Palette.couleur(nom)


## Couleur de l'eau à une profondeur (px sous la surface), d'après les « paliers » de chaque zone.
static func couleur_eau(zones: Array, profondeur_px: float, pixels_par_metre: float) -> Color:
	var profondeur_m := maxf(profondeur_px, 0.0) / pixels_par_metre
	var zone: Dictionary = zones[zones.size() - 1]
	for candidate: Dictionary in zones:
		if profondeur_m < float(candidate["fin_m"]):
			zone = candidate
			break
	var paliers: Array = zone["paliers"]
	var debut := float(zone["debut_m"])
	var t := clampf((profondeur_m - debut) / (float(zone["fin_m"]) - debut), 0.0, 0.999)
	return Palette.couleur(str(paliers[int(t * paliers.size())]))
