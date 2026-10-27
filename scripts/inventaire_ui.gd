class_name PanneauInventaire
extends CanvasLayer
## Panneau d'inventaire : une case par ressource (pastille, nom, quantité).
## S'ouvre et se ferme avec I / Tab ou le bouton ; Échap ou un clic à côté le ferme.

const TAILLE_PANNEAU := Vector2(500.0, 196.0)
const TAILLE_CASE := Vector2(88.0, 112.0)
const ECART_CASES := 8.0
const TAILLE_PASTILLE := 20.0

# Couleurs : noms de la palette. Le voile est une trame (1 pixel sur 2), pas une transparence.
const COULEUR_VOILE := "nuit"
const COULEUR_PANNEAU := "creme"
const COULEUR_BORD := "or"
const COULEUR_BORD_FONCE := "or_fonce"
const COULEUR_CASE := "nacre"
const COULEUR_CASE_BORD := "lavande"
const COULEUR_TEXTE := "nuit"

var _quantites: Dictionary = {}   # id -> Label


func _ready() -> void:
	layer = 5
	visible = false

	var voile := TextureRect.new()
	voile.texture = Pixel.damier(Palette.couleur(COULEUR_VOILE), Color(0.0, 0.0, 0.0, 0.0))
	voile.stretch_mode = TextureRect.STRETCH_TILE
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	Pixel.activer_motifs(voile)
	voile.size = Vector2(640.0, 360.0)
	voile.gui_input.connect(_sur_clic_voile)
	add_child(voile)

	var origine := (Vector2(640.0, 360.0) - TAILLE_PANNEAU) / 2.0
	var bord_fonce := ColorRect.new()
	bord_fonce.color = Palette.couleur(COULEUR_BORD_FONCE)
	bord_fonce.position = origine - Vector2.ONE * 3.0
	bord_fonce.size = TAILLE_PANNEAU + Vector2.ONE * 6.0
	add_child(bord_fonce)
	var bord := ColorRect.new()
	bord.color = Palette.couleur(COULEUR_BORD)
	bord.position = origine - Vector2.ONE * 2.0
	bord.size = TAILLE_PANNEAU + Vector2.ONE * 4.0
	add_child(bord)
	var panneau := ColorRect.new()
	panneau.color = Palette.couleur(COULEUR_PANNEAU)
	panneau.position = origine
	panneau.size = TAILLE_PANNEAU
	add_child(panneau)

	_etiquette("Inventaire", origine + Vector2(12.0, 6.0))
	_etiquette("Fermer : I, Tab ou Échap", origine + Vector2(12.0, TAILLE_PANNEAU.y - 24.0))

	var ids := Game.ressources.keys()
	var largeur := ids.size() * TAILLE_CASE.x + (ids.size() - 1) * ECART_CASES
	var x := origine.x + (TAILLE_PANNEAU.x - largeur) / 2.0
	var y := origine.y + 32.0
	for id: String in ids:
		var case_bord := ColorRect.new()
		case_bord.color = Palette.couleur(COULEUR_CASE_BORD)
		case_bord.position = Vector2(x - 1.0, y - 1.0)
		case_bord.size = TAILLE_CASE + Vector2.ONE * 2.0
		case_bord.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(case_bord)
		var case := ColorRect.new()
		case.color = Palette.couleur(COULEUR_CASE)
		case.position = Vector2(x, y)
		case.size = TAILLE_CASE
		case.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(case)
		var pastille := ColorRect.new()
		pastille.color = Game.couleur_ressource(id)
		pastille.position = Vector2(x + (TAILLE_CASE.x - TAILLE_PASTILLE) / 2.0, y + 8.0)
		pastille.size = Vector2.ONE * TAILLE_PASTILLE
		pastille.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pastille)
		var nom := _etiquette(Game.nom_ressource(id), Vector2(x + 2.0, y + 32.0))
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.custom_minimum_size = Vector2(TAILLE_CASE.x - 4.0, 0.0)
		nom.size = Vector2(TAILLE_CASE.x - 4.0, 40.0)
		var quantite := _etiquette("", Vector2(x, y + TAILLE_CASE.y - 22.0))
		quantite.size.x = TAILLE_CASE.x
		quantite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_quantites[id] = quantite
		x += TAILLE_CASE.x + ECART_CASES


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


func _sur_clic_voile(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.pressed:
		fermer()


func _etiquette(texte: String, position_etiquette: Vector2) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.position = position_etiquette
	Pixel.texte(etiquette, COULEUR_TEXTE, "")
	add_child(etiquette)
	return etiquette
