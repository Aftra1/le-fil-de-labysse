class_name InterfaceIle
extends CanvasLayer
## Interface de l'île : bouton d'inventaire, rangée des ressources, annonces et aide.

const TAILLE_POLICE := 12
const TAILLE_POLICE_ANNONCE := 16
const DUREE_ANNONCE := 4.0
const LARGEUR_ECRAN := 640.0
const LARGEUR_CASE := 40.0
const TAILLE_PASTILLE := 8.0

const COULEUR_TEXTE := Color("ffffff")
const COULEUR_CONTOUR := Color("2a3550")

var bouton_inventaire := Button.new()

var _quantites: Dictionary = {}   # id -> Label
var _annonce := Label.new()
var _aide := Label.new()
var _annonce_restante := 0.0


func _ready() -> void:
	bouton_inventaire.text = "Inventaire (I)"
	bouton_inventaire.position = Vector2(8.0, 6.0)
	bouton_inventaire.focus_mode = Control.FOCUS_NONE
	bouton_inventaire.add_theme_font_size_override("font_size", TAILLE_POLICE)
	add_child(bouton_inventaire)

	var ids := Game.ressources.keys()
	var x := LARGEUR_ECRAN - 8.0 - LARGEUR_CASE * ids.size()
	for id: String in ids:
		var pastille := ColorRect.new()
		pastille.color = Game.couleur_ressource(id)
		pastille.position = Vector2(x, 12.0)
		pastille.size = Vector2.ONE * TAILLE_PASTILLE
		pastille.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pastille)
		var quantite := Label.new()
		_placer(quantite, Vector2(x + TAILLE_PASTILLE + 3.0, 6.0))
		_quantites[id] = quantite
		x += LARGEUR_CASE

	_placer(_annonce, Vector2(0.0, 36.0), TAILLE_POLICE_ANNONCE)
	_annonce.size.x = LARGEUR_ECRAN
	_annonce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_annonce.visible = false

	_placer(_aide, Vector2(8.0, 338.0))
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


func _placer(etiquette: Label, position_etiquette: Vector2, taille_police: int = TAILLE_POLICE) -> void:
	etiquette.position = position_etiquette
	etiquette.add_theme_font_size_override("font_size", taille_police)
	etiquette.add_theme_color_override("font_color", COULEUR_TEXTE)
	etiquette.add_theme_color_override("font_outline_color", COULEUR_CONTOUR)
	etiquette.add_theme_constant_override("outline_size", 3)
	add_child(etiquette)
