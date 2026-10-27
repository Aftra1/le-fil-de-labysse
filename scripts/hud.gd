extends CanvasLayer
## Interface de plongée : barre d'oxygène, profondeur en mètres, message de remontée.

const POSITION_BARRE := Vector2(8.0, 8.0)
const TAILLE_BARRE := Vector2(120.0, 8.0)
const TAILLE_POLICE := 12
const SEUIL_OXYGENE_BAS := 0.25

const COULEUR_FOND := Color(0.0, 0.0, 0.0, 0.5)
const COULEUR_OXYGENE := Color("3fe0e8")
const COULEUR_OXYGENE_BAS := Color("b06cff")
const COULEUR_TEXTE := Color("ffffff")

var _remplissage := ColorRect.new()
var _profondeur := Label.new()
var _message := Label.new()


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = COULEUR_FOND
	fond.position = POSITION_BARRE - Vector2.ONE
	fond.size = TAILLE_BARRE + Vector2.ONE * 2.0
	add_child(fond)

	_remplissage.position = POSITION_BARRE
	_remplissage.size = TAILLE_BARRE
	add_child(_remplissage)

	_profondeur.position = POSITION_BARRE + Vector2(0.0, 14.0)
	_preparer_etiquette(_profondeur)
	add_child(_profondeur)

	_message.text = "Plus d'air… la cloche remonte"
	_message.position = Vector2(8.0, 330.0)
	_message.visible = false
	_preparer_etiquette(_message)
	add_child(_message)


func mettre_a_jour(ratio_oxygene: float, profondeur_m: float, remontee: bool) -> void:
	_remplissage.size.x = TAILLE_BARRE.x * clampf(ratio_oxygene, 0.0, 1.0)
	_remplissage.color = COULEUR_OXYGENE_BAS if ratio_oxygene < SEUIL_OXYGENE_BAS else COULEUR_OXYGENE
	_profondeur.text = "Profondeur : %d m" % int(profondeur_m)
	_message.visible = remontee


func _preparer_etiquette(etiquette: Label) -> void:
	etiquette.add_theme_font_size_override("font_size", TAILLE_POLICE)
	etiquette.add_theme_color_override("font_color", COULEUR_TEXTE)
	etiquette.add_theme_color_override("font_outline_color", Color.BLACK)
	etiquette.add_theme_constant_override("outline_size", 3)
