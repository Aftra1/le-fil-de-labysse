extends Node2D
## Plongée : décor par zones, câble, oxygène, minage, sac et règles de remontée.
## Pas de game over : à 0 d'oxygène, la cloche remonte toute seule et une partie du butin est perdue.

# Monde (pixels)
const SURFACE_Y := 0.0
const PROFONDEUR_MAX := 3000.0
const PIXELS_PAR_METRE := 10.0
const LARGEUR_DECOR := 2000.0
const HAUTEUR_CIEL := 400.0
const HAUTEUR_BANDE := 30.0     # le dégradé de l'eau est dessiné par bandes
const MARGE_CAMERA_HAUT := 90.0 # ciel visible au-dessus de l'eau quand on est en surface
const MARGE_CAMERA_BAS := 60.0

# Oxygène (la consommation est multipliée par le réglage « conso_oxygene » de la zone)
const OXYGENE_MAX := 100.0
const CONSOMMATION_PAR_S := 1.2
const RECHARGE_PAR_S := 25.0
const SEUIL_SURFACE := 6.0      # au-dessus de cette profondeur (px), on respire à l'air libre

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
const EPAISSEUR_CABLE := 2.0

# Couleurs
const COULEUR_CIEL := Color("cfe9f7")
const COULEUR_SURFACE := Color("ffffff")
const COULEUR_REPERE := Color(1.0, 1.0, 1.0, 0.25)
const COULEUR_CABLE := Color("d8dde6")

var oxygene := OXYGENE_MAX

var _temps := 0.0
var _zones: Array = []
var _minerais: Dictionary = {}
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
	_hasard.randomize()
	_zones = Donnees.charger_json("res://data/zones.json")
	_minerais = Donnees.charger_json("res://data/minerais.json")
	_camera.limit_top = int(-MARGE_CAMERA_HAUT)
	_camera.limit_bottom = int(PROFONDEUR_MAX + MARGE_CAMERA_BAS)
	_camera.position = Vector2(0.0, _cloche.position.y)
	_generer_gisements()
	_rafraichir_sac()
	_interface.definir_stock(_texte_butin("Île : ", Game.stock_ile))


func _physics_process(delta: float) -> void:
	var zone := _zone_a(_profondeur_m())
	var sous_leau := _cloche.position.y > SURFACE_Y + SEUIL_SURFACE

	if sous_leau:
		oxygene = maxf(oxygene - CONSOMMATION_PAR_S * float(zone["conso_oxygene"]) * delta, 0.0)
	else:
		oxygene = minf(oxygene + RECHARGE_PAR_S * delta, OXYGENE_MAX)

	if oxygene <= 0.0:
		_cloche.remontee_auto = true
	if _sous_leau_avant and not sous_leau:
		_arriver_en_surface()
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

func _arriver_en_surface() -> void:
	var urgence := _cloche.remontee_auto
	var perdues := {}
	if urgence:
		perdues = _sac.perdre(PERTE_REMONTEE_AUTO, _hasard)
	var gardees := _sac.vider()
	Game.deposer_butin(gardees)

	var nb_perdues := _total(perdues)
	var nb_gardees := _total(gardees)
	if urgence and nb_perdues > 0:
		_interface.annoncer("Tu as perdu %s ! %s." % [_unites(nb_perdues), _sauvees(nb_gardees)])
	elif urgence and nb_gardees > 0:
		_interface.annoncer("Remontée d'urgence : rien de perdu, %s." % _sauvees(nb_gardees))
	elif nb_gardees > 0:
		_interface.annoncer("Butin rangé : %s." % _unites(nb_gardees))

	_interface.definir_stock(_texte_butin("Île : ", Game.stock_ile))
	_generer_gisements()
	_rafraichir_sac()


func _total(butin: Dictionary) -> int:
	var total := 0
	for minerai: String in butin:
		total += int(butin[minerai])
	return total


func _unites(nombre: int) -> String:
	return "%d unité" % nombre if nombre <= 1 else "%d unités" % nombre


func _sauvees(nombre: int) -> String:
	return "%d sauvée" % nombre if nombre <= 1 else "%d sauvées" % nombre


func _texte_butin(prefixe: String, butin: Dictionary) -> String:
	if butin.is_empty():
		return prefixe + "—"
	var morceaux: PackedStringArray = []
	for minerai: String in butin:
		morceaux.append("%s ×%d" % [_minerais[minerai]["nom"], int(butin[minerai])])
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
				donnees,
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
	var gauche := -LARGEUR_DECOR / 2.0
	draw_rect(Rect2(gauche, SURFACE_Y - HAUTEUR_CIEL, LARGEUR_DECOR, HAUTEUR_CIEL), COULEUR_CIEL)

	var y := SURFACE_Y
	while y < SURFACE_Y + PROFONDEUR_MAX + MARGE_CAMERA_BAS + 200.0:
		var profondeur_m := (y + HAUTEUR_BANDE / 2.0 - SURFACE_Y) / PIXELS_PAR_METRE
		var zone := _zone_a(profondeur_m)
		var debut := float(zone["debut_m"])
		var t := clampf((profondeur_m - debut) / (float(zone["fin_m"]) - debut), 0.0, 1.0)
		var couleur := Color.html(str(zone["couleur_haut"])).lerp(Color.html(str(zone["couleur_bas"])), t)
		draw_rect(Rect2(gauche, y, LARGEUR_DECOR, HAUTEUR_BANDE + 1.0), couleur)
		y += HAUTEUR_BANDE

	draw_line(Vector2(gauche, SURFACE_Y), Vector2(-gauche, SURFACE_Y), COULEUR_SURFACE, 2.0)

	# Repères de profondeur tous les 10 m
	var repere := SURFACE_Y + PIXELS_PAR_METRE * 10.0
	while repere <= SURFACE_Y + PROFONDEUR_MAX:
		draw_line(Vector2(-300.0, repere), Vector2(-280.0, repere), COULEUR_REPERE, 1.0)
		draw_line(Vector2(280.0, repere), Vector2(300.0, repere), COULEUR_REPERE, 1.0)
		repere += PIXELS_PAR_METRE * 10.0

	_dessiner_cable()


func _dessiner_cable() -> void:
	var debut := Vector2(0.0, SURFACE_Y)
	var fin: Vector2 = _cloche.position - Vector2(0.0, 13.0)
	var points := PackedVector2Array()
	for i in SEGMENTS_CABLE + 1:
		var t := float(i) / SEGMENTS_CABLE
		var point := debut.lerp(fin, t)
		point.x += sin(t * PI) * ONDULATION_CABLE * sin(_temps * 1.5 + t * 4.0)
		points.append(point)
	draw_polyline(points, COULEUR_CABLE, EPAISSEUR_CABLE)
