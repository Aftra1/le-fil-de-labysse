class_name Interface
extends CanvasLayer
## Interface de plongée : oxygène, profondeur, zone, sac, stock de l'île et messages.

const POSITION_BARRE := Vector2(8.0, 8.0)
const TAILLE_BARRE := Vector2(120.0, 8.0)
const TAILLE_POLICE := 12
const TAILLE_POLICE_ANNONCE := 16
const SEUIL_OXYGENE_BAS := 0.25
const DUREE_ANNONCE := 4.0
const LARGEUR_ECRAN := 640.0

const COULEUR_FOND := Color(0.0, 0.0, 0.0, 0.5)
const COULEUR_OXYGENE := Color("3fe0e8")
const COULEUR_OXYGENE_BAS := Color("b06cff")
const COULEUR_TEXTE := Color("ffffff")

var _remplissage := ColorRect.new()
var _profondeur := Label.new()
var _zone := Label.new()
var _sac := Label.new()
var _stock := Label.new()
var _annonce := Label.new()
var _message := Label.new()
var _annonce_restante := 0.0


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = COULEUR_FOND
	fond.position = POSITION_BARRE - Vector2.ONE
	fond.size = TAILLE_BARRE + Vector2.ONE * 2.0
	add_child(fond)

	_remplissage.position = POSITION_BARRE
	_remplissage.size = TAILLE_BARRE
	add_child(_remplissage)

	_placer(_profondeur, Vector2(8.0, 22.0))
	_placer(_zone, Vector2(8.0, 36.0))
	_placer(_sac, Vector2(8.0, 50.0))

	_placer(_stock, Vector2(LARGEUR_ECRAN - 308.0, 8.0))
	_stock.size.x = 300.0
	_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_placer(_annonce, Vector2(0.0, 36.0), TAILLE_POLICE_ANNONCE)
	_annonce.size.x = LARGEUR_ECRAN
	_annonce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_annonce.visible = false

	_placer(_message, Vector2(8.0, 330.0))
	_message.visible = false


func _process(delta: float) -> void:
	if _annonce_restante > 0.0:
		_annonce_restante -= delta
		_annonce.visible = _annonce_restante > 0.0


func mettre_a_jour(ratio_oxygene: float, profondeur_m: float, nom_zone: String, message_bas: String) -> void:
	_remplissage.size.x = TAILLE_BARRE.x * clampf(ratio_oxygene, 0.0, 1.0)
	_remplissage.color = COULEUR_OXYGENE_BAS if ratio_oxygene < SEUIL_OXYGENE_BAS else COULEUR_OXYGENE
	_profondeur.text = "Profondeur : %d m" % int(profondeur_m)
	_zone.text = nom_zone
	_message.text = message_bas
	_message.visible = message_bas != ""


func definir_sac(texte: String) -> void:
	_sac.text = texte


func definir_stock(texte: String) -> void:
	_stock.text = texte


## Affiche un message temporaire au centre en haut.
func annoncer(texte: String, duree: float = DUREE_ANNONCE) -> void:
	_annonce.text = texte
	_annonce.visible = true
	_annonce_restante = duree


func _placer(etiquette: Label, position_etiquette: Vector2, taille_police: int = TAILLE_POLICE) -> void:
	etiquette.position = position_etiquette
	etiquette.add_theme_font_size_override("font_size", taille_police)
	etiquette.add_theme_color_override("font_color", COULEUR_TEXTE)
	etiquette.add_theme_color_override("font_outline_color", Color.BLACK)
	etiquette.add_theme_constant_override("outline_size", 3)
	add_child(etiquette)
