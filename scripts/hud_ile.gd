class_name InterfaceIle
extends CanvasLayer
## Interface de l'île (640x360) : bouton d'inventaire, barre des ressources, annonces et aide.
## Cadres épais or et crème (ArtIle.cadre), texte brun foncé en DotGothic16.

const DUREE_ANNONCE := 4.0
const MARGE := 6.0
const HAUT_ANNONCE := 96.0
const HAUT_AIDE := 46.0   # sous le bouton : le bas de l'écran reste libre pour la cloche

var bouton_inventaire := Button.new()
var bouton_carnet := Button.new()

var _quantites: Dictionary = {}   # id -> Label
var _annonce_panneau: PanelContainer
var _annonce: Label
var _aide_panneau: PanelContainer
var _aide: Label
var _annonce_restante := 0.0


func _ready() -> void:
	bouton_inventaire.text = "Inventaire (I)"
	ArtIle.styler_bouton(bouton_inventaire)
	bouton_carnet.text = "Carnet (K)"
	ArtIle.styler_bouton(bouton_carnet)
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 4)
	boutons.position = Vector2(MARGE, MARGE)
	boutons.add_child(bouton_inventaire)
	boutons.add_child(bouton_carnet)
	add_child(boutons)

	var barre := _panneau()
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	for id: String in Game.ids("ressource"):
		var icone := TextureRect.new()
		icone.texture = ArtIle.icone(id, 1.0)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ligne.add_child(icone)
		var quantite := _etiquette()
		_quantites[id] = quantite
		ligne.add_child(quantite)
	barre.add_child(ligne)
	ArtIle.ancrer(barre, 1.0, 0.0, MARGE)

	_annonce_panneau = _panneau()
	_annonce = _etiquette()
	_annonce_panneau.add_child(_annonce)
	ArtIle.ancrer(_annonce_panneau, 0.5, 0.0, 0.0)
	_annonce_panneau.offset_top = HAUT_ANNONCE
	_annonce_panneau.offset_bottom = HAUT_ANNONCE
	_annonce_panneau.visible = false

	_aide_panneau = _panneau()
	_aide = _etiquette()
	_aide_panneau.add_child(_aide)
	ArtIle.ancrer(_aide_panneau, 0.0, 0.0, MARGE)
	_aide_panneau.offset_top = HAUT_AIDE
	_aide_panneau.offset_bottom = HAUT_AIDE
	rafraichir_inventaire()


func _process(delta: float) -> void:
	if _annonce_restante > 0.0:
		_annonce_restante -= delta
		_annonce_panneau.visible = _annonce_restante > 0.0


func rafraichir_inventaire() -> void:
	for id: String in _quantites:
		(_quantites[id] as Label).text = str(Game.inventaire.quantite(id))


func annoncer(texte: String, duree: float = DUREE_ANNONCE) -> void:
	_annonce.text = texte
	_annonce_panneau.visible = true
	_annonce_restante = duree


func texte_annonce() -> String:
	return _annonce.text if _annonce_panneau.visible else ""


func definir_aide(texte: String) -> void:
	_aide.text = texte
	_aide_panneau.visible = texte != ""


## Panneau d'information : il ne capte pas la souris (on peut cliquer le monde dessous).
func _panneau() -> PanelContainer:
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", ArtIle.cadre(1.0))
	panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panneau)
	return panneau


func _etiquette() -> Label:
	var etiquette := Label.new()
	Pixel.texte(etiquette, ArtIle.CONTOUR, "")
	return etiquette
