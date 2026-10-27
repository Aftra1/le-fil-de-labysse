class_name EcranTitre
extends MenuCadre
## Écran titre, en haut de l'écran pour laisser voir l'île figée : Continuer (grisé sans sauvegarde),
## Nouvelle partie (confirmation si une partie existe déjà), Quitter. Un message discret signale une
## sauvegarde abîmée, reprise ou d'une version plus récente.

signal continuer
signal nouvelle_partie
signal quitter

const TAILLE_TITRE := 32   # 2 × la taille de la police pixel : le titre reste net

var bouton_continuer: Button
var bouton_nouvelle: Button
var bouton_quitter: Button
var bouton_remplacer: Button
var bouton_annuler: Button

var _message: Label
var _choix: HBoxContainer
var _confirmation: VBoxContainer
var _partie_existante := false


func _construire() -> void:
	ancre_y = 0.0
	marge_y = 16.0
	var titre := _etiquette("Le Fil de l'Abysse", "or.2")
	titre.add_theme_font_size_override("font_size", TAILLE_TITRE)
	_colonne.add_child(titre)
	var sous_titre := _etiquette("Gardien d'une île au-dessus de l'abîme")
	_colonne.add_child(sous_titre)
	var espace := Control.new()
	espace.custom_minimum_size.y = ECART
	_colonne.add_child(espace)

	_choix = HBoxContainer.new()
	_choix.add_theme_constant_override("separation", ECART)
	_choix.alignment = BoxContainer.ALIGNMENT_CENTER
	bouton_continuer = _bouton("Continuer", func() -> void: continuer.emit())
	bouton_nouvelle = _bouton("Nouvelle partie", demander_nouvelle_partie)
	bouton_quitter = _bouton("Quitter", func() -> void: quitter.emit())
	for bouton in [bouton_continuer, bouton_nouvelle, bouton_quitter]:
		_choix.add_child(bouton)
	_colonne.add_child(_choix)

	_confirmation = VBoxContainer.new()
	_confirmation.add_theme_constant_override("separation", ECART)
	_confirmation.add_child(_etiquette("Une partie existe déjà. La remplacer ?"))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", ECART)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	bouton_remplacer = _bouton("Remplacer", func() -> void:
		_montrer_confirmation(false)
		nouvelle_partie.emit())
	bouton_annuler = _bouton("Annuler", annuler_confirmation)
	ligne.add_child(bouton_remplacer)
	ligne.add_child(bouton_annuler)
	_confirmation.add_child(ligne)
	_confirmation.visible = false
	_colonne.add_child(_confirmation)

	_message = _etiquette("", COULEUR_MESSAGE)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message.custom_minimum_size.x = 400.0
	_message.visible = false
	_colonne.add_child(_message)


## peut_continuer : une sauvegarde utilisable existe ; partie_existante : Nouvelle partie demande
## confirmation ; message : vide si tout va bien.
func ouvrir(peut_continuer: bool, partie_existante: bool, message: String) -> void:
	bouton_continuer.disabled = not peut_continuer
	_partie_existante = partie_existante
	_message.text = message
	_message.visible = message != ""
	_montrer_confirmation(false)
	visible = true


func demander_nouvelle_partie() -> void:
	if _partie_existante:
		_montrer_confirmation(true)
	else:
		nouvelle_partie.emit()


func annuler_confirmation() -> void:
	_montrer_confirmation(false)


func confirmation_ouverte() -> bool:
	return _confirmation.visible


func message() -> String:
	return _message.text if _message.visible else ""


func _montrer_confirmation(montrer: bool) -> void:
	_confirmation.visible = montrer
	_choix.visible = not montrer
	_recentrer()


func _unhandled_input(evenement: InputEvent) -> void:
	if visible and evenement.is_action_pressed("pause"):
		if confirmation_ouverte():
			annuler_confirmation()
		get_viewport().set_input_as_handled()
