class_name Cloche
extends CharacterBody2D
## La cloche de plongée : déplacement avec inertie et flottabilité douce.
## Les ordres viennent de dive.gd (contrôle actif ou remontée automatique).

# Réglages de déplacement (pixels et secondes)
const VITESSE_MAX := 110.0            # vitesse de plongée / de déplacement voulue par le joueur
const VITESSE_REMONTEE_AUTO := 90.0   # vitesse quand l'oxygène est vide
const VITESSE_FLOTTAISON := 14.0      # montée lente quand on ne touche à rien
const ACCELERATION := 260.0           # plus c'est petit, plus la cloche « glisse »
const FREINAGE := 120.0               # décélération quand on lâche les touches

# Limites de la zone
const DEMI_LARGEUR_ZONE := 280.0
const PROFONDEUR_MAX_PX := 3000.0

# Dessin : sprite pixel art de 20x22 px (une lettre = une couleur de la palette, « . » = transparent)
const LARGEUR := 20.0
const HAUTEUR := 22.0
const MOTIF: PackedStringArray = [
	"........oooo........",
	"......ooOOOOoo......",
	".....oOjjOOOOOo.....",
	"....oOjjOOOOOOOo....",
	"....oOjOOOOOOOOo....",
	"...oOjOOOaaaaOOOo...",
	"...oOjOOaCCccaOOo...",
	"...oOjOOaCcccaOOo...",
	"...oOjOOaccccaOOo...",
	"...oOjOOOaaaaOOOo...",
	"...oOOOOOOOOOOOOo...",
	"..ooOOOOOOOOOOOOoo..",
	"..oaaaaaaaaaaaaaao..",
	"..oajajajajajajaao..",
	"..oaaaaaaaaaaaaaao..",
	".ooOOOOOOOOOOOOOOoo.",
	".oOjOOOOOOOOOOOOOOo.",
	".oOOOOOOOOOOOOOOOOo.",
	"oOOOOOOOOOOOOOOOOOOo",
	"oooooooooooooooooooo",
	".aaaaaaaaaaaaaaaaaa.",
	"....................",
]
const COULEURS_MOTIF := {
	"o": "or_fonce", "O": "or", "j": "or_clair", "a": "ardoise", "c": "cyan", "C": "cyan_clair",
}

var controle_actif := true
var remontee_auto := false
## Vrai pendant le minage : la flottabilité est suspendue pour rester devant le gisement.
var stabilisee := false


func _physics_process(delta: float) -> void:
	var cible := Vector2.ZERO
	var acceleration := FREINAGE
	if remontee_auto:
		cible = Vector2(0.0, -VITESSE_REMONTEE_AUTO)
		acceleration = ACCELERATION
	elif controle_actif:
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		cible = direction * VITESSE_MAX
		if is_zero_approx(direction.y):
			cible.y = 0.0 if stabilisee else -VITESSE_FLOTTAISON
		if direction != Vector2.ZERO:
			acceleration = ACCELERATION
	velocity = velocity.move_toward(cible, acceleration * delta)
	move_and_slide()

	position.x = clampf(position.x, -DEMI_LARGEUR_ZONE, DEMI_LARGEUR_ZONE)
	if position.y < 0.0 or position.y > PROFONDEUR_MAX_PX:
		position.y = clampf(position.y, 0.0, PROFONDEUR_MAX_PX)
		velocity.y = 0.0


func _draw() -> void:
	Cloche.dessiner(self, Vector2.ZERO)


## Dessin de la cloche, réutilisé par l'île et la transition.
static func dessiner(toile: CanvasItem, centre: Vector2) -> void:
	Pixel.sprite(toile, Pixel.motif(MOTIF, COULEURS_MOTIF), centre)
