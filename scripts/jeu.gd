extends Node2D
## Scène principale : enchaîne l'île, la transition et la plongée.
## L'île reste en mémoire pendant la plongée (figée et cachée) ; à son retour,
## elle rattrape la recharge correspondant au temps passé sous l'eau.
## La plongée est créée dès le début de la descente (figée et cachée) et gardée jusqu'à la fin de la
## remontée : la transition dessine son décor sous la surface, ce qui évite toute coupure.

enum Etat { ILE, DESCENTE, PLONGEE, REMONTEE }

const SCENE_PLONGEE := preload("res://scenes/dive.tscn")
var etat := Etat.ILE
var temps_plongee := 0.0

var _plongee: Node2D = null
var _gardees: Dictionary = {}
var _perdues: Dictionary = {}
var _urgence := false

@onready var _ile: Ile = $Ile
@onready var _transition: Transition = $Transition
@onready var _conteneur: Node2D = $Plongee


func _ready() -> void:
	_ile.plongee_demandee.connect(_lancer_descente)
	_transition.terminee.connect(_fin_transition)


func _process(delta: float) -> void:
	if etat == Etat.PLONGEE:
		temps_plongee += delta


func plongee() -> Node2D:
	return _plongee


func _lancer_descente() -> void:
	if etat != Etat.ILE:
		return
	etat = Etat.DESCENTE
	_ile.preparer_depart()
	_plongee = SCENE_PLONGEE.instantiate()
	_plongee.retour_ile.connect(_sur_retour_ile)
	_figer_plongee(true)
	_conteneur.add_child(_plongee)
	_transition.lancer(true, _ile, _plongee)


func _fin_transition() -> void:
	if etat == Etat.DESCENTE:
		_ile.visible = false
		_figer_plongee(false)
		temps_plongee = 0.0
		etat = Etat.PLONGEE
	elif etat == Etat.REMONTEE:
		_conteneur.remove_child(_plongee)
		_plongee.queue_free()
		_plongee = null
		etat = Etat.ILE
		_ile.arriver(temps_plongee, _gardees, _perdues, _urgence)


func _sur_retour_ile(gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
	_gardees = gardees
	_perdues = perdues
	_urgence = urgence
	# Différé : le signal est émis depuis le _physics_process de la plongée.
	_lancer_remontee.call_deferred()


func _lancer_remontee() -> void:
	_figer_plongee(true)
	etat = Etat.REMONTEE
	_ile.visible = true
	_transition.lancer(false, _ile, _plongee, _plongee.cloche_position(), _plongee.haut_camera())


## Plongée figée et cachée (pendant les transitions) ou active et visible.
func _figer_plongee(figee: bool) -> void:
	_plongee.process_mode = Node.PROCESS_MODE_DISABLED if figee else Node.PROCESS_MODE_INHERIT
	_plongee.visible = not figee
	(_plongee.get_node("HUD") as CanvasLayer).visible = not figee
