class_name VueMonde
extends Node2D
## Rendu du monde en 320x180, affiché ×2 sous l'interface (qui reste en 640x360).
## La logique du jeu garde ses positions en 640x360 : au dessin, on les divise par 2 et on les
## arrondit au pixel du monde (vers_monde), donc tous les pixels du monde ont la même taille.
##
## Fluidité :
## - un objet du monde avance toujours par pas d'un pixel entier du monde (pas de demi-pixel) ;
##   les objets lents avancent à cadence fixe, calée sur la physique à 60 Hz (voir SourceRessource) ;
## - le défilement (caméra, transition) est lissé : l'image entière du monde peut être décalée
##   d'un pixel d'écran (un demi-pixel du monde) sans déformer aucun pixel. La vue est rendue avec
##   un pixel de marge pour couvrir ce décalage.

const ECHELLE := 2
const TAILLE := Vector2i(320, 180)

## Fonction de dessin du monde : Callable(toile: Node2D), en coordonnées du monde (320x180).
var dessiner: Callable
## Coin haut-gauche de la vue, en coordonnées 640x360 (0 pour une vue fixe).
var camera := Vector2.ZERO

var _vue := SubViewport.new()
var _toile := Node2D.new()


func _ready() -> void:
	_vue.size = TAILLE + Vector2i.ONE
	_vue.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vue.snap_2d_transforms_to_pixel = true
	_vue.snap_2d_vertices_to_pixel = true
	_vue.disable_3d = true
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	Pixel.activer_motifs(_toile)
	_toile.draw.connect(func() -> void:
		if dessiner.is_valid():
			dessiner.call(_toile))
	_vue.add_child(_toile)
	add_child(_vue)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta: float) -> void:
	_toile.position = -(camera / ECHELLE).floor()
	_toile.queue_redraw()
	queue_redraw()


func _draw() -> void:
	# Reste du défilement plus fin qu'un pixel du monde : 0 ou 1 pixel d'écran. La marge d'un pixel
	# du monde n'est affichée que si ce reste l'exige.
	var reste := (camera - (camera / ECHELLE).floor() * ECHELLE).round()
	var source := Rect2(Vector2.ZERO, Vector2(TAILLE) + Vector2(signf(reste.x), signf(reste.y)))
	draw_texture_rect_region(_vue.get_texture(), Rect2(-reste, source.size * ECHELLE), source)


func taille_monde() -> Vector2i:
	return TAILLE


## Position 640x360 -> pixel entier du monde 320x180.
static func vers_monde(point: Vector2) -> Vector2:
	return (point / ECHELLE).floor()
