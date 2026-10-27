class_name Pixel
extends RefCounted
## Outils de dessin « pixel art » : tout est dessiné au pixel entier, sans antialiasing.
## Les petites formes (cloche, cristaux, nuages, cercles, jauges, trames) sont des textures
## générées en code (Image) à la taille native, mises en cache, affichées sans filtrage.
## Les nœuds qui dessinent des trames doivent avoir texture_repeat activé (voir activer_motifs).

const PAS_BANDE := 4   # hauteur des bandes de dégradé (px)
const TAILLE_TEXTE := 16  # DotGothic16 n'est nette qu'à sa taille native : un seul corps de texte
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

static var _textures: Dictionary = {}


## À appeler dans _ready des nœuds qui dessinent des trames ou des motifs répétés.
static func activer_motifs(noeud: CanvasItem) -> void:
	noeud.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	noeud.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


# --- Primitives au pixel près -------------------------------------------------

static func rect(toile: CanvasItem, zone: Rect2, couleur: Color) -> void:
	toile.draw_rect(Rect2(zone.position.round(), zone.size.round()), couleur)


## Cadre de 1 px à l'intérieur de la zone.
static func cadre(toile: CanvasItem, zone: Rect2, couleur: Color) -> void:
	var z := Rect2(zone.position.round(), zone.size.round())
	toile.draw_rect(Rect2(z.position, Vector2(z.size.x, 1)), couleur)
	toile.draw_rect(Rect2(z.position + Vector2(0, z.size.y - 1), Vector2(z.size.x, 1)), couleur)
	toile.draw_rect(Rect2(z.position, Vector2(1, z.size.y)), couleur)
	toile.draw_rect(Rect2(z.position + Vector2(z.size.x - 1, 0), Vector2(1, z.size.y)), couleur)


## Ligne de 1 px (algorithme de Bresenham).
static func ligne(toile: CanvasItem, debut: Vector2, fin: Vector2, couleur: Color) -> void:
	var a := Vector2i(debut.round())
	var b := Vector2i(fin.round())
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var erreur := dx + dy
	while true:
		toile.draw_rect(Rect2(a, Vector2.ONE), couleur)
		if a == b:
			break
		var e2 := 2 * erreur
		if e2 >= dy:
			erreur += dy
			a.x += sx
		if e2 <= dx:
			erreur += dx
			a.y += sy


## Dessine une texture centrée, coin haut-gauche arrondi au pixel.
static func sprite(toile: CanvasItem, texture: Texture2D, centre: Vector2) -> void:
	toile.draw_texture(texture, (centre - texture.get_size() / 2.0).floor())


## Dégradé vertical en paliers nets. Chaque changement de palier passe par trois bandes tramées
## (Bayer 25 %, 50 %, 75 %) au lieu d'un fondu lisse.
## palier : Callable(y_monde: float) -> Color ; decalage : y_monde = y_ecran + decalage (entier).
static func bandes(toile: CanvasItem, x: float, largeur: float, y_haut: float, y_bas: float,
		decalage: int, palier: Callable) -> void:
	var y := floori((y_haut + decalage) / float(PAS_BANDE)) * PAS_BANDE - PAS_BANDE * 2
	var fin := y_bas + decalage
	var debut_bloc := y
	var couleur_bloc: Color = palier.call(float(y) + PAS_BANDE / 2.0)
	while y < fin:
		var actuelle: Color = palier.call(float(y) + PAS_BANDE / 2.0)
		var suivante: Color = palier.call(float(y) + PAS_BANDE * 1.5)
		if actuelle != couleur_bloc:
			toile.draw_rect(Rect2(x, debut_bloc - decalage, largeur, y - debut_bloc), couleur_bloc)
			debut_bloc = y
			couleur_bloc = actuelle
		if suivante == actuelle:
			y += PAS_BANDE
			continue
		toile.draw_rect(Rect2(x, debut_bloc - decalage, largeur, y - debut_bloc), couleur_bloc)
		for i in 3:
			var bande := Rect2(x, y + i * PAS_BANDE - decalage, largeur, PAS_BANDE)
			var fond := actuelle if i < 2 else suivante
			var dessus := suivante if i < 2 else actuelle
			toile.draw_rect(bande, fond)
			toile.draw_texture_rect(trame(4 if i != 1 else 8, dessus), bande, true)
		y += PAS_BANDE * 3
		debut_bloc = y
		couleur_bloc = suivante
	toile.draw_rect(Rect2(x, debut_bloc - decalage, largeur, maxf(y - debut_bloc, 0.0)), couleur_bloc)


## Style commun des textes : police pixel (thème du projet), couleur et ombre portée de 1 px.
static func texte(etiquette: Label, couleur: String = "blanc", ombre: String = "nuit") -> void:
	etiquette.add_theme_font_size_override("font_size", TAILLE_TEXTE)
	etiquette.add_theme_color_override("font_color", Palette.couleur(couleur))
	if ombre != "":
		etiquette.add_theme_color_override("font_shadow_color", Palette.couleur(ombre))
		etiquette.add_theme_constant_override("shadow_offset_x", 1)
		etiquette.add_theme_constant_override("shadow_offset_y", 1)
		etiquette.add_theme_constant_override("shadow_outline_size", 0)


# --- Textures générées -----------------------------------------------------------

## Texture à partir d'un dessin en caractères : chaque caractère renvoie à un nom de la palette,
## « . » est transparent.
static func motif(lignes: PackedStringArray, couleurs: Dictionary) -> ImageTexture:
	var cle := "motif:" + "|".join(lignes) + str(couleurs)
	if _textures.has(cle):
		return _textures[cle]
	var image := Image.create(lignes[0].length(), lignes.size(), false, Image.FORMAT_RGBA8)
	for y in lignes.size():
		for x in lignes[y].length():
			var caractere := lignes[y][x]
			if caractere != "." and couleurs.has(caractere):
				image.set_pixel(x, y, Palette.couleur(str(couleurs[caractere])))
	return _memoriser(cle, image)


static func disque(rayon: int, couleur: Color) -> ImageTexture:
	var cle := "disque:%d:%s" % [rayon, couleur.to_html()]
	if _textures.has(cle):
		return _textures[cle]
	var image := _image_carree(rayon)
	for y in rayon * 2 + 1:
		for x in rayon * 2 + 1:
			if Vector2(x - rayon, y - rayon).length() <= rayon + 0.3:
				image.set_pixel(x, y, couleur)
	return _memoriser(cle, image)


## Anneau de 1 px ; pointille : un pixel sur deux (effet de halo tramé).
static func anneau(rayon: int, couleur: Color, pointille: bool = false) -> ImageTexture:
	var cle := "anneau:%d:%s:%s" % [rayon, couleur.to_html(), pointille]
	if _textures.has(cle):
		return _textures[cle]
	var image := _image_carree(rayon)
	for y in rayon * 2 + 1:
		for x in rayon * 2 + 1:
			var d := Vector2(x - rayon, y - rayon).length()
			if d >= rayon - 0.5 and d < rayon + 0.5 and (not pointille or (x + y) % 2 == 0):
				image.set_pixel(x, y, couleur)
	return _memoriser(cle, image)


## Jauge circulaire de 2 px d'épaisseur, remplie dans le sens horaire depuis le haut (24 crans).
static func jauge(rayon: int, progression: float, couleur: Color) -> ImageTexture:
	var crans := clampi(int(progression * 24.0), 0, 24)
	var cle := "jauge:%d:%d:%s" % [rayon, crans, couleur.to_html()]
	if _textures.has(cle):
		return _textures[cle]
	var image := _image_carree(rayon)
	var limite := TAU * crans / 24.0
	for y in rayon * 2 + 1:
		for x in rayon * 2 + 1:
			var v := Vector2(x - rayon, y - rayon)
			var d := v.length()
			if d >= rayon - 1.5 and d < rayon + 0.5:
				var angle := fposmod(atan2(v.x, -v.y), TAU)
				if angle < limite:
					image.set_pixel(x, y, couleur)
	return _memoriser(cle, image)


## Damier 2x2 de deux couleurs (trame à 50 %).
static func damier(a: Color, b: Color) -> ImageTexture:
	var cle := "damier:%s:%s" % [a.to_html(), b.to_html()]
	if _textures.has(cle):
		return _textures[cle]
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, a)
	image.set_pixel(1, 1, a)
	image.set_pixel(1, 0, b)
	image.set_pixel(0, 1, b)
	return _memoriser(cle, image)


## Trame ordonnée (Bayer 4x4) : niveau 0 = transparent, 16 = plein.
static func trame(niveau: int, couleur: Color) -> ImageTexture:
	niveau = clampi(niveau, 0, 16)
	var cle := "trame:%d:%s" % [niveau, couleur.to_html()]
	if _textures.has(cle):
		return _textures[cle]
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for i in 16:
		if BAYER[i] < niveau:
			image.set_pixel(i % 4, i / 4, couleur)
	return _memoriser(cle, image)


## Nuage arrondi (trois bosses), ombré en bas.
static func nuage(largeur: int, hauteur: int, couleur: Color, ombre: Color) -> ImageTexture:
	var cle := "nuage:%d:%d:%s:%s" % [largeur, hauteur, couleur.to_html(), ombre.to_html()]
	if _textures.has(cle):
		return _textures[cle]
	var image := Image.create(largeur, hauteur, false, Image.FORMAT_RGBA8)
	var bosses := [
		[Vector2(largeur * 0.28, hauteur * 0.62), hauteur * 0.38],
		[Vector2(largeur * 0.52, hauteur * 0.45), hauteur * 0.45],
		[Vector2(largeur * 0.75, hauteur * 0.62), hauteur * 0.34],
	]
	var dedans := func(x: int, y: int) -> bool:
		if y >= int(hauteur * 0.62) and y < hauteur and x >= int(largeur * 0.18) and x < int(largeur * 0.86):
			return true
		for bosse: Array in bosses:
			if Vector2(x + 0.5, y + 0.5).distance_to(bosse[0]) <= float(bosse[1]):
				return true
		return false
	for y in hauteur:
		for x in largeur:
			if dedans.call(x, y):
				image.set_pixel(x, y, ombre if not dedans.call(x, y + 2) else couleur)
	return _memoriser(cle, image)


static func _image_carree(rayon: int) -> Image:
	return Image.create(rayon * 2 + 1, rayon * 2 + 1, false, Image.FORMAT_RGBA8)


static func _memoriser(cle: String, image: Image) -> ImageTexture:
	var texture := ImageTexture.create_from_image(image)
	_textures[cle] = texture
	return texture
