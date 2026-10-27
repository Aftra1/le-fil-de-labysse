class_name InterfaceIle
extends CanvasLayer
## Interface de l'île : bouton d'inventaire, rangée des ressources, annonces et aide.

const DUREE_ANNONCE := 4.0
const LARGEUR_ECRAN := 640.0
const LARGEUR_CASE := 40.0
const TAILLE_PASTILLE := 8.0

# Couleurs : noms de la palette
const COULEUR_TEXTE := "blanc"
const COULEUR_CONTOUR := "nuit"
const COULEUR_BOUTON := "nuit"
const COULEUR_BOUTON_SURVOL := "bleu_nuit"
const COULEUR_BOUTON_APPUI := "abysse"
const COULEUR_BOUTON_BORD := "or"
const COULEUR_PASTILLE_BORD := "nuit"

var bouton_inventaire := Button.new()

var _quantites: Dictionary = {}   # id -> Label
var _annonce := Label.new()
var _aide := Label.new()
var _annonce_restante := 0.0


func _ready() -> void:
	bouton_inventaire.text = "Inventaire (I)"
	bouton_inventaire.position = Vector2(8.0, 6.0)
	bouton_inventaire.focus_mode = Control.FOCUS_NONE
	bouton_inventaire.add_theme_font_size_override("font_size", Pixel.TAILLE_TEXTE)
	bouton_inventaire.add_theme_color_override("font_color", Palette.couleur(COULEUR_TEXTE))
	bouton_inventaire.add_theme_color_override("font_hover_color", Palette.couleur(COULEUR_TEXTE))
	bouton_inventaire.add_theme_color_override("font_pressed_color", Palette.couleur(COULEUR_TEXTE))
	bouton_inventaire.add_theme_stylebox_override("normal", _style_bouton(COULEUR_BOUTON))
	bouton_inventaire.add_theme_stylebox_override("hover", _style_bouton(COULEUR_BOUTON_SURVOL))
	bouton_inventaire.add_theme_stylebox_override("pressed", _style_bouton(COULEUR_BOUTON_APPUI))
	add_child(bouton_inventaire)

	var ids := Game.ressources.keys()
	var x := LARGEUR_ECRAN - 8.0 - LARGEUR_CASE * ids.size()
	for id: String in ids:
		var bord := ColorRect.new()
		bord.color = Palette.couleur(COULEUR_PASTILLE_BORD)
		bord.position = Vector2(x - 1.0, 14.0)
		bord.size = Vector2.ONE * (TAILLE_PASTILLE + 2.0)
		bord.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bord)
		var pastille := ColorRect.new()
		pastille.color = Game.couleur_ressource(id)
		pastille.position = Vector2(x, 15.0)
		pastille.size = Vector2.ONE * TAILLE_PASTILLE
		pastille.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pastille)
		var quantite := Label.new()
		_placer(quantite, Vector2(x + TAILLE_PASTILLE + 3.0, 8.0))
		_quantites[id] = quantite
		x += LARGEUR_CASE

	_placer(_annonce, Vector2(0.0, 40.0))
	_annonce.size.x = LARGEUR_ECRAN
	_annonce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_annonce.visible = false

	_placer(_aide, Vector2(8.0, 334.0))
	rafraichir_inventaire()


func _process(delta: float) -> void:
	if _annonce_restante > 0.0:
		_annonce_restante -= delta
		_annonce.visible = _annonce_restante > 0.0


func rafraichir_inventaire() -> void:
	for id: String in _quantites:
		(_quantites[id] as Label).text = str(Game.inventaire.quantite(id))


func annoncer(texte: String, duree: float = DUREE_ANNONCE) -> void:
	_annonce.text = texte
	_annonce.visible = true
	_annonce_restante = duree


func texte_annonce() -> String:
	return _annonce.text if _annonce.visible else ""


func definir_aide(texte: String) -> void:
	_aide.text = texte


func _style_bouton(fond: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.couleur(fond)
	style.border_color = Palette.couleur(COULEUR_BOUTON_BORD)
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.anti_aliasing = false
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _placer(etiquette: Label, position_etiquette: Vector2) -> void:
	etiquette.position = position_etiquette
	Pixel.texte(etiquette, COULEUR_TEXTE, COULEUR_CONTOUR)
	add_child(etiquette)
