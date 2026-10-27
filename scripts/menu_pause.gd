class_name MenuPause
extends MenuCadre
## Menu pause (Échap sur l'île ou en plongée) : le jeu est figé tant qu'il est ouvert.
## Reprendre (ou Échap), Retour au titre et Quitter sauvegardent sur l'île ; en plongée,
## le butin en cours est abandonné (la sauvegarde du départ fait foi), ce que le menu rappelle.

signal reprendre
signal retour_titre
signal quitter

var bouton_reprendre: Button
var bouton_titre: Button
var bouton_quitter: Button

var _note: Label


func _construire() -> void:
	_colonne.add_child(_etiquette("Pause", "or.2"))
	bouton_reprendre = _bouton("Reprendre", func() -> void: reprendre.emit())
	bouton_titre = _bouton("Retour au titre", func() -> void: retour_titre.emit())
	bouton_quitter = _bouton("Quitter", func() -> void: quitter.emit())
	for bouton in [bouton_reprendre, bouton_titre, bouton_quitter]:
		_colonne.add_child(bouton)
	_note = _etiquette("", COULEUR_MESSAGE)
	_colonne.add_child(_note)


## en_plongee : rappelle que quitter la plongée abandonne son butin.
func ouvrir(en_plongee: bool) -> void:
	_note.text = "Le butin de cette plongée sera perdu." if en_plongee else "La partie est sauvegardée en sortant."
	# Violet pour l'avertissement, couleur du texte pour la simple information.
	_note.add_theme_color_override("font_color", Palette.couleur(COULEUR_MESSAGE if en_plongee else COULEUR_TEXTE))
	_recentrer()
	visible = true


func note() -> String:
	return _note.text


func _unhandled_input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		reprendre.emit()
