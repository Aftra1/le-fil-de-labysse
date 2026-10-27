extends Node2D
## Prototype de plongée : décor, câble, oxygène et règles de remontée.
## Pas de game over : à 0 d'oxygène, la cloche remonte toute seule.

# Monde (pixels)
const SURFACE_Y := 0.0
const PROFONDEUR_MAX := 3000.0
const PIXELS_PAR_METRE := 10.0
const LARGEUR_DECOR := 2000.0
const HAUTEUR_CIEL := 400.0
const HAUTEUR_BANDE := 30.0     # le dégradé de l'eau est dessiné par bandes
const MARGE_CAMERA_HAUT := 90.0 # ciel visible au-dessus de l'eau quand on est en surface
const MARGE_CAMERA_BAS := 60.0

# Oxygène
const OXYGENE_MAX := 100.0
const CONSOMMATION_PAR_S := 1.5
const RECHARGE_PAR_S := 25.0
const SEUIL_SURFACE := 6.0      # sous cette profondeur (px), on respire à l'air libre

# Câble
const SEGMENTS_CABLE := 16
const ONDULATION_CABLE := 6.0
const EPAISSEUR_CABLE := 2.0

# Couleurs
const COULEUR_CIEL := Color("cfe9f7")
const COULEUR_EAU_HAUT := Color("5fb4d9")
const COULEUR_EAU_MILIEU := Color("0b1530")
const COULEUR_EAU_FOND := Color("02030a")
const COULEUR_SURFACE := Color("ffffff")
const COULEUR_REPERE := Color(1.0, 1.0, 1.0, 0.25)
const COULEUR_CABLE := Color("d8dde6")

var oxygene := OXYGENE_MAX
var _temps := 0.0

@onready var _cloche: CharacterBody2D = $Bell
@onready var _camera: Camera2D = $Camera
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	_camera.limit_top = int(-MARGE_CAMERA_HAUT)
	_camera.limit_bottom = int(PROFONDEUR_MAX + MARGE_CAMERA_BAS)
	_camera.position = Vector2.ZERO
	_camera.position.y = _cloche.position.y


func _physics_process(delta: float) -> void:
	var sous_leau: bool = _cloche.position.y > SURFACE_Y + SEUIL_SURFACE
	if sous_leau:
		oxygene = maxf(oxygene - CONSOMMATION_PAR_S * delta, 0.0)
	else:
		oxygene = minf(oxygene + RECHARGE_PAR_S * delta, OXYGENE_MAX)

	if oxygene <= 0.0:
		_cloche.set("remontee_auto", true)
	elif not sous_leau:
		_cloche.set("remontee_auto", false)


func _process(delta: float) -> void:
	_temps += delta
	_camera.position.y = _cloche.position.y
	_hud.call(
		"mettre_a_jour",
		oxygene / OXYGENE_MAX,
		maxf(_cloche.position.y - SURFACE_Y, 0.0) / PIXELS_PAR_METRE,
		_cloche.get("remontee_auto"),
	)
	queue_redraw()
	if Input.is_action_just_pressed("pause"):
		get_tree().quit()


func _draw() -> void:
	var gauche := -LARGEUR_DECOR / 2.0
	draw_rect(Rect2(gauche, SURFACE_Y - HAUTEUR_CIEL, LARGEUR_DECOR, HAUTEUR_CIEL), COULEUR_CIEL)

	var y := SURFACE_Y
	while y < SURFACE_Y + PROFONDEUR_MAX + MARGE_CAMERA_BAS + 200.0:
		var t := clampf((y - SURFACE_Y) / PROFONDEUR_MAX, 0.0, 1.0)
		var couleur: Color
		if t < 0.5:
			couleur = COULEUR_EAU_HAUT.lerp(COULEUR_EAU_MILIEU, t * 2.0)
		else:
			couleur = COULEUR_EAU_MILIEU.lerp(COULEUR_EAU_FOND, (t - 0.5) * 2.0)
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
