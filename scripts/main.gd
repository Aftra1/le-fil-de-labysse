extends Node2D
## Scène de test de l'étape 0 : tout est dessiné en code.

const LARGEUR := 640.0
const HAUTEUR := 360.0
const HAUTEUR_CIEL := 150.0
const TAILLE_CARRE := 8.0
const VITESSE := 80.0

const COULEUR_CIEL := Color("a8d8f0")
const COULEUR_ABYSSE := Color("0b1530")
const COULEUR_OR := Color("e8b923")

var _position := Vector2(LARGEUR / 2.0, HAUTEUR_CIEL - TAILLE_CARRE)


func _ready() -> void:
	var etiquette := Label.new()
	etiquette.text = "étape 0 OK"
	etiquette.position = Vector2(8, 8)
	etiquette.add_theme_color_override("font_color", Color("0b1530"))
	add_child(etiquette)


func _process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_position += direction * VITESSE * delta
	_position = _position.clamp(Vector2.ZERO, Vector2(LARGEUR - TAILLE_CARRE, HAUTEUR - TAILLE_CARRE))
	queue_redraw()
	if Input.is_action_just_pressed("pause"):
		get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, LARGEUR, HAUTEUR_CIEL), COULEUR_CIEL)
	draw_rect(Rect2(0, HAUTEUR_CIEL, LARGEUR, HAUTEUR - HAUTEUR_CIEL), COULEUR_ABYSSE)
	draw_rect(Rect2(_position.round(), Vector2(TAILLE_CARRE, TAILLE_CARRE)), COULEUR_OR)
