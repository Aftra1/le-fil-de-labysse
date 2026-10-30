extends Node2D
## Scène principale : enchaîne l'île, la transition et la plongée.
## L'île reste en mémoire pendant la plongée (figée et cachée) ; à son retour,
## elle rattrape la recharge correspondant au temps passé sous l'eau.
## La plongée est créée dès le début de la descente (figée et cachée) et gardée jusqu'à la fin de la
## remontée : la transition dessine son décor sous la surface, ce qui évite toute coupure.
##
## Le jeu s'ouvre sur l'écran titre (île figée derrière). La partie est sauvegardée au départ en
## plongée, au retour sur l'île, après chaque fabrication, à la fermeture de la fenêtre et en
## quittant par le menu pause. Fermer en pleine plongée garde l'état du départ (butin en cours perdu).
## Échap ouvre le menu pause sur l'île et en plongée ; il est ignoré pendant les transitions.

enum Etat { ILE, DESCENTE, PLONGEE, REMONTEE }

const SCENE_PLONGEE := preload("res://scenes/dive.tscn")
## Le HUD de plongée entre pendant les dernières secondes de la descente et sort pendant les
## premières secondes de la remontée, en glissant depuis les bords de l'écran.
const DUREE_GLISSEMENT_HUD := 0.3
var etat := Etat.ILE
var temps_plongee := 0.0
## Faux pour démarrer directement sur l'île (tests) ; à régler avant l'ajout à l'arbre.
var avec_titre := true
## Vrai une fois la partie lancée (Continuer ou Nouvelle partie) : rien n'est sauvegardé avant.
var partie_en_cours := false
## Action des boutons Quitter et de la fermeture de la fenêtre (remplaçable dans les tests) : le son
## est coupé un instant avant de quitter.
var action_quitter: Callable = func() -> void:
	Son.arreter()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit()

var _plongee: Node2D = null
var _gardees: Dictionary = {}
var _perdues: Dictionary = {}
var _urgence := false
var _lecture: Dictionary = {}     # résultat de Sauvegarde.lire() affiché à l'écran titre

@onready var _ile: Ile = $Ile
@onready var _transition: Transition = $Transition
@onready var _conteneur: Node2D = $Plongee
@onready var _titre: EcranTitre = $EcranTitre
@onready var _pause: MenuPause = $MenuPause


func _ready() -> void:
	# La fermeture de la fenêtre passe par _notification (sauvegarde, son coupé, puis sortie).
	get_tree().auto_accept_quit = false
	_ile.plongee_demandee.connect(_lancer_descente)
	_ile.partie_modifiee.connect(sauvegarder)
	_transition.terminee.connect(_fin_transition)
	_titre.continuer.connect(continuer)
	_titre.nouvelle_partie.connect(nouvelle_partie)
	_titre.quitter.connect(func() -> void: action_quitter.call())
	_pause.reprendre.connect(fermer_pause)
	_pause.retour_titre.connect(retour_au_titre)
	_pause.quitter.connect(quitter)
	_pause.volumes_modifies.connect(sauvegarder)
	if avec_titre:
		montrer_titre()
	else:
		partie_en_cours = true


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
		get_tree().auto_accept_quit = true


func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_CLOSE_REQUEST:
		sauvegarder()
		action_quitter.call()


func _unhandled_input(evenement: InputEvent) -> void:
	if evenement.is_action_pressed("pause") and peut_mettre_en_pause():
		get_viewport().set_input_as_handled()
		ouvrir_pause()


func _process(delta: float) -> void:
	if etat == Etat.PLONGEE:
		temps_plongee += delta
	elif etat == Etat.DESCENTE:
		_glisser_hud(1.0 - _transition.temps_restant() / DUREE_GLISSEMENT_HUD)
	elif etat == Etat.REMONTEE:
		_glisser_hud(1.0 - _transition.temps_ecoule() / DUREE_GLISSEMENT_HUD)


func _glisser_hud(progression: float) -> void:
	if not is_instance_valid(_plongee):
		return
	var interface: Interface = _plongee.get_node("HUD")
	interface.visible = progression > 0.0
	interface.glisser(progression)


func plongee() -> Node2D:
	return _plongee


# --- Écran titre et partie -------------------------------------------------------------

## Affiche l'écran titre au-dessus de l'île figée, d'après la sauvegarde trouvée.
func montrer_titre() -> void:
	partie_en_cours = false
	_lecture = Sauvegarde.lire()
	var statut: Sauvegarde.Statut = _lecture["statut"]
	var peut_continuer := statut == Sauvegarde.Statut.OK or statut == Sauvegarde.Statut.RECUPEREE
	if peut_continuer:
		Son.charger_reglages(_lecture["partie"].get("reglages", {}))
	_ile.afficher_interface(false)
	Son.ambiance("ile", 1.0)
	get_tree().paused = true
	_titre.ouvrir(peut_continuer, peut_continuer or statut == Sauvegarde.Statut.TROP_RECENTE, _lecture["message"])


## Reprend la partie sauvegardée ; l'île rattrape le temps passé jeu fermé (plafonné par les sources).
func continuer() -> void:
	var partie: Dictionary = _lecture.get("partie", {})
	if partie.is_empty():
		return
	Game.inventaire = Inventaire.depuis_dictionnaire(partie["inventaire"], Game.ressources.keys())
	Game.atelier.charger_niveaux(partie["ameliorations"])
	Game.atelier.charger_ilots(partie["ilots"])
	Game.atelier.carnet.charger(partie["carnet"])
	Game.atelier.charger_machines(partie["machines"])
	Game.atelier.charger_niveaux_machines(partie["machines_ameliorations"])
	Game.atelier.charger_fourneaux(partie["fourneaux"])
	Game.atelier.charger_palier(partie.get("palier"))
	_ile.restaurer_sources(partie["ile"])
	_ile.rattraper(Sauvegarde.secondes_depuis(partie))
	_commencer()
	if _lecture["statut"] == Sauvegarde.Statut.RECUPEREE:
		sauvegarder()


func nouvelle_partie() -> void:
	if _lecture.get("statut") == Sauvegarde.Statut.TROP_RECENTE:
		Sauvegarde.mettre_de_cote_version_recente()
	Game.inventaire = Inventaire.new()
	_ile.reinitialiser_sources()
	_commencer()
	sauvegarder()


func _commencer() -> void:
	_titre.fermer()
	get_tree().paused = false
	partie_en_cours = true
	_ile.afficher_interface(true)


## Données de la partie à sauvegarder.
func donnees_partie() -> Dictionary:
	return {
		"inventaire": Game.inventaire.vers_dictionnaire(),
		"ameliorations": Game.atelier.niveaux.duplicate(),
		"ilots": Game.atelier.ilots_relies.duplicate(),
		"machines": Game.atelier.machines.duplicate(),
		"machines_ameliorations": Game.atelier.niveaux_machines.duplicate(true),
		"palier": Game.atelier.palier,
		"fourneaux": Game.atelier.recettes_fourneau.duplicate(),
		"carnet": Game.atelier.carnet.vers_dictionnaire(),
		"reglages": Son.reglages(),
		"ile": _ile.etat_sources(),
	}


## Sauvegarde sur l'île seulement : en plongée, la sauvegarde du départ fait foi.
func sauvegarder() -> bool:
	if not partie_en_cours or etat != Etat.ILE:
		return false
	return Sauvegarde.ecrire(donnees_partie())


# --- Menu pause -----------------------------------------------------------------------

func peut_mettre_en_pause() -> bool:
	return partie_en_cours and not _pause.est_ouvert() and (etat == Etat.ILE or etat == Etat.PLONGEE)


func ouvrir_pause() -> void:
	get_tree().paused = true
	_pause.ouvrir(etat == Etat.PLONGEE)


func fermer_pause() -> void:
	_pause.fermer()
	get_tree().paused = false


func retour_au_titre() -> void:
	_pause.fermer()
	if etat == Etat.PLONGEE:
		_abandonner_plongee()
	else:
		sauvegarder()
	montrer_titre()


func quitter() -> void:
	sauvegarder()
	action_quitter.call()


## Plongée abandonnée par le menu pause : son butin est perdu, l'île reprend comme au départ.
func _abandonner_plongee() -> void:
	if is_instance_valid(_plongee):
		_conteneur.remove_child(_plongee)
		_plongee.queue_free()
	_plongee = null
	etat = Etat.ILE
	Son.ambiance("ile", 1.0)
	_ile.reprendre()


# --- Plongée ----------------------------------------------------------------------------

func _lancer_descente() -> void:
	if etat != Etat.ILE:
		return
	sauvegarder()
	Son.jouer("souffle")
	Son.ambiance("lagon", Transition.DUREE)
	etat = Etat.DESCENTE
	_ile.preparer_depart()
	_plongee = SCENE_PLONGEE.instantiate()
	_plongee.retour_ile.connect(_sur_retour_ile)
	_figer_plongee(true)
	_conteneur.add_child(_plongee)
	_plongee.rafraichir_interface()
	_transition.lancer(true, _ile, _plongee)


func _fin_transition() -> void:
	if etat == Etat.DESCENTE:
		_ile.visible = false
		_figer_plongee(false)
		(_plongee.get_node("HUD") as Interface).glisser(1.0)
		temps_plongee = 0.0
		etat = Etat.PLONGEE
	elif etat == Etat.REMONTEE:
		_conteneur.remove_child(_plongee)
		_plongee.queue_free()
		_plongee = null
		etat = Etat.ILE
		_ile.arriver(temps_plongee, _gardees, _perdues, _urgence)
		sauvegarder()


func _sur_retour_ile(gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
	_gardees = gardees
	_perdues = perdues
	_urgence = urgence
	# Différé : le signal est émis depuis le _physics_process de la plongée.
	_lancer_remontee.call_deferred()


func _lancer_remontee() -> void:
	Son.jouer("souffle")
	Son.ambiance("ile", Transition.DUREE)
	_figer_plongee(true)
	etat = Etat.REMONTEE
	_ile.visible = true
	_transition.lancer(false, _ile, _plongee, _plongee.cloche_position(), _plongee.haut_camera())


## Plongée figée et cachée (pendant les transitions) ou active et visible.
func _figer_plongee(figee: bool) -> void:
	_plongee.process_mode = Node.PROCESS_MODE_DISABLED if figee else Node.PROCESS_MODE_INHERIT
	_plongee.visible = not figee
	(_plongee.get_node("HUD") as CanvasLayer).visible = not figee
