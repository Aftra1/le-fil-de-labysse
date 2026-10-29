class_name PanneauAtelier
extends CanvasLayer
## Interface de l'atelier (640x360) : panneau opaque en cadres or et crème.
## En haut, quatre onglets (composants, améliorations, construction, machines) ; à gauche, la liste des
## recettes ; à droite, le détail de la recette choisie : ingrédients « possédé / requis », effet, bouton
## Fabriquer, Installer ou Construire.
## Onglet Machines : la machine est construite sur l'emplacement cliqué sur l'île (emplacement_cible),
## ou à défaut sur le premier emplacement libre. À partir du palier 2, trois boutons en haut du détail
## choisissent entre Construire et les améliorations de cette sorte de machine (Vitesse, Réserve).
## S'ouvre et se ferme avec C ou un clic sur la cabane ; Échap ou un clic à côté le ferme.

## genre : « composant » (fabriqué), « amelioration » (installée), « construction » (construite)
## « machine » (construite sur un emplacement) ou « machine_amelioration » (vitesse ou réserve).
signal fabrique(id: String, genre: String)

const LARGEUR_LISTE := 196.0
const LARGEUR_DETAIL := 300.0
const HAUTEUR_DETAIL := 196.0
const ECART := 4
const COULEUR_TEXTE := "contour_haut"
const COULEUR_MANQUE := "corail.2"

const MODES := {"construire": "Construire", "vitesse": "Vitesse", "capacite": "Réserve"}
const ONGLETS := {
	"composants": "Composants", "ameliorations": "Améliorations", "construction": "Construction", "machines": "Machines",
}

var onglet := "composants"       # « composants », « ameliorations », « construction » ou « machines »
var selection := ""
## Emplacement choisi sur l'île pour la prochaine machine (vide : le premier libre).
var emplacement_cible := ""
## Emplacement de la dernière machine construite.
var dernier_emplacement := ""
## Onglet Machines : « construire », « vitesse » ou « capacite ».
var mode := "construire"

var _liste: VBoxContainer
var _onglets: Dictionary = {}     # onglet -> Button
var _titre: Label
var _modes: HBoxContainer
var _boutons_modes: Dictionary = {}   # mode -> Button
var _effet: Label
var _ingredients: VBoxContainer
var _bouton: Button
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
	colonne.add_child(_etiquette("Atelier"))
	var ligne_onglets := HBoxContainer.new()
	ligne_onglets.add_theme_constant_override("separation", ECART)
	for nom: String in ONGLETS:
		var bouton := Button.new()
		bouton.text = ONGLETS[nom]
		ArtIle.styler_bouton(bouton)
		bouton.toggle_mode = true
		bouton.pressed.connect(choisir_onglet.bind(nom))
		_onglets[nom] = bouton
		ligne_onglets.add_child(bouton)
	colonne.add_child(ligne_onglets)

	var corps := HBoxContainer.new()
	corps.add_theme_constant_override("separation", ECART * 2)
	var gauche := VBoxContainer.new()
	gauche.custom_minimum_size.x = LARGEUR_LISTE
	gauche.add_theme_constant_override("separation", ECART)
	_liste = VBoxContainer.new()
	_liste.add_theme_constant_override("separation", ECART)
	gauche.add_child(_liste)
	corps.add_child(gauche)

	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", ArtIle.cadre(1.0, "interface.5", "interface"))
	detail.custom_minimum_size = Vector2(LARGEUR_DETAIL, HAUTEUR_DETAIL)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", ECART)
	_titre = _etiquette("")
	contenu.add_child(_titre)
	_modes = HBoxContainer.new()
	_modes.add_theme_constant_override("separation", ECART)
	for nom: String in MODES:
		var bouton := Button.new()
		bouton.text = MODES[nom]
		ArtIle.styler_bouton(bouton)
		bouton.toggle_mode = true
		bouton.pressed.connect(choisir_mode.bind(nom))
		_boutons_modes[nom] = bouton
		_modes.add_child(bouton)
	contenu.add_child(_modes)
	_effet = _etiquette("")
	_effet.autowrap_mode = TextServer.AUTOWRAP_WORD
	_effet.custom_minimum_size.x = LARGEUR_DETAIL - 24.0
	contenu.add_child(_effet)
	_ingredients = VBoxContainer.new()
	_ingredients.add_theme_constant_override("separation", 2)
	contenu.add_child(_ingredients)
	var espace := Control.new()
	espace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenu.add_child(espace)
	_bouton = Button.new()
	ArtIle.styler_bouton(_bouton)
	_bouton.size_flags_horizontal = Control.SIZE_SHRINK_END
	_bouton.pressed.connect(fabriquer_selection)
	contenu.add_child(_bouton)
	detail.add_child(contenu)
	corps.add_child(detail)
	colonne.add_child(corps)
	colonne.add_child(_etiquette("Fermer : C ou Échap"))
	panneau.add_child(colonne)
	add_child(panneau)
	ArtIle.ancrer(panneau, 0.5, 0.5, 0.0)
	choisir_onglet("composants")


func est_ouvert() -> bool:
	return visible


func ouvrir() -> void:
	emplacement_cible = ""
	rafraichir()
	visible = true


## Ouvre l'onglet Machines pour construire sur cet emplacement (clic sur un emplacement libre).
func ouvrir_machines(emplacement: String) -> void:
	ouvrir()
	choisir_onglet("machines")
	emplacement_cible = emplacement
	rafraichir()


func fermer() -> void:
	visible = false


func basculer() -> void:
	if visible:
		fermer()
	else:
		ouvrir()


func choisir_onglet(nom: String) -> void:
	onglet = nom
	for cle: String in _onglets:
		(_onglets[cle] as Button).set_pressed_no_signal(cle == nom)
	var ids: Array = Game.atelier.composants()
	if nom == "ameliorations":
		ids = Atelier.AMELIORATIONS
	elif nom == "construction":
		ids = Atelier.CONSTRUCTIONS
	elif nom == "machines":
		ids = Game.atelier.machines_disponibles()
	mode = "construire"
	selection = ids[0]
	_remplir_liste(ids)
	rafraichir()


func selectionner(id: String) -> void:
	selection = id
	mode = "construire"
	rafraichir()


## Onglet Machines : construire, ou améliorer la vitesse ou la réserve de cette sorte de machine.
func choisir_mode(nom: String) -> void:
	mode = nom
	rafraichir()


## Fabrique, installe ou construit la recette sélectionnée, si c'est possible.
func fabriquer_selection() -> bool:
	var reussi := false
	var genre := "composant"
	match onglet:
		"ameliorations":
			genre = "amelioration"
			reussi = Game.atelier.ameliorer(selection)
		"construction":
			genre = "construction"
			reussi = Game.atelier.construire(selection)
		"machines":
			if mode == "construire":
				genre = "machine"
				dernier_emplacement = Game.atelier.construire_machine(selection, emplacement_cible)
				reussi = dernier_emplacement != ""
				emplacement_cible = ""
			else:
				genre = "machine_amelioration"
				reussi = Game.atelier.ameliorer_machine(selection, mode)
		_:
			reussi = Game.atelier.fabriquer(selection)
	if reussi:
		fabrique.emit(selection, genre)
	rafraichir()
	return reussi


func peut_fabriquer_selection() -> bool:
	match onglet:
		"ameliorations":
			return Game.atelier.peut_ameliorer(selection)
		"construction":
			return Game.atelier.peut_construire(selection)
		"machines":
			if mode != "construire":
				return Game.atelier.peut_ameliorer_machine(selection, mode)
			return Game.atelier.peut_construire_machine(selection)
	return Game.atelier.peut_fabriquer(selection)


func rafraichir() -> void:
	for bouton in _liste.get_children():
		var id: String = bouton.get_meta("id")
		(bouton as Button).set_pressed_no_signal(id == selection)
		(bouton as Button).text = _libelle(id)
	_titre.text = _libelle(selection)
	for enfant in _ingredients.get_children():
		enfant.queue_free()
	var ingredients := {}
	if onglet == "ameliorations":
		var recette := Game.atelier.prochain_niveau(selection)
		_effet.text = "Installée : niveau maximal atteint." if recette.is_empty() else str(recette["effet"])
		ingredients = {} if recette.is_empty() else recette["ingredients"]
		_bouton.text = "Installer"
	elif onglet == "construction":
		var construite := Game.atelier.est_construite(selection)
		_effet.text = "Construite : l'îlot est relié." if construite else Game.atelier.effet_construction(selection)
		ingredients = {} if construite else Game.atelier.ingredients_construction(selection)
		_bouton.text = "Construire"
	elif onglet == "machines" and mode != "construire":
		_effet.text = _texte_amelioration()
		ingredients = Game.atelier.prochaine_amelioration_machine(selection, mode)
		_bouton.text = "Améliorer"
	elif onglet == "machines":
		_effet.text = "%s\n%s" % [str(Game.atelier.machine(selection)["effet"]), _texte_emplacement()]
		ingredients = Game.atelier.machine(selection)["ingredients"]
		_bouton.text = "Construire"
	else:
		_effet.text = "Composant pour les améliorations de la cloche."
		ingredients = Game.atelier.ingredients_composant(selection)
		_bouton.text = "Fabriquer"
	for id: String in ingredients:
		_ingredients.add_child(_ligne_ingredient(id, int(ingredients[id])))
	_bouton.disabled = not peut_fabriquer_selection()
	# Boutons Construire / Vitesse / Réserve à la place du titre (machines améliorables, palier 2).
	var avec_modes := onglet == "machines" and Game.atelier.palier >= 2 \
		and Game.atelier.machines_ameliorables().has(selection)
	_modes.visible = avec_modes
	_titre.visible = not avec_modes
	for nom: String in _boutons_modes:
		(_boutons_modes[nom] as Button).set_pressed_no_signal(nom == mode)


func _remplir_liste(ids: Array) -> void:
	for enfant in _liste.get_children():
		_liste.remove_child(enfant)
		enfant.queue_free()
	for id: String in ids:
		var bouton := Button.new()
		ArtIle.styler_bouton(bouton)
		bouton.toggle_mode = true
		bouton.button_group = _groupe
		bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		match onglet:
			"ameliorations":
				bouton.icon = ArtIle.icone_amelioration(id)
			"construction":
				bouton.icon = ArtIle.icone_construction(id)
			"machines":
				bouton.icon = ArtIle.icone_machine(id)
			_:
				bouton.icon = ArtIle.icone(id, 1.0)
		bouton.set_meta("id", id)
		bouton.pressed.connect(selectionner.bind(id))
		_liste.add_child(bouton)


func _libelle(id: String) -> String:
	if onglet == "ameliorations":
		var atelier := Game.atelier
		return "%s  %d/%d" % [atelier.nom_amelioration(id), atelier.niveau(id), atelier.niveau_max(id)]
	if onglet == "construction":
		return Game.atelier.nom_construction(id)
	if onglet == "machines":
		var nombre := Game.atelier.nombre_machines(id)
		return Game.atelier.nom_machine(id) + ("  ×%d" % nombre if nombre > 0 else "")
	return Game.nom_ressource(id)


## Effet de la prochaine amélioration de cette sorte de machine (toutes les machines de la sorte).
func _texte_amelioration() -> String:
	var atelier := Game.atelier
	var reglage := atelier.machine(selection)
	if atelier.prochaine_amelioration_machine(selection, mode).is_empty():
		return "Niveau maximal atteint pour l'instant."
	var texte := ""
	if mode == "vitesse":
		texte = "1 %s toutes les %s s au lieu de %s s." % [_unite(str(reglage["ressource"])),
			_nombre(atelier.recharge_machine(selection) / 1.5), _nombre(atelier.recharge_machine(selection))]
	else:
		texte = "Réserve de %d au lieu de %d." % [atelier.plafond_machine(selection) * 2, atelier.plafond_machine(selection)]
	if atelier.nombre_machines(selection) == 0:
		return texte + "\nConstruis d'abord cette machine."
	return texte + "\nPour toutes ces machines."


func _unite(ressource: String) -> String:
	return {"vent": "vent", "nuage": "ouate", "cristal_solaire": "cristal"}.get(ressource, ressource)


func _nombre(valeur: float) -> String:
	return str(snappedf(valeur, 0.1)).replace(".", ",").trim_suffix(",0")


## Où ira la prochaine machine.
func _texte_emplacement() -> String:
	var atelier := Game.atelier
	var libres := atelier.emplacements_libres(selection)
	if libres.is_empty():
		return "Aucun filon libre." if atelier.sur_filon(selection) else "Aucun emplacement libre."
	var lieu := emplacement_cible if libres.has(emplacement_cible) else str(libres[0])
	return "Emplacement : %s" % str(atelier.emplacement(lieu)["nom"])


func _ligne_ingredient(id: String, requis: int) -> HBoxContainer:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	var icone := TextureRect.new()
	icone.texture = ArtIle.icone(id, 1.0)
	icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icone.custom_minimum_size = Vector2(16, 16)
	ligne.add_child(icone)
	var possede := Game.inventaire.quantite(id)
	var nom := _etiquette(Game.nom_ressource(id))
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(nom)
	ligne.add_child(_etiquette("%d / %d" % [possede, requis], COULEUR_TEXTE if possede >= requis else COULEUR_MANQUE))
	return ligne


func _sur_clic_a_cote(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.pressed:
		fermer()


func _etiquette(texte: String, couleur: String = COULEUR_TEXTE) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	Pixel.texte(etiquette, couleur, "")
	return etiquette
