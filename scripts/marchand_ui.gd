class_name PanneauMarchand
extends CanvasLayer
## Panneau du marchand de vent (640x360) : cadres or et crème, comme l'atelier. En haut, sa réplique du
## jour ; en dessous, ses trois échanges (ce qu'on donne → ce qu'on reçoit, bouton Échanger, ou « Fait ») ;
## en bas, le temps qu'il reste avant son départ. S'ouvre d'un clic sur son dirigeable ; Échap ou un clic
## à côté le ferme. Il se ferme seul quand le marchand repart.

## Un échange vient d'être fait (l'île l'annonce et sauvegarde).
signal echange_fait(id: String)

const LARGEUR := 500.0
const ECART := 4
const COULEUR_TEXTE := "contour_haut"
const COULEUR_MANQUE := "corail.2"
const COULEUR_REPLIQUE := "or.1"

var _replique: Label
var _lignes: VBoxContainer
var _depart: Label
var _boutons: Dictionary = {}     # échange -> Button


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
	colonne.add_child(_etiquette("Le vieux marchand de vent"))
	_replique = _etiquette("", COULEUR_REPLIQUE)
	_replique.autowrap_mode = TextServer.AUTOWRAP_WORD
	_replique.custom_minimum_size.x = LARGEUR
	colonne.add_child(_replique)
	var cadre := PanelContainer.new()
	cadre.add_theme_stylebox_override("panel", ArtIle.cadre(1.0, "interface.5", "interface"))
	_lignes = VBoxContainer.new()
	_lignes.add_theme_constant_override("separation", ECART)
	cadre.add_child(_lignes)
	colonne.add_child(cadre)
	_depart = _etiquette("")
	colonne.add_child(_depart)
	panneau.add_child(colonne)
	add_child(panneau)
	ArtIle.ancrer(panneau, 0.5, 0.5, 0.0)


func _process(_delta: float) -> void:
	if visible:
		if not Game.atelier.marchand.est_present():
			fermer()
		else:
			rafraichir()


func est_ouvert() -> bool:
	return visible


func ouvrir() -> void:
	var marchand := Game.atelier.marchand
	if not marchand.est_present():
		return
	_replique.text = "« %s »" % marchand.replique()
	for enfant in _lignes.get_children():
		_lignes.remove_child(enfant)
		enfant.queue_free()
	_boutons.clear()
	for id: String in marchand.offres:
		_lignes.add_child(_ligne(id))
	visible = true
	rafraichir()


func fermer() -> void:
	visible = false


func rafraichir() -> void:
	var marchand := Game.atelier.marchand
	for id: String in _boutons:
		var bouton: Button = _boutons[id]
		var fait := marchand.faits.has(id)
		bouton.text = "Fait" if fait else "Échanger"
		bouton.disabled = not marchand.peut_echanger(id, Game.inventaire)
		var donne: Label = bouton.get_meta("donne")
		var assez := true
		for ressource: String in marchand.echange(id)["donne"]:
			assez = assez and Game.inventaire.quantite(ressource) >= int(marchand.echange(id)["donne"][ressource])
		donne.add_theme_color_override("font_color", Palette.couleur(COULEUR_TEXTE if assez or fait else COULEUR_MANQUE))
	_depart.text = "Il repart dans %d s. Fermer : Échap" % ceili(marchand.restant)


## Fait l'échange s'il est possible ; renvoie vrai s'il a eu lieu.
func echanger(id: String) -> bool:
	if not Game.atelier.marchand.echanger(id, Game.inventaire):
		return false
	echange_fait.emit(id)
	rafraichir()
	return true


func bouton(id: String) -> Button:
	return _boutons.get(id)


## Une ligne : icônes et quantités données, flèche, icônes et quantités reçues, bouton Échanger.
func _ligne(id: String) -> HBoxContainer:
	var donnees := Game.atelier.marchand.echange(id)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	ligne.custom_minimum_size.x = LARGEUR - 12.0
	var donne := _etiquette(_texte(donnees["donne"]))
	ligne.add_child(_icones(donnees["donne"]))
	ligne.add_child(donne)
	ligne.add_child(_etiquette("→"))
	ligne.add_child(_icones(donnees["recoit"]))
	var recoit := _etiquette(_texte(donnees["recoit"]))
	recoit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(recoit)
	var bouton := Button.new()
	ArtIle.styler_bouton(bouton)
	bouton.custom_minimum_size.x = 92.0
	bouton.set_meta("donne", donne)
	bouton.pressed.connect(echanger.bind(id))
	_boutons[id] = bouton
	ligne.add_child(bouton)
	return ligne


func _icones(ressources: Dictionary) -> HBoxContainer:
	var boite := HBoxContainer.new()
	boite.add_theme_constant_override("separation", 1)
	for ressource: String in ressources:
		var icone := TextureRect.new()
		icone.texture = ArtIle.icone(ressource, 1.0)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icone.custom_minimum_size = Vector2(16, 16)
		boite.add_child(icone)
	return boite


## « Ouate de nuage ×12 », ou plusieurs ressources séparées par « + ».
func _texte(ressources: Dictionary) -> String:
	var morceaux := PackedStringArray()
	for ressource: String in ressources:
		morceaux.append("%s ×%d" % [Game.nom_ressource(ressource), int(ressources[ressource])])
	return " + ".join(morceaux)


func _sur_clic_a_cote(evenement: InputEvent) -> void:
	if evenement is InputEventMouseButton and evenement.pressed:
		fermer()


func _etiquette(texte: String, couleur: String = COULEUR_TEXTE) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	Pixel.texte(etiquette, couleur, "")
	return etiquette
