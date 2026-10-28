class_name Interface
extends CanvasLayer
## Interface de plongée (640x360) : oxygène, profondeur, zone, sac, annonces et messages.
## Cadres en métal sombre avec une lueur cyan (ArtAbysse.cadre), texte cyan clair.
## glisser() fait entrer ou sortir les panneaux par les bords de l'écran (transitions), au pixel près.

const MARGE := 6.0
# Réserve de base ; le réservoir allonge la jauge (×1,5 puis ×2 : 96, 144, 192 px).
const TAILLE_BARRE := Vector2(96.0, 10.0)
const SEUIL_OXYGENE_BAS := 0.25
const DUREE_ANNONCE := 4.0
const COULEUR_TEXTE := "cyan.3"

var _taille_barre := TAILLE_BARRE
var _barre_conteneur: Control
var _barre_bord: ColorRect
var _barre_fond: ColorRect
var _remplissage := ColorRect.new()
var _reflet := ColorRect.new()
var _etat: PanelContainer
var _profondeur: Label
var _zone: Label
var _sac: Label
var _annonce_panneau: PanelContainer
var _annonce: Label
var _message_panneau: PanelContainer
var _message: Label
var _annonce_restante := 0.0
var _glissement := 1.0
var _bases: Dictionary = {}       # panneau -> Vector4 (offsets gauche, haut, droite, bas en place)


func _ready() -> void:
	_etat = _panneau()
	var etat := _etat
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 2)
	var ligne_air := HBoxContainer.new()
	ligne_air.add_theme_constant_override("separation", 6)
	ligne_air.add_child(_etiquette("Air"))
	ligne_air.add_child(_barre())
	colonne.add_child(ligne_air)
	_profondeur = _etiquette("")
	_zone = _etiquette("")
	_sac = _etiquette("")
	for etiquette in [_profondeur, _zone, _sac]:
		colonne.add_child(etiquette)
	etat.add_child(colonne)
	ArtIle.ancrer(etat, 0.0, 0.0, MARGE)

	_annonce_panneau = _panneau()
	_annonce = _etiquette("")
	_annonce_panneau.add_child(_annonce)
	ArtIle.ancrer(_annonce_panneau, 0.5, 0.0, 0.0)
	_annonce_panneau.offset_top = MARGE
	_annonce_panneau.offset_bottom = MARGE
	_annonce_panneau.visible = false

	_message_panneau = _panneau()
	_message = _etiquette("")
	_message_panneau.add_child(_message)
	ArtIle.ancrer(_message_panneau, 0.0, 1.0, MARGE)
	_message_panneau.visible = false

	for panneau: PanelContainer in [_etat, _annonce_panneau, _message_panneau]:
		_bases[panneau] = Vector4(panneau.offset_left, panneau.offset_top, panneau.offset_right, panneau.offset_bottom)


func _process(delta: float) -> void:
	if _annonce_restante > 0.0:
		_annonce_restante -= delta
		_annonce_panneau.visible = _annonce_restante > 0.0


func mettre_a_jour(ratio_oxygene: float, profondeur_m: float, nom_zone: String, message_bas: String) -> void:
	var largeur := roundf((_taille_barre.x - 2.0) * clampf(ratio_oxygene, 0.0, 1.0))
	_remplissage.size.x = largeur
	_reflet.size.x = largeur
	var bas := ratio_oxygene < SEUIL_OXYGENE_BAS
	_remplissage.color = Palette.couleur("corail.3" if bas else "cyan.2")
	_reflet.color = Palette.couleur("corail.4" if bas else "cyan.3")
	_profondeur.text = "Profondeur : %d m" % int(profondeur_m)
	_zone.text = nom_zone
	_message.text = message_bas
	_message_panneau.visible = message_bas != ""


## progression : 0 = panneaux hors de l'écran, 1 = en place. Chacun sort par son bord le plus proche :
## l'état par la gauche, l'annonce par le haut, le message par le bas. Pas de transparence.
func glisser(progression: float) -> void:
	_glissement = clampf(progression, 0.0, 1.0)
	var reste := 1.0 - smoothstep(0.0, 1.0, _glissement)
	_decaler(_etat, Vector2(-roundf(reste * (_etat.size.x + MARGE)), 0.0))
	_decaler(_annonce_panneau, Vector2(0.0, -roundf(reste * (_annonce_panneau.size.y + MARGE))))
	_decaler(_message_panneau, Vector2(0.0, roundf(reste * (_message_panneau.size.y + MARGE))))


func progression_glissement() -> float:
	return _glissement


## Décalage du panneau par rapport à sa place (pixels d'écran).
func decalage_panneau_etat() -> Vector2:
	var base: Vector4 = _bases[_etat]
	return Vector2(_etat.offset_left - base.x, _etat.offset_top - base.y)


func _decaler(panneau: PanelContainer, decalage: Vector2) -> void:
	var base: Vector4 = _bases[panneau]
	panneau.offset_left = base.x + decalage.x
	panneau.offset_right = base.z + decalage.x
	panneau.offset_top = base.y + decalage.y
	panneau.offset_bottom = base.w + decalage.y


## Longueur de la jauge d'oxygène proportionnelle à la réserve (1 = réserve de base).
func regler_reserve(facteur: float) -> void:
	_taille_barre = Vector2(roundf(TAILLE_BARRE.x * facteur), TAILLE_BARRE.y)
	_barre_conteneur.custom_minimum_size = _taille_barre
	_barre_bord.size = _taille_barre
	_barre_fond.size = _taille_barre - Vector2(2, 2)
	_reflet.size.y = 2.0


func largeur_jauge() -> float:
	return _taille_barre.x


func definir_sac(texte: String) -> void:
	_sac.text = texte


func annoncer(texte: String, duree: float = DUREE_ANNONCE) -> void:
	_annonce.text = texte
	_annonce_panneau.visible = true
	_annonce_restante = duree


## Jauge d'oxygène : fond noir, remplissage cyan (violet lumineux quand il reste peu d'air).
func _barre() -> Control:
	var barre := Control.new()
	_barre_conteneur = barre
	barre.custom_minimum_size = TAILLE_BARRE
	barre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bord := ColorRect.new()
	_barre_bord = bord
	bord.color = Palette.couleur("metal.2")
	bord.size = TAILLE_BARRE
	barre.add_child(bord)
	var fond := ColorRect.new()
	_barre_fond = fond
	fond.color = Palette.couleur("abysse.0")
	fond.position = Vector2.ONE
	fond.size = TAILLE_BARRE - Vector2(2, 2)
	barre.add_child(fond)
	_remplissage.position = Vector2.ONE
	_remplissage.size = TAILLE_BARRE - Vector2(2, 2)
	barre.add_child(_remplissage)
	_reflet.position = Vector2.ONE
	_reflet.size = Vector2(TAILLE_BARRE.x - 2.0, 2.0)
	barre.add_child(_reflet)
	return barre


## Panneau d'information : il ne capte pas la souris.
func _panneau() -> PanelContainer:
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", ArtAbysse.cadre())
	panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panneau)
	return panneau


func _etiquette(texte: String) -> Label:
	var etiquette := Label.new()
	etiquette.text = texte
	Pixel.texte(etiquette, COULEUR_TEXTE, "")
	return etiquette
