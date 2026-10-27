class_name MenuCadre
extends CanvasLayer
## Base des menus plein écran (écran titre, pause) : un panneau en cadre or et crème, centré ou
## en haut, avec une colonne de textes et de boutons. Les menus restent actifs quand le jeu est en pause.

const LARGEUR_BOUTON := 168.0
const ECART := 4
const COULEUR_TEXTE := "contour_haut"
const COULEUR_MESSAGE := "corail.2"

## Position verticale du panneau (0 : en haut, 0.5 : au centre) et marge au bord.
var ancre_y := 0.5
var marge_y := 0.0

var _colonne: VBoxContainer
var _panneau: PanelContainer


func _ready() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Capteur plein écran : rien ne passe au jeu sous le menu.
	var capteur := Control.new()
	capteur.size = Vector2(640.0, 360.0)
	capteur.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(capteur)
	_panneau = PanelContainer.new()
	_panneau.add_theme_stylebox_override("panel", ArtIle.cadre(1.0))
	_colonne = VBoxContainer.new()
	_colonne.add_theme_constant_override("separation", ECART)
	_colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	_panneau.add_child(_colonne)
	add_child(_panneau)
	_construire()
	_recentrer()


## À compléter par chaque menu : remplit _colonne.
func _construire() -> void:
	pass


func est_ouvert() -> bool:
	return visible


func fermer() -> void:
	visible = false


func _bouton(texte: String, action: Callable) -> Button:
	var bouton := Button.new()
	bouton.text = texte
	ArtIle.styler_bouton(bouton)
	bouton.custom_minimum_size.x = LARGEUR_BOUTON
	bouton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bouton.pressed.connect(action)
	return bouton


func _etiquette(texte: String, couleur: String = COULEUR_TEXTE) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Pixel.texte(etiquette, couleur, "")
	return etiquette


## Le panneau garde sa taille minimale quand son contenu change (textes, boutons cachés).
func _recentrer() -> void:
	_panneau.reset_size()
	ArtIle.ancrer(_panneau, 0.5, ancre_y, marge_y)
