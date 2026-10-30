class_name PanneauCarnet
extends CanvasLayer
## Carnet de collection (640x360) : panneau opaque en cadres or et crème, comme l'atelier.
## En haut, le pourcentage du carnet et quatre pages (perles, fossiles, reliques, machines) ; à gauche,
## les six cases de la page (trouvailles agrandies ×3 au pixel près, silhouettes tant qu'elles ne sont pas
## trouvées) ; à droite, la fiche de la case choisie et le bonus de la page.
## S'ouvre et se ferme avec K ou le bouton « Carnet » ; Échap ou un clic à côté le ferme.

const ECHELLE_ICONE := 3
const TAILLE_CASE := Vector2(62.0, 50.0)
const LARGEUR_DETAIL := 280.0
const HAUTEUR_DETAIL := 160.0
const ECART := 4
const COULEUR_TEXTE := "contour_haut"
const COULEUR_BONUS := "or.1"
const ONGLETS := {"lagon": "Perles", "coraux": "Fossiles", "faille": "Reliques", "machines": "Machines"}
const NOMS_ZONES := {"lagon": "le Lagon de lumière", "coraux": "la Forêt de coraux", "faille": "la Faille volcanique"}

var page := "lagon"
var selection := ""

var _titre: Label
var _onglets: Dictionary = {}     # page -> Button
var _grille: GridContainer
var _nom: Label
var _description: Label
var _bonus: Label
var _groupe := ButtonGroup.new()


func _ready() -> void:
	layer = 5
	visible = false
	var capteur := Control.new()
	capteur.size = Vector2(640.0, 360.0)
	capteur.mouse_filter = Control.MOUSE_FILTER_STOP
	capteur.gui_input.connect(_sur_clic_a_cote)
	add_child(capteur)

	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", ArtIle.cadre(1.0))
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", ECART)
	_titre = _etiquette("")
	colonne.add_child(_titre)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", ECART)
	for nom: String in ONGLETS:
		var bouton := Button.new()
		bouton.text = ONGLETS[nom]
		ArtIle.styler_bouton(bouton)
		bouton.toggle_mode = true
		bouton.pressed.connect(choisir_page.bind(nom))
		_onglets[nom] = bouton
		ligne.add_child(bouton)
	colonne.add_child(ligne)

	var corps := HBoxContainer.new()
	corps.add_theme_constant_override("separation", ECART * 2)
	_grille = GridContainer.new()
	_grille.columns = 3
	_grille.add_theme_constant_override("h_separation", ECART)
	_grille.add_theme_constant_override("v_separation", ECART)
	corps.add_child(_grille)
	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", ArtIle.cadre(1.0, "interface.5", "interface"))
	detail.custom_minimum_size = Vector2(LARGEUR_DETAIL, HAUTEUR_DETAIL)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", ECART)
	_nom = _etiquette("")
	contenu.add_child(_nom)
	_description = _etiquette("")
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD
	_description.custom_minimum_size.x = LARGEUR_DETAIL - 24.0
	contenu.add_child(_description)
	detail.add_child(contenu)
	corps.add_child(detail)
	colonne.add_child(corps)
	_bonus = _etiquette("", COULEUR_BONUS)
	_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD
	_bonus.custom_minimum_size.x = 3 * (TAILLE_CASE.x + ECART) + LARGEUR_DETAIL
	colonne.add_child(_bonus)
	colonne.add_child(_etiquette("Fermer : K ou Échap"))
	panneau.add_child(colonne)
	add_child(panneau)
	ArtIle.ancrer(panneau, 0.5, 0.5, 0.0)
	choisir_page("lagon")


func est_ouvert() -> bool:
	return visible


func ouvrir() -> void:
	choisir_page(page)
	visible = true


func fermer() -> void:
	visible = false


func basculer() -> void:
	if visible:
		fermer()
	else:
		ouvrir()


func choisir_page(nom: String) -> void:
	page = nom
	for cle: String in _onglets:
		(_onglets[cle] as Button).set_pressed_no_signal(cle == nom)
	for enfant in _grille.get_children():
		_grille.remove_child(enfant)
		enfant.queue_free()
	var cases := Game.atelier.carnet.cases(nom)
	for id: String in cases:
		_grille.add_child(_case(id))
	selection = str(cases[0])
	rafraichir()


func selectionner(id: String) -> void:
	selection = id
	rafraichir()


func rafraichir() -> void:
	var carnet := Game.atelier.carnet
	_titre.text = "Carnet : %d %%" % carnet.pourcentage()
	for case in _grille.get_children():
		(case as Button).set_pressed_no_signal(case.get_meta("id") == selection)
	var connue := carnet.est_dans_carnet(page, selection)
	if page == "machines":
		_nom.text = Game.atelier.nom_machine(selection) if connue else "Machine pas encore construite"
		_description.text = str(Game.atelier.machine(selection)["effet"]) if connue \
			else "Elle apparaîtra ici quand tu l'auras construite une première fois."
	else:
		var donnees := carnet.trouvaille(selection)
		_nom.text = str(donnees["nom"]) if connue else "Pas encore trouvée"
		_description.text = str(donnees["description"]) if connue \
			else "Un éclat rare la cache quelque part dans %s." % str(NOMS_ZONES.get(page, "l'abysse"))
	var donnees_page := carnet.page(page)
	_bonus.text = ("Page complète : %s" if carnet.page_complete(page) else "%d/%d. Page complète : %s") % (
		[str(donnees_page["bonus"])] if carnet.page_complete(page)
		else [carnet.remplies(page), carnet.cases(page).size(), str(donnees_page["bonus"])])


func _case(id: String) -> Button:
	var carnet := Game.atelier.carnet
	var bouton := Button.new()
	ArtIle.styler_bouton(bouton)
	bouton.toggle_mode = true
	bouton.button_group = _groupe
	bouton.custom_minimum_size = TAILLE_CASE
	bouton.set_meta("id", id)
	bouton.pressed.connect(selectionner.bind(id))
	var texture: Texture2D
	var connue := carnet.est_dans_carnet(page, id)
	if page == "machines":
		texture = ArtIle.icone_machine(id)
		if not connue:
			texture = Pixel.silhouette(texture, Palette.couleur("roche.1"))
	else:
		texture = ArtTrouvailles.icone(id, connue)
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.custom_minimum_size = texture.get_size() * ECHELLE_ICONE
	image.size = image.custom_minimum_size
	image.position = ((TAILLE_CASE - image.custom_minimum_size) / 2.0).floor()
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bouton.add_child(image)
	return bouton


func _sur_clic_a_cote(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.pressed:
		fermer()


func _etiquette(texte: String, couleur: String = COULEUR_TEXTE) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	Pixel.texte(etiquette, couleur, "")
	return etiquette
