extends Node2D
## Scène principale : enchaîne l'île, la transition et la plongée.
## L'île reste en mémoire pendant la plongée (figée et cachée) ; à son retour,
## elle rattrape la recharge correspondant au temps passé sous l'eau.

enum Etat { ILE, DESCENTE, PLONGEE, REMONTEE }

const SCENE_PLONGEE := preload("res://scenes/dive.tscn")
const CENTRE_X := 320.0  # x écran du point x = 0 de la plongée (caméra centrée)

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
	_transition.lancer(true, _ile)


func _fin_transition() -> void:
	if etat == Etat.DESCENTE:
		_ile.visible = false
		_plongee = SCENE_PLONGEE.instantiate()
		_plongee.retour_ile.connect(_sur_retour_ile)
		_conteneur.add_child(_plongee)
		temps_plongee = 0.0
		etat = Etat.PLONGEE
	elif etat == Etat.REMONTEE:
		etat = Etat.ILE
		_ile.arriver(temps_plongee, _gardees, _perdues, _urgence)


func _sur_retour_ile(gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
	_gardees = gardees
	_perdues = perdues
	_urgence = urgence
	# Différé : le signal est émis depuis le _physics_process de la plongée.
	_lancer_remontee.call_deferred()


func _lancer_remontee() -> void:
	var x_cloche := CENTRE_X + (_plongee.get_node("Bell") as Node2D).position.x
	_conteneur.remove_child(_plongee)
	_plongee.queue_free()
	_plongee = null
	etat = Etat.REMONTEE
	_ile.visible = true
	_transition.lancer(false, _ile, x_cloche)
