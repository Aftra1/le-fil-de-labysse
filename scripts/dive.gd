extends Node2D
## Plongée : décor par zones, câble, oxygène, minage, sac et règles de remontée.
## Pas de game over : à 0 d'oxygène, la cloche remonte toute seule et une partie du butin est perdue.
## Quand la cloche revient en surface après être descendue sous PROFONDEUR_ARMEMENT_M,
## la plongée est terminée : on émet retour_ile et la scène Jeu lance la remontée vers l'île.

## gardees / perdues : { id: nombre } ; urgence : vrai après une remontée automatique.
signal retour_ile(gardees: Dictionary, perdues: Dictionary, urgence: bool)

# Monde (pixels)
const SURFACE_Y := 0.0
const PROFONDEUR_MAX := 3000.0
const PIXELS_PAR_METRE := 10.0
const LARGEUR_DECOR := 2000.0
const HAUTEUR_CIEL := 400.0
const MARGE_CAMERA_HAUT := 90.0 # ciel visible au-dessus de l'eau quand on est en surface
const MARGE_CAMERA_BAS := 60.0

# Oxygène (la consommation est multipliée par le réglage « conso_oxygene » de la zone)
const OXYGENE_MAX := 100.0
const CONSOMMATION_PAR_S := 1.2
const RECHARGE_PAR_S := 25.0
const SEUIL_SURFACE := 6.0      # au-dessus de cette profondeur (px), on respire à l'air libre

# Retour à l'île : seulement si la cloche est d'abord descendue sous cette profondeur
const PROFONDEUR_ARMEMENT_M := 10.0

# Minage et perte de butin
const PORTEE_MINAGE := 28.0
const PERTE_REMONTEE_AUTO := 0.4 # part du sac perdue à une remontée automatique

# Placement des gisements (pixels)
const ESPACEMENT_MIN := 40.0
const MARGE_BORD := 24.0
const DISTANCE_MIN_SURFACE := 100.0 # aucun gisement dans les 10 premiers mètres
const MARGE_FOND := 30.0
const ESSAIS_PLACEMENT := 200

# Câble
const SEGMENTS_CABLE := 16
const ONDULATION_CABLE := 6.0

# Dessin (couleurs : noms de la palette)
const DEMI_ECRAN := Vector2(320.0, 180.0)
const LONGUEUR_REPERE := 6.0
const COULEUR_SURFACE := "blanc"
const COULEUR_SOUS_SURFACE := "nacre"
const COULEUR_REPERE := "nacre"
const COULEUR_CABLE := "nacre"

var oxygene := OXYGENE_MAX

var _temps := 0.0
var _zones: Array = []
var _minerais: Dictionary = {}
var _armee := false
var _terminee := false
var _sac := Sac.new()
var _hasard := RandomNumberGenerator.new()
var _sous_leau_avant := false
var _id_zone := ""
var _gisement_mine: Gisement = null
var _progres_minage := 0.0
var _gisement_a_portee: Gisement = null

@onready var _cloche: Cloche = $Bell
@onready var _camera: Camera2D = $Camera
@onready var _interface: Interface = $HUD
@onready var _gisements: Node2D = $Gisements


func _ready() -> void:
	Pixel.activer_motifs(self)
	_hasard.randomize()
	_zones = Donnees.charger_json("res://data/zones.json")
	_minerais = Donnees.charger_json("res://data/minerais.json")
	_camera.limit_top = int(-MARGE_CAMERA_HAUT)
	_camera.limit_bottom = int(PROFONDEUR_MAX + MARGE_CAMERA_BAS)
	_camera.position = Vector2(0.0, _cloche.position.y)
	_generer_gisements()
	_rafraichir_sac()


func _physics_process(delta: float) -> void:
	if _terminee:
		return
	if _profondeur_m() > PROFONDEUR_ARMEMENT_M:
		_armee = true
	var zone := _zone_a(_profondeur_m())
	var sous_leau := _cloche.position.y > SURFACE_Y + SEUIL_SURFACE

	if sous_leau:
		oxygene = maxf(oxygene - CONSOMMATION_PAR_S * float(zone["conso_oxygene"]) * delta, 0.0)
	else:
		oxygene = minf(oxygene + RECHARGE_PAR_S * delta, OXYGENE_MAX)

	if oxygene <= 0.0:
		_cloche.remontee_auto = true
	if _sous_leau_avant and not sous_leau and _armee:
		_terminer_plongee()
		return
	if not sous_leau:
		_cloche.remontee_auto = false
	_sous_leau_avant = sous_leau

	if sous_leau and str(zone["id"]) != _id_zone:
		_id_zone = str(zone["id"])
		_interface.annoncer(str(zone["nom"]))
	elif not sous_leau:
		_id_zone = ""

	_gerer_minage(delta)


func _process(delta: float) -> void:
	_temps += delta
	_camera.position.y = _cloche.position.y
	var zone := _zone_a(_profondeur_m())
	var sous_leau := _cloche.position.y > SURFACE_Y + SEUIL_SURFACE
	_interface.mettre_a_jour(
		oxygene / OXYGENE_MAX,
		_profondeur_m(),
		str(zone["nom"]) if sous_leau else "Surface",
		_message_bas(sous_leau),
	)
	queue_redraw()
	if Input.is_action_just_pressed("pause"):
		get_tree().quit()


func _profondeur_m() -> float:
	return maxf(_cloche.position.y - SURFACE_Y, 0.0) / PIXELS_PAR_METRE


func _zone_a(profondeur_m: float) -> Dictionary:
	for zone: Dictionary in _zones:
		if profondeur_m < float(zone["fin_m"]):
			return zone
	return _zones[_zones.size() - 1]


# --- Minage -----------------------------------------------------------------

func _gerer_minage(delta: float) -> void:
	var cible := _trouver_gisement_a_portee()
	if cible != _gisement_a_portee:
		if is_instance_valid(_gisement_a_portee):
			_gisement_a_portee.en_evidence = false
		_gisement_a_portee = cible
		if cible != null:
			cible.en_evidence = true

	var peut_miner := cible != null and not _cloche.remontee_auto and not _sac.est_plein()
	if peut_miner and Input.is_action_pressed("interact"):
		if cible != _gisement_mine:
			_arreter_minage()
			_gisement_mine = cible
		_cloche.stabilisee = true
		_progres_minage += delta / cible.duree_minage
		cible.progres = minf(_progres_minage, 1.0)
		if _progres_minage >= 1.0:
			_terminer_unite(cible)
	else:
		_arreter_minage()


func _trouver_gisement_a_portee() -> Gisement:
	var meilleur: Gisement = null
	var meilleure_distance := PORTEE_MINAGE * PORTEE_MINAGE
	for enfant in _gisements.get_children():
		var gisement := enfant as Gisement
		if gisement == null or gisement.is_queued_for_deletion():
			continue
		var distance := gisement.position.distance_squared_to(_cloche.position)
		if distance <= meilleure_distance:
			meilleure_distance = distance
			meilleur = gisement
	return meilleur


## Remet la jauge à zéro : seule l'unité en cours est perdue.
func _arreter_minage() -> void:
	if is_instance_valid(_gisement_mine):
		_gisement_mine.progres = 0.0
	_gisement_mine = null
	_progres_minage = 0.0
	_cloche.stabilisee = false


func _terminer_unite(gisement: Gisement) -> void:
	_sac.ajouter(gisement.minerai)
	gisement.progres = 0.0
	gisement.retirer_unite()
	_progres_minage = 0.0
	if gisement.is_queued_for_deletion():
		_gisement_mine = null
		_gisement_a_portee = null
	_rafraichir_sac()


func _rafraichir_sac() -> void:
	_interface.definir_sac(_texte_butin("Sac %d/%d : " % [_sac.nombre(), Sac.CAPACITE], _sac.compter()))
	for enfant in _gisements.get_children():
		var gisement := enfant as Gisement
		if gisement != null:
			gisement.grise = _sac.est_plein()


func _message_bas(sous_leau: bool) -> String:
	if _cloche.remontee_auto:
		return "Plus d'air… la cloche remonte"
	if sous_leau and _sac.est_plein():
		return "Sac plein : remonte à la surface !"
	if sous_leau and _gisement_a_portee != null:
		return "Maintiens E (ou Espace) pour miner"
	return ""


# --- Retour en surface ------------------------------------------------------

func _terminer_plongee() -> void:
	var urgence := _cloche.remontee_auto
	var perdues := {}
	if urgence:
		perdues = _sac.perdre(PERTE_REMONTEE_AUTO, _hasard)
	var gardees := _sac.vider()
	_terminee = true
	_arreter_minage()
	_cloche.remontee_auto = false
	_cloche.controle_actif = false
	_cloche.velocity = Vector2.ZERO
	_rafraichir_sac()
	retour_ile.emit(gardees, perdues, urgence)


func _total(butin: Dictionary) -> int:
	var total := 0
	for minerai: String in butin:
		total += int(butin[minerai])
	return total


func _texte_butin(prefixe: String, butin: Dictionary) -> String:
	if butin.is_empty():
		return prefixe + "—"
	var morceaux: PackedStringArray = []
	for minerai: String in butin:
		morceaux.append("%s ×%d" % [Game.nom_ressource(minerai), int(butin[minerai])])
	return prefixe + ", ".join(morceaux)


# --- Génération des gisements -----------------------------------------------

func _generer_gisements() -> void:
	_arreter_minage()
	_gisement_a_portee = null
	for enfant in _gisements.get_children():
		enfant.queue_free()

	var positions: Array[Vector2] = []
	for zone: Dictionary in _zones:
		var y_min := maxf(float(zone["debut_m"]) * PIXELS_PAR_METRE, DISTANCE_MIN_SURFACE)
		var y_max := minf(float(zone["fin_m"]) * PIXELS_PAR_METRE, PROFONDEUR_MAX - MARGE_FOND)
		var id_minerai := str(zone["minerai"])
		var donnees: Dictionary = _minerais[id_minerai]
		for i in int(zone["gisements"]):
			var position_gisement := _trouver_emplacement(positions, y_min, y_max)
			if position_gisement == Vector2.INF:
				push_warning("Zone %s : pas assez de place pour tous les gisements." % zone["id"])
				break
			positions.append(position_gisement)
			var gisement := Gisement.new()
			gisement.position = position_gisement
			gisement.configurer(
				id_minerai,
				Game.couleur_ressource(id_minerai),
				float(donnees["duree_minage"]),
				_hasard.randi_range(int(donnees["stock_min"]), int(donnees["stock_max"])),
			)
			_gisements.add_child(gisement)


## Cherche un point libre (espacement minimal) ; renvoie Vector2.INF si on n'en trouve pas.
func _trouver_emplacement(existantes: Array[Vector2], y_min: float, y_max: float) -> Vector2:
	var x_max := Cloche.DEMI_LARGEUR_ZONE - MARGE_BORD
	for essai in ESSAIS_PLACEMENT:
		var candidat := Vector2(_hasard.randf_range(-x_max, x_max), _hasard.randf_range(y_min, y_max))
		var libre := true
		for autre in existantes:
			if candidat.distance_to(autre) < ESPACEMENT_MIN:
				libre = false
				break
		if libre:
			return candidat
	return Vector2.INF


# --- Dessin -----------------------------------------------------------------

func _draw() -> void:
	# On ne dessine que la partie visible (plus une marge), au pixel près.
	var centre := _camera.get_screen_center_position().round()
	var haut := centre.y - DEMI_ECRAN.y - 8.0
	var bas := centre.y + DEMI_ECRAN.y + 8.0
	var gauche := -LARGEUR_DECOR / 2.0

	if haut < SURFACE_Y:
		Pixel.rect(self, Rect2(gauche, haut, LARGEUR_DECOR, SURFACE_Y - haut), Palette.couleur(Decor.CIEL_SURFACE))
	var eau := func(y: float) -> Color:
		return Decor.couleur_eau(_zones, y - SURFACE_Y, PIXELS_PAR_METRE)
	Pixel.bandes(self, gauche, LARGEUR_DECOR, maxf(haut, SURFACE_Y), bas, 0, eau)

	Pixel.rect(self, Rect2(gauche, SURFACE_Y - 1.0, LARGEUR_DECOR, 1.0), Palette.couleur(COULEUR_SURFACE))
	Pixel.rect(self, Rect2(gauche, SURFACE_Y, LARGEUR_DECOR, 1.0), Palette.couleur(COULEUR_SOUS_SURFACE))

	# Repères de profondeur tous les 10 m, sur les bords
	var pas := PIXELS_PAR_METRE * 10.0
	var repere := maxf(ceilf(haut / pas), 1.0) * pas
	while repere <= minf(bas, SURFACE_Y + PROFONDEUR_MAX):
		for x: float in [-300.0, 300.0 - LONGUEUR_REPERE]:
			Pixel.rect(self, Rect2(x, repere, LONGUEUR_REPERE, 1.0), Palette.couleur(COULEUR_REPERE))
		repere += pas

	_dessiner_cable(haut, bas)


## Câble de 1 px entre la surface et le haut de la cloche, légèrement ondulant.
func _dessiner_cable(haut: float, bas: float) -> void:
	var debut := Vector2(0.0, SURFACE_Y)
	var fin: Vector2 = _cloche.position.round() - Vector2(0.0, Cloche.HAUTEUR / 2.0)
	var precedent := debut
	for i in range(1, SEGMENTS_CABLE + 1):
		var t := float(i) / SEGMENTS_CABLE
		var point := debut.lerp(fin, t)
		point.x += sin(t * PI) * ONDULATION_CABLE * sin(_temps * 1.5 + t * 4.0)
		point = point.round()
		if maxf(precedent.y, point.y) >= haut and minf(precedent.y, point.y) <= bas:
			Pixel.ligne(self, precedent, point, Palette.couleur(COULEUR_CABLE))
		precedent = point
