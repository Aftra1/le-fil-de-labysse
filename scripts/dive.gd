extends Node2D
## Plongée : décor par zones, câble, oxygène, minage, sac et règles de remontée.
## Pas de game over : à 0 d'oxygène, la cloche remonte toute seule et une partie du butin est perdue.
## Quand la cloche revient en surface après être descendue sous PROFONDEUR_ARMEMENT_M,
## la plongée est terminée : on émet retour_ile et la scène Jeu lance la remontée vers l'île.
## Rendu : le monde est dessiné en 320x180 (VueMonde, ArtAbysse) ; la logique reste en 640x360.

## gardees / perdues : { id: nombre } ; urgence : vrai après une remontée automatique.
signal retour_ile(gardees: Dictionary, perdues: Dictionary, urgence: bool)

# Monde (pixels)
const SURFACE_Y := 0.0
const PROFONDEUR_MAX := 3000.0
const PIXELS_PAR_METRE := 10.0
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
const LONGUEUR_CABLE_DROIT := 40.0   # pixels du monde : en dessous, le câble ne flotte pas

# Caméra lissée (voir _suivre_camera)
const ECRAN := Vector2(640.0, 360.0)
const LISSAGE_CAMERA := 10.0    # plus c'est grand, plus la caméra rattrape vite la cloche
const COULEUR_CABLE := "metal.3"

var oxygene := OXYGENE_MAX

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
var _monde := VueMonde.new()
var _camera := Vector2.ZERO     # coin haut-gauche de la vue, en 640x360

@onready var _cloche: Cloche = $Bell
@onready var _interface: Interface = $HUD
@onready var _gisements: Node2D = $Gisements


func _ready() -> void:
	_hasard.randomize()
	_zones = Donnees.charger_json("res://data/zones.json")
	_minerais = Donnees.charger_json("res://data/minerais.json")
	# La cloche et les gisements ne se dessinent pas eux-mêmes : tout passe par la vue du monde.
	_cloche.visible = false
	_gisements.visible = false
	_monde.name = "Monde"
	_monde.dessiner = _dessiner_monde
	add_child(_monde)
	move_child(_monde, 0)
	_camera = _cible_camera()
	_monde.camera = _camera
	_generer_gisements()
	_rafraichir_sac()


func _physics_process(delta: float) -> void:
	_suivre_camera(delta)
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


func _process(_delta: float) -> void:
	var zone := _zone_a(_profondeur_m())
	var sous_leau := _cloche.position.y > SURFACE_Y + SEUIL_SURFACE
	_interface.mettre_a_jour(
		oxygene / OXYGENE_MAX,
		_profondeur_m(),
		str(zone["nom"]) if sous_leau else "Surface",
		_message_bas(sous_leau),
	)
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


# --- Caméra -------------------------------------------------------------------------------

## La caméra vise la position *dessinée* de la cloche (arrondie au pixel du monde) et la rattrape en
## douceur. Elle avance au même rythme que la cloche (dans _physics_process), et VueMonde l'arrondit
## au pixel d'écran : le décor glisse d'un pixel d'écran à la fois.
func _cible_camera() -> Vector2:
	var cloche := VueMonde.vers_monde(_cloche.position) * VueMonde.ECHELLE
	var haut := clampf(cloche.y - ECRAN.y / 2.0, -MARGE_CAMERA_HAUT, PROFONDEUR_MAX + MARGE_CAMERA_BAS - ECRAN.y)
	return Vector2(-ECRAN.x / 2.0, haut)


func _suivre_camera(delta: float) -> void:
	var cible := _cible_camera()
	_camera = _camera.lerp(cible, 1.0 - exp(-LISSAGE_CAMERA * delta))
	if _camera.distance_to(cible) < 0.5:
		_camera = cible
	_monde.camera = _camera


# --- Dessin du monde (320x180) --------------------------------------------------------------

func _dessiner_monde(toile: Node2D) -> void:
	dessiner_monde(toile, _monde.vue_monde(), true, true)


## Décor, gisements, câble et cloche dans « vue » (pixels du monde de la plongée). La transition
## l'appelle aussi (sans ciel ni cloche) pour que la surface raccorde sans coupure.
func dessiner_monde(toile: CanvasItem, vue: Rect2, avec_ciel: bool, avec_cloche: bool) -> void:
	var fond := PROFONDEUR_MAX / VueMonde.ECHELLE
	ArtAbysse.dessiner_eau(toile, vue, fond, avec_ciel)
	ArtAbysse.dessiner_reperes(toile, vue, fond)
	for enfant in _gisements.get_children():
		var gisement := enfant as Gisement
		if gisement != null and not gisement.is_queued_for_deletion():
			gisement.dessiner_monde(toile)
	if avec_cloche:
		_dessiner_cable(toile, vue)
		var cloche := VueMonde.vers_monde(_cloche.position)
		Pixel.sprite_ombre(toile, ArtIle.cloche(0.5, ArtAbysse.contour_cloche(cloche.y)), cloche,
			Palette.plus_sombre(ArtAbysse.couleur_fond(cloche)))


## Position de la cloche et haut de la vue (640x360), pour une remontée qui part de cette image.
func cloche_position() -> Vector2:
	return _cloche.position


func haut_camera() -> float:
	return _camera.round().y


## Câble de 1 px : vertical au-dessus de la surface (il monte vers l'île), puis de la surface au haut
## de la cloche, légèrement ondulant.
func _dessiner_cable(toile: CanvasItem, vue: Rect2) -> void:
	if vue.position.y < 0.0:
		toile.draw_rect(Rect2(0, vue.position.y, 1, -vue.position.y), Palette.couleur(COULEUR_CABLE))
	var debut := Vector2.ZERO
	var fin := VueMonde.vers_monde(_cloche.position) - Vector2(0.0, ceilf(ArtIle.cloche(0.5).get_height() / 2.0))
	if debut.distance_to(fin) < LONGUEUR_CABLE_DROIT:
		# Câble court (cloche en surface) : droit, comme le dessine la transition.
		Pixel.ligne(toile, debut, fin, Palette.couleur(COULEUR_CABLE))
		return
	var t := ArtAbysse.temps()
	var precedent := debut
	for i in range(1, SEGMENTS_CABLE + 1):
		var avance := float(i) / SEGMENTS_CABLE
		var point := debut.lerp(fin, avance)
		point.x += sin(avance * PI) * ONDULATION_CABLE / VueMonde.ECHELLE * sin(t * 1.5 + avance * 4.0)
		point = point.round()
		if maxf(precedent.y, point.y) >= vue.position.y and minf(precedent.y, point.y) <= vue.end.y:
			Pixel.ligne(toile, precedent, point, Palette.couleur(COULEUR_CABLE))
		precedent = point
