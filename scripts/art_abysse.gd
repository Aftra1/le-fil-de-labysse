class_name ArtAbysse
extends RefCounted
## Pixel art de l'abysse (plongée), dessiné dans le monde 320x180 (voir VueMonde).
## Repère : pixels du monde de la plongée, x = 0 au centre, y = 0 à la surface de la mer.
## L'eau, les reflets, les particules et la surface sont des fonctions du lieu et d'une horloge
## commune (images de physique) : la transition peut redessiner exactement la même image.
## Contour bleu nuit (« contour_bas »), ombres portées d'un ton plus sombre que l'eau derrière.

const CONTOUR := "contour_bas"
const PX_PAR_METRE := 5.0         # pixels du monde par mètre (10 en 640x360)
const PROFONDEUR_REFLETS := 140   # les reflets de lumière s'éteignent avec la profondeur
const VAGUES := [0, 1, 2, 2, 1, 0, 0, 0]
const CELLULE_PARTICULES := 16
const CELLULE_REFLETS := Vector2i(12, 6)
const DECALAGE_COLONNE := Vector2i(160, 900)   # pixel (0, 0) de la plongée dans la colonne du ciel

const CRISTAL: PackedStringArray = [
	"...3...",
	"..332..",
	"3.3321.",
	"3232211",
	"3222111",
	".211110",
	"..0000.",
]
const CORAIL: PackedStringArray = [
	".4...4.",
	".3.4.3.",
	"43.3.34",
	".33333.",
	"..232..",
	"...2...",
	"..101..",
]

# Obscurité : rien jusqu'à DEBUT_OBSCURITE_M, puis un ton de plus tous les PAS_OBSCURITE_M (3 au plus),
# limité par la lanterne. Autour de la cloche, un halo en anneaux de ANNEAU_HALO pixels du monde.
const DEBUT_OBSCURITE_M := 40.0
const PAS_OBSCURITE_M := 40.0
const ANNEAU_HALO := 10.0
const LUEURS := ["cyan.3", "corail.4"]   # bioluminescence et éclats : jamais assombris

## Horloge figée (vérification du raccord entre transition et plongée).
static var figer_temps := false
static var _etapes: Array = []    # [profondeur en px du monde, couleur], de la surface vers le fond
static var _cache: Dictionary = {}


static func c(nom: String) -> Color:
	return Palette.couleur(nom)


static func temps() -> float:
	return 0.0 if figer_temps else Engine.get_physics_frames() / 60.0


# --- Eau ---------------------------------------------------------------------------------

## Couleur de l'eau à une profondeur (px du monde sous la surface), paliers des zones (data/zones.json).
static func couleur_eau(profondeur: float) -> Color:
	_charger()
	var teinte: Color = _etapes[0][1]
	for etape: Array in _etapes:
		if profondeur >= float(etape[0]):
			teinte = etape[1]
	return teinte


## Couleur de ce qu'il y a derrière un point de la plongée (ciel au-dessus de la surface, eau dessous).
static func couleur_fond(point: Vector2) -> Color:
	if point.y < 0.0:
		return ArtIle.couleur_ciel_monde(point.y + DECALAGE_COLONNE.y)
	return couleur_eau(point.y)


## Contour de la cloche : brun au-dessus de la surface (monde du haut), bleu nuit dessous.
static func contour_cloche(y_plongee: float) -> String:
	return ArtIle.CONTOUR if y_plongee < 0.0 else CONTOUR


## Dessine le décor de la plongée visible dans « zone » (pixels du monde de la plongée) :
## ciel au-dessus de la surface, surface animée, eau en paliers à bords en vagues, reflets, particules.
static func dessiner_eau(toile: CanvasItem, zone: Rect2, profondeur_max: float, avec_ciel: bool = true) -> void:
	_charger()
	var t := temps()
	if avec_ciel and zone.position.y < 0.0:
		var ciel := Rect2(zone.position, Vector2(zone.size.x, minf(-zone.position.y, zone.size.y)))
		ArtIle.dessiner_ciel(toile, ciel, DECALAGE_COLONNE.x, DECALAGE_COLONNE.y)
	var haut := maxf(zone.position.y, 0.0)
	var bas := minf(zone.end.y, profondeur_max + 40.0)
	if bas <= haut:
		return
	# Paliers
	for i in _etapes.size():
		var debut := maxf(float(_etapes[i][0]), haut)
		var fin := bas if i + 1 == _etapes.size() else minf(float(_etapes[i + 1][0]), bas)
		if fin > debut:
			toile.draw_rect(Rect2(zone.position.x, debut, zone.size.x, fin - debut), _etapes[i][1])
	# Bords en vagues : le palier clair du dessus descend dans le palier sombre
	for i in range(1, _etapes.size()):
		var bord := float(_etapes[i][0])
		if bord < haut or bord - 2.0 > bas:
			continue
		var x := floori(zone.position.x / 2.0) * 2
		while x < zone.end.x:
			var hauteur: int = VAGUES[posmod(x / 2, VAGUES.size())]
			if hauteur > 0:
				toile.draw_rect(Rect2(x, bord, 2, hauteur), _etapes[i - 1][1])
			x += 2
	# Reflets de lumière près de la surface (petits traits clairs qui glissent lentement)
	if haut < PROFONDEUR_REFLETS:
		var cy0 := floori(maxf(haut, 2.0) / CELLULE_REFLETS.y)
		for cy in range(cy0, floori(minf(bas, PROFONDEUR_REFLETS) / CELLULE_REFLETS.y) + 1):
			for cx in range(floori(zone.position.x / CELLULE_REFLETS.x) - 1, floori(zone.end.x / CELLULE_REFLETS.x) + 1):
				var tirage := _hasard(cx, cy, 1)
				var y := cy * CELLULE_REFLETS.y + int(_hasard(cx, cy, 2) * CELLULE_REFLETS.y)
				if y < 2 or tirage > 0.32 * (1.0 - float(y) / PROFONDEUR_REFLETS):
					continue
				var glisse := posmod(int(t * (0.6 + _hasard(cx, cy, 3))), CELLULE_REFLETS.x)
				var x := cx * CELLULE_REFLETS.x + int(_hasard(cx, cy, 4) * CELLULE_REFLETS.x) + glisse
				var longueur := 2 + int(_hasard(cx, cy, 5) * 3.0)
				toile.draw_rect(Rect2(x, y, longueur, 1), Palette.plus_clair(couleur_eau(y), 1))
	# Surface : écume et crêtes de vagues
	if haut <= 1.0 and zone.position.y <= 0.0:
		toile.draw_rect(Rect2(zone.position.x, 0, zone.size.x, 1), c("nuage.4"))
		toile.draw_rect(Rect2(zone.position.x, 1, zone.size.x, 1), c("lagon.5"))
		var decalage := int(t * 3.0)
		for x in range(floori(zone.position.x), ceili(zone.end.x)):
			var phase := posmod(x + decalage, 9)
			if phase < 2:
				toile.draw_rect(Rect2(x, -1, 1, 1), c("nuage.4"))
			if phase == 0:
				toile.draw_rect(Rect2(x, -2, 1, 1), c("nuage.3"))
	_dessiner_particules(toile, Rect2(zone.position.x, haut, zone.size.x, bas - haut), t)


## Particules : un point par cellule (ou rien), qui dérive d'un pixel entier à la fois.
## Lagon : poussière claire ; forêt de coraux : bioluminescence cyan et violette.
static func _dessiner_particules(toile: CanvasItem, zone: Rect2, t: float) -> void:
	var n := CELLULE_PARTICULES
	for cy in range(floori(zone.position.y / n) - 1, floori(zone.end.y / n) + 1):
		for cx in range(floori(zone.position.x / n) - 1, floori(zone.end.x / n) + 1):
			if _hasard(cx, cy, 10) > 0.45:
				continue
			var monte := 1.0 + _hasard(cx, cy, 11) * 2.0
			var derive := (_hasard(cx, cy, 12) - 0.5) * 1.2
			var x := cx * n + posmod(int(_hasard(cx, cy, 13) * n + t * derive), n)
			var y := cy * n + posmod(int(_hasard(cx, cy, 14) * n - t * monte), n)
			if y < 3 or not zone.has_point(Vector2(x, y)):
				continue
			var profond := y >= int(_etapes_zone_2())
			var vive := _hasard(cx, cy, 15)
			var teinte := c("lagon.5") if not profond else (c("cyan.3") if vive < 0.5 else c("corail.4"))
			if profond and vive < 0.18:
				# Lueur : un point vif entouré de quatre pixels plus sombres
				var halo := c("cyan.1") if vive < 0.09 else c("corail.2")
				for voisin: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
					toile.draw_rect(Rect2(Vector2(x, y) + voisin, Vector2.ONE), halo)
			toile.draw_rect(Rect2(x, y, 1, 1), teinte)


## Repères de profondeur tous les 10 m sur les bords.
static func dessiner_reperes(toile: CanvasItem, zone: Rect2, profondeur_max: float) -> void:
	var pas := 10.0 * PX_PAR_METRE
	var y := maxf(ceilf(zone.position.y / pas), 1.0) * pas
	while y <= minf(zone.end.y, profondeur_max):
		var teinte := Palette.plus_clair(couleur_eau(y), 2)
		toile.draw_rect(Rect2(-150, y, 3, 1), teinte)
		toile.draw_rect(Rect2(147, y, 3, 1), teinte)
		y += pas


# --- Obscurité et halo -------------------------------------------------------------------------
# La même règle est utilisée par le shader (rendu) et par ces fonctions (tests, vérifications).

## Nombre de tons d'obscurité à une profondeur, sans halo (0 à 3, limité par la lanterne).
static func niveau_obscurite(profondeur_m: float, obscurite_max: int) -> int:
	if profondeur_m < DEBUT_OBSCURITE_M:
		return 0
	return mini(mini(3, 1 + int((profondeur_m - DEBUT_OBSCURITE_M) / PAS_OBSCURITE_M)), obscurite_max)


## Tons retirés par le halo à une distance de la cloche (pixels du monde) : 0 au centre, puis 1, 2, 3.
static func crans_halo(distance: float, rayon: float) -> int:
	if distance < rayon:
		return 0
	if distance < rayon + ANNEAU_HALO:
		return 1
	if distance < rayon + 2.0 * ANNEAU_HALO:
		return 2
	return 3


## Couleur affichée d'un pixel du monde : son ton, assombri dans sa propre rampe.
static func assombrir(teinte: Color, profondeur_m: float, distance: float, rayon: float, obscurite_max: int) -> Color:
	var crans := mini(crans_halo(distance, rayon), niveau_obscurite(profondeur_m, obscurite_max))
	for nom: String in LUEURS:
		if teinte == c(nom):
			return teinte
	return Palette.plus_sombre(teinte, crans) if crans > 0 else teinte


## Matériau d'obscurité de la vue du monde de la plongée (ombre « un ton plus sombre » par pixel).
## Table : ligne k = chaque couleur de la palette assombrie de k tons dans sa rampe.
static func materiau_obscurite() -> ShaderMaterial:
	var noms := Palette.noms()
	var table := Image.create(noms.size(), 4, false, Image.FORMAT_RGBA8)
	for i in noms.size():
		var teinte := c(noms[i])
		for k in 4:
			table.set_pixel(i, k, Palette.plus_sombre(teinte, k))
	var shader := Shader.new()
	shader.code = SHADER_OBSCURITE % [DEBUT_OBSCURITE_M, DEBUT_OBSCURITE_M, PAS_OBSCURITE_M]
	var materiau := ShaderMaterial.new()
	materiau.shader = shader
	materiau.set_shader_parameter("table", ImageTexture.create_from_image(table))
	materiau.set_shader_parameter("nombre", noms.size())
	materiau.set_shader_parameter("anneau", ANNEAU_HALO)
	materiau.set_shader_parameter("px_par_metre", PX_PAR_METRE)
	materiau.set_shader_parameter("lueur_1", c(LUEURS[0]))
	materiau.set_shader_parameter("lueur_2", c(LUEURS[1]))
	return materiau


const SHADER_OBSCURITE := """
shader_type canvas_item;
uniform sampler2D table : filter_nearest, repeat_disable;
uniform int nombre;
uniform vec2 cloche;          // pixel du monde de la cloche, relatif au coin de la vue
uniform float rayon;
uniform float anneau;
uniform float origine_y;      // profondeur (pixels du monde) de la première ligne de la vue
uniform float px_par_metre;
uniform int obscurite_max;
uniform vec4 lueur_1;
uniform vec4 lueur_2;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	float m = (origine_y + texel.y) / px_par_metre;
	int niveau = m < %.1f ? 0 : min(3, 1 + int((m - %.1f) / %.1f));
	niveau = min(niveau, obscurite_max);
	float d = length(texel - cloche);
	int crans = d < rayon ? 0 : (d < rayon + anneau ? 1 : (d < rayon + 2.0 * anneau ? 2 : 3));
	int k = min(crans, niveau);
	COLOR = c;
	if (k > 0 && distance(c.rgb, lueur_1.rgb) > 0.002 && distance(c.rgb, lueur_2.rgb) > 0.002) {
		for (int i = 0; i < nombre; i++) {
			vec4 p = texelFetch(table, ivec2(i, 0), 0);
			if (distance(p.rgb, c.rgb) < 0.002) {
				COLOR = texelFetch(table, ivec2(i, k), 0);
				break;
			}
		}
	}
}
"""


# --- Sprites ---------------------------------------------------------------------------------

static func gisement(minerai: String, grise: bool) -> ImageTexture:
	var dessin := CORAIL if minerai == "corail" else CRISTAL
	var rampe := "metal" if grise else ("corail" if minerai == "corail" else "cyan")
	return Pixel.motif(dessin, ArtIle.couleurs_rampe(rampe), CONTOUR)


## Cadre des panneaux de l'abysse : liseré bleu nuit, métal sombre en relief, lueur cyan, fond nuit.
static func cadre() -> StyleBoxTexture:
	if _cache.has("cadre"):
		return _cache["cadre"]
	var style := ArtIle.style_anneaux([
		[c(CONTOUR), c(CONTOUR)], [c("metal.3"), c("metal.1")], [c("metal.2"), c("metal.2")],
		[c("cyan.1"), c("cyan.1")], [c("abysse.3"), c("abysse.2")],
	], c("abysse.2"))
	_cache["cadre"] = style
	return style


static func vider_cache() -> void:
	_cache.clear()


static func _charger() -> void:
	if not _etapes.is_empty():
		return
	var zones: Array = Donnees.charger_json("res://data/zones.json")
	for zone: Dictionary in zones:
		var paliers: Array = zone["paliers"]
		var debut := float(zone["debut_m"]) * PX_PAR_METRE
		var fin := float(zone["fin_m"]) * PX_PAR_METRE
		for j in paliers.size():
			_etapes.append([roundi(debut + (fin - debut) * j / paliers.size()), c(str(paliers[j]))])


static func _etapes_zone_2() -> float:
	var zones: Array = Donnees.charger_json("res://data/zones.json")
	return float(zones[1]["debut_m"]) * PX_PAR_METRE if zones.size() > 1 else 1e9


## Nombre pseudo-aléatoire stable dans [0, 1) pour une cellule et un usage donnés.
static func _hasard(a: int, b: int, usage: int) -> float:
	var h := a * 73856093 ^ b * 19349663 ^ usage * 83492791
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(posmod(h, 10007)) / 10007.0
