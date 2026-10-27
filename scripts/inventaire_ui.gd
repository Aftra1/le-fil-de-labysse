class_name PanneauInventaire
extends CanvasLayer
## Panneau d'inventaire : une case par ressource (pastille, nom, quantité).
## S'ouvre et se ferme avec I / Tab ou le bouton ; Échap ou un clic à côté le ferme.

const TAILLE_PANNEAU := Vector2(400.0, 170.0)
const TAILLE_CASE := Vector2(68.0, 92.0)
const ECART_CASES := 8.0
const TAILLE_PASTILLE := 20.0
const TAILLE_POLICE := 12
const TAILLE_POLICE_PETITE := 10

const COULEUR_VOILE := Color(0.05, 0.08, 0.15, 0.55)
const COULEUR_PANNEAU := Color("f4efe6")
const COULEUR_BORD := Color("e8b923")
const COULEUR_CASE := Color("e3d9c4")
const COULEUR_TEXTE := Color("2a3550")

var _quantites: Dictionary = {}   # id -> Label


func _ready() -> void:
	layer = 5
	visible = false

	var voile := ColorRect.new()
	voile.color = COULEUR_VOILE
	voile.size = Vector2(640.0, 360.0)
	voile.gui_input.connect(_sur_clic_voile)
	add_child(voile)

	var origine := (Vector2(640.0, 360.0) - TAILLE_PANNEAU) / 2.0
	var bord := ColorRect.new()
	bord.color = COULEUR_BORD
	bord.position = origine - Vector2.ONE * 2.0
	bord.size = TAILLE_PANNEAU + Vector2.ONE * 4.0
	add_child(bord)
	var panneau := ColorRect.new()
	panneau.color = COULEUR_PANNEAU
	panneau.position = origine
	panneau.size = TAILLE_PANNEAU
	add_child(panneau)

	_etiquette("Inventaire", origine + Vector2(12.0, 8.0), TAILLE_POLICE)
	_etiquette("Fermer : I, Tab ou Échap", origine + Vector2(12.0, TAILLE_PANNEAU.y - 22.0), TAILLE_POLICE_PETITE)

	var ids := Game.ressources.keys()
	var largeur := ids.size() * TAILLE_CASE.x + (ids.size() - 1) * ECART_CASES
	var x := origine.x + (TAILLE_PANNEAU.x - largeur) / 2.0
	var y := origine.y + 34.0
	for id: String in ids:
		var case := ColorRect.new()
		case.color = COULEUR_CASE
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
		var nom := _etiquette(Game.nom_ressource(id), Vector2(x + 2.0, y + 32.0), TAILLE_POLICE_PETITE)
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.custom_minimum_size = Vector2(TAILLE_CASE.x - 4.0, 0.0)
		nom.size = Vector2(TAILLE_CASE.x - 4.0, 30.0)
		var quantite := _etiquette("", Vector2(x, y + TAILLE_CASE.y - 20.0), TAILLE_POLICE)
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


func _etiquette(texte: String, position_etiquette: Vector2, taille_police: int) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	etiquette.position = position_etiquette
	etiquette.add_theme_font_size_override("font_size", taille_police)
	etiquette.add_theme_color_override("font_color", COULEUR_TEXTE)
	add_child(etiquette)
	return etiquette
