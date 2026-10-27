class_name DecorCiel
extends RefCounted
## Le ciel entre l'île et l'océan, partagé par l'île et la transition
## pour que les deux s'enchaînent sans saut de couleur.
## Repère « monde » : y = 0 en haut de l'écran de l'île, y = HAUTEUR_CIEL à la surface de l'océan.

const HAUTEUR_CIEL := 1800.0
const CIEL_HAUT := Color("8ccff2")
const CIEL_BAS := Color("cfe9f7")   # même couleur que le ciel de la plongée


static func couleur(y_monde: float) -> Color:
	return CIEL_HAUT.lerp(CIEL_BAS, clampf(y_monde / HAUTEUR_CIEL, 0.0, 1.0))
