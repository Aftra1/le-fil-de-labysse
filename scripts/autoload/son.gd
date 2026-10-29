extends Node
## Autoload « Son » : ambiances et effets sonores, tous synthétisés en code au démarrage (Synthe).
##
## Deux bus sous « Master » : « Musique » (ambiances) et « Effets ». Un limiteur sur Master évite toute
## saturation. Les volumes (0 à 1, par pas de 10 %) se règlent dans le menu pause et sont enregistrés
## dans la sauvegarde (champ « reglages »).
##
## Mixage pensé pour de longues sessions : chaque effet a son niveau, un délai minimal avant de pouvoir
## rejouer (pas de mitraillage) et une légère variation de hauteur ; les ambiances passent de l'une à
## l'autre par un fondu enchaîné.
## Le nœud tourne aussi quand le jeu est en pause (l'ambiance continue sous le menu).
## Sans pilote audio (tests, serveur), tout fonctionne de la même façon, en silence.

const BUS_MUSIQUE := "Musique"
const BUS_EFFETS := "Effets"
const VOLUME_DEFAUT := {"musique": 0.7, "effets": 0.8}
const FONDU_S := 2.5
const LECTEURS_EFFETS := 8
const VARIATION_HAUTEUR := 0.04

## Niveau (dB) et délai minimal entre deux lectures (s) de chaque effet.
const REGLAGES_EFFETS := {
	"clic": [-14.0, 0.04], "nuage": [-8.0, 0.08], "vent": [-8.0, 0.2], "cristal": [-10.0, 0.15],
	"bassin": [-9.0, 0.15], "minage": [-14.0, 0.2], "unite": [-8.0, 0.1], "sac_plein": [-6.0, 1.0],
	"oxygene_bas": [-12.0, 1.2], "craquement": [-6.0, 2.5], "remontee_auto": [-6.0, 2.0],
	"fabrication": [-7.0, 0.2], "installation": [-6.0, 0.3], "construction": [-6.0, 0.3], "souffle": [-9.0, 1.0],
	"machine": [-9.0, 0.15], "foreuse": [-9.0, 0.15], "fourneau": [-9.0, 0.2],
	"sonde": [-9.0, 0.15], "trouvaille": [-6.0, 1.0],
}

var volume_musique: float = VOLUME_DEFAUT["musique"]
var volume_effets: float = VOLUME_DEFAUT["effets"]
## Ambiance en cours (« ile », « lagon », « coraux », « faille » ou vide).
var ambiance_actuelle := ""
## Derniers effets joués (le plus récent à la fin), pour les tests.
var historique: Array[String] = []

var _effets: Dictionary = {}
var _ambiances: Dictionary = {}
var _lecteurs: Array[AudioStreamPlayer] = []
var _prochain_lecteur := 0
var _dernier_jeu: Dictionary = {}      # id -> temps (s) de la dernière lecture
var _musique_a: AudioStreamPlayer
var _musique_b: AudioStreamPlayer
var _fondu: Tween
var _hasard := RandomNumberGenerator.new()
var _temps := 0.0                      # temps de jeu écoulé (s), pause comprise


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hasard.randomize()
	_creer_bus()
	_effets = Synthe.effets()
	_ambiances = Synthe.ambiances()
	for i in LECTEURS_EFFETS:
		var lecteur := AudioStreamPlayer.new()
		lecteur.bus = BUS_EFFETS
		add_child(lecteur)
		_lecteurs.append(lecteur)
	_musique_a = _lecteur_musique()
	_musique_b = _lecteur_musique()
	appliquer_volumes()
	get_tree().node_added.connect(_sur_noeud_ajoute)


func _process(delta: float) -> void:
	_temps += delta


## Coupe tous les sons (avant de quitter : le serveur audio relâche les lectures arrêtées au mixage
## suivant, il faut donc arrêter quelques images avant la fermeture pour ne rien laisser derrière).
func arreter() -> void:
	if _fondu != null and _fondu.is_valid():
		_fondu.kill()
	for lecteur in _lecteurs + [_musique_a, _musique_b]:
		lecteur.stop()
	ambiance_actuelle = ""


## Fermeture : on libère les sons générés.
func _exit_tree() -> void:
	arreter()
	for lecteur in _lecteurs + [_musique_a, _musique_b]:
		lecteur.stream = null
	_effets.clear()
	_ambiances.clear()
	Synthe.liberer()


func _lecteur_musique() -> AudioStreamPlayer:
	var lecteur := AudioStreamPlayer.new()
	lecteur.bus = BUS_MUSIQUE
	lecteur.volume_db = -80.0
	add_child(lecteur)
	return lecteur


func _creer_bus() -> void:
	for nom: String in [BUS_MUSIQUE, BUS_EFFETS]:
		if AudioServer.get_bus_index(nom) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, nom)
		AudioServer.set_bus_send(index, "Master")
	var master := AudioServer.get_bus_index("Master")
	var a_limiteur := false
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) is AudioEffectHardLimiter:
			a_limiteur = true
	if not a_limiteur:
		var limiteur := AudioEffectHardLimiter.new()
		limiteur.ceiling_db = -1.0
		AudioServer.add_bus_effect(master, limiteur)


# --- Effets ----------------------------------------------------------------------------

## Joue un effet (ignoré s'il vient d'être joué : voir REGLAGES_EFFETS) ; hauteur : 1 = normale.
## Renvoie vrai si l'effet a été lancé.
func jouer(id: String, hauteur: float = 1.0) -> bool:
	if not _effets.has(id):
		push_warning("Effet sonore inconnu : %s" % id)
		return false
	var reglage: Array = REGLAGES_EFFETS.get(id, [-8.0, 0.1])
	var maintenant := _temps
	if maintenant - float(_dernier_jeu.get(id, -100.0)) < float(reglage[1]):
		return false
	_dernier_jeu[id] = maintenant
	var lecteur := _lecteurs[_prochain_lecteur]
	_prochain_lecteur = (_prochain_lecteur + 1) % _lecteurs.size()
	lecteur.stream = _effets[id]
	lecteur.volume_db = float(reglage[0])
	lecteur.pitch_scale = hauteur * (1.0 + _hasard.randf_range(-VARIATION_HAUTEUR, VARIATION_HAUTEUR))
	lecteur.play()
	historique.append(id)
	if historique.size() > 64:
		historique.remove_at(0)
	return true


func a_joue(id: String) -> bool:
	return historique.has(id)


func vider_historique() -> void:
	historique.clear()
	_dernier_jeu.clear()


## Tous les boutons de l'interface font un petit clic.
func _sur_noeud_ajoute(noeud: Node) -> void:
	if noeud is BaseButton:
		(noeud as BaseButton).pressed.connect(func() -> void: jouer("clic"))


# --- Ambiances -------------------------------------------------------------------------

## Passe à l'ambiance « id » par un fondu enchaîné de « duree » secondes (rien si elle joue déjà).
func ambiance(id: String, duree: float = FONDU_S) -> void:
	if id == ambiance_actuelle or not _ambiances.has(id):
		return
	ambiance_actuelle = id
	# Le lecteur silencieux prend la nouvelle ambiance ; l'autre s'éteint.
	var entrant := _musique_b if _musique_a.playing and _musique_a.volume_db > -40.0 else _musique_a
	var sortant := _musique_a if entrant == _musique_b else _musique_b
	entrant.stream = _ambiances[id]
	entrant.volume_db = -60.0
	entrant.play()
	if _fondu != null and _fondu.is_valid():
		_fondu.kill()
	_fondu = create_tween().set_parallel(true)
	_fondu.tween_property(entrant, "volume_db", 0.0, maxf(duree, 0.01)).set_trans(Tween.TRANS_SINE)
	_fondu.tween_property(sortant, "volume_db", -60.0, maxf(duree, 0.01)).set_trans(Tween.TRANS_SINE)
	_fondu.chain().tween_callback(sortant.stop)


## Lecteur d'ambiance au premier plan (tests).
func lecteur_ambiance() -> AudioStreamPlayer:
	return _musique_a if _musique_a.volume_db >= _musique_b.volume_db else _musique_b


# --- Volumes et sauvegarde -------------------------------------------------------------

func regler_volumes(musique: float, effets: float) -> void:
	volume_musique = snappedf(clampf(musique, 0.0, 1.0), 0.1)
	volume_effets = snappedf(clampf(effets, 0.0, 1.0), 0.1)
	appliquer_volumes()


func appliquer_volumes() -> void:
	_regler_bus(BUS_MUSIQUE, volume_musique)
	_regler_bus(BUS_EFFETS, volume_effets)


func _regler_bus(nom: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(nom)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


## Réglages enregistrés dans la sauvegarde.
func reglages() -> Dictionary:
	return {"musique": volume_musique, "effets": volume_effets}


## Reprend des réglages sauvegardés ; une valeur absente ou fausse garde la valeur par défaut.
func charger_reglages(donnees: Dictionary) -> void:
	var musique = donnees.get("musique", VOLUME_DEFAUT["musique"])
	var effets = donnees.get("effets", VOLUME_DEFAUT["effets"])
	regler_volumes(float(musique) if (musique is float or musique is int) else VOLUME_DEFAUT["musique"],
		float(effets) if (effets is float or effets is int) else VOLUME_DEFAUT["effets"])
