class_name PanneauInventaire
extends CanvasLayer
## Panneau d'inventaire opaque (cadre or et crème, pas de voile) : une case par ressource.
## S'ouvre et se ferme avec I / Tab ou le bouton ; Échap ou un clic à côté le ferme.

const TAILLE_CASE := Vector2(80.0, 78.0)
const LARGEUR_NOM := 72.0
const ECART := 4

var _quantites: Dictionary = {}   # id -> Label


func _ready() -> void:
	layer = 5
	visible = false

	# Zone invisible plein écran : un clic à côté du panneau le ferme (sans rien dessiner).
	var capteur := Control.new()
	capteur.size = Vector2(640.0, 360.0)
	capteur.mouse_filter = Control.MOUSE_FILTER_STOP
	capteur.gui_input.connect(_sur_clic_a_cote)
	add_child(capteur)

	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", ArtIle.cadre(1.0))
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", ECART)
	colonne.add_child(_etiquette("Inventaire"))
	for categorie: String in ["ressource", "composant", "raffine"]:
		var cases := HBoxContainer.new()
		cases.add_theme_constant_override("separation", ECART)
		for id: String in Game.ids(categorie):
			cases.add_child(_case(id))
		colonne.add_child(cases)
	colonne.add_child(_etiquette("Fermer : I, Tab ou Échap"))
	panneau.add_child(colonne)
	add_child(panneau)
	ArtIle.ancrer(panneau, 0.5, 0.5, 0.0)


func _case(id: String) -> PanelContainer:
	var case := PanelContainer.new()
	case.add_theme_stylebox_override("panel", ArtIle.cadre(1.0, "interface.5", "interface"))
	case.custom_minimum_size = TAILLE_CASE
	var contenu := VBoxContainer.new()
	contenu.alignment = BoxContainer.ALIGNMENT_CENTER
	var icone := TextureRect.new()
	icone.texture = ArtIle.icone(id, 1.0)
	icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	contenu.add_child(icone)
	var nom := _etiquette(Game.nom_ressource(id))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.custom_minimum_size = Vector2(LARGEUR_NOM, 0.0)
	contenu.add_child(nom)
	var quantite := _etiquette("")
	quantite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenu.add_child(quantite)
	_quantites[id] = quantite
	case.add_child(contenu)
	return case


func est_ouvert() -> bool:
	return visible


func ouvrir() -> void:
	rafraichir()
	visible = true


func fermer() -> void:
	visible = false


func basculer() -> void:
	if visible:
		fermer()
	else:
		ouvrir()


func rafraichir() -> void:
	for id: String in _quantites:
		(_quantites[id] as Label).text = "×%d" % Game.inventaire.quantite(id)


func _sur_clic_a_cote(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.pressed:
		fermer()


func _etiquette(texte: String) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	Pixel.texte(etiquette, ArtIle.CONTOUR, "")
	return etiquette
