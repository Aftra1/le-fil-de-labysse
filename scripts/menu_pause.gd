class_name MenuPause
extends MenuCadre
## Menu pause (Échap sur l'île ou en plongée) : le jeu est figé tant qu'il est ouvert.
## Reprendre (ou Échap), Retour au titre et Quitter sauvegardent sur l'île ; en plongée,
## le butin en cours est abandonné (la sauvegarde du départ fait foi), ce que le menu rappelle.
## Deux réglages de volume (musique, effets), par pas de 10 %, appliqués tout de suite ; ils sont
## enregistrés avec la partie (signal volumes_modifies).

signal reprendre
signal retour_titre
signal quitter
signal volumes_modifies

const LARGEUR_NOM := 72.0
const LARGEUR_VALEUR := 52.0
const PAS_VOLUME := 0.1

var bouton_reprendre: Button
var bouton_titre: Button
var bouton_quitter: Button
## Boutons de volume : { "musique": [moins, plus], "effets": [moins, plus] }
var boutons_volume: Dictionary = {}

var _valeurs: Dictionary = {}          # « musique » / « effets » -> Label du pourcentage

var _note: Label


func _construire() -> void:
	_colonne.add_child(_etiquette("Pause", "or.2"))
	bouton_reprendre = _bouton("Reprendre", func() -> void: reprendre.emit())
	bouton_titre = _bouton("Retour au titre", func() -> void: retour_titre.emit())
	bouton_quitter = _bouton("Quitter", func() -> void: quitter.emit())
	for bouton in [bouton_reprendre, bouton_titre, bouton_quitter]:
		_colonne.add_child(bouton)
	for canal: String in ["musique", "effets"]:
		_colonne.add_child(_ligne_volume(canal))
	_note = _etiquette("", COULEUR_MESSAGE)
	_colonne.add_child(_note)


## en_plongee : rappelle que quitter la plongée abandonne son butin.
func ouvrir(en_plongee: bool) -> void:
	_note.text = "Le butin de cette plongée sera perdu." if en_plongee else "La partie est sauvegardée en sortant."
	# Violet pour l'avertissement, couleur du texte pour la simple information.
	_note.add_theme_color_override("font_color", Palette.couleur(COULEUR_MESSAGE if en_plongee else COULEUR_TEXTE))
	_afficher_volumes()
	_recentrer()
	visible = true


func note() -> String:
	return _note.text


## Monte ou baisse un volume d'un pas (« musique » ou « effets »).
func changer_volume(canal: String, sens: int) -> void:
	var musique: float = Son.volume_musique + (PAS_VOLUME * sens if canal == "musique" else 0.0)
	var effets: float = Son.volume_effets + (PAS_VOLUME * sens if canal == "effets" else 0.0)
	Son.regler_volumes(musique, effets)
	_afficher_volumes()
	volumes_modifies.emit()


func _ligne_volume(canal: String) -> HBoxContainer:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", ECART)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	var nom := _etiquette("Musique" if canal == "musique" else "Effets")
	nom.custom_minimum_size.x = LARGEUR_NOM
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var moins := _petit_bouton("−", changer_volume.bind(canal, -1))
	var valeur := _etiquette("")
	valeur.custom_minimum_size.x = LARGEUR_VALEUR
	var plus := _petit_bouton("+", changer_volume.bind(canal, 1))
	for enfant in [nom, moins, valeur, plus]:
		ligne.add_child(enfant)
	_valeurs[canal] = valeur
	boutons_volume[canal] = [moins, plus]
	return ligne


func _petit_bouton(texte: String, action: Callable) -> Button:
	var bouton := _bouton(texte, action)
	bouton.custom_minimum_size.x = 28.0
	return bouton


func _afficher_volumes() -> void:
	for canal: String in _valeurs:
		var volume: float = Son.volume_musique if canal == "musique" else Son.volume_effets
		(_valeurs[canal] as Label).text = "%d %%" % roundi(volume * 100.0)


func _unhandled_input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		reprendre.emit()
