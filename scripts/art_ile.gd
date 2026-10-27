class_name ArtIle
extends RefCounted
## Pixel art du monde du haut (île, ciel, nuages, cloche, interface), généré en code.
## Tout est paramétré par une échelle k : 1 pour 640x360, 0.5 pour 320x180 (essai comparatif).
## Les grandes images (fond de l'île) sont peintes une fois dans une Image, puis mises en cache.
## Règles : couleurs de la palette uniquement, contour brun foncé (« contour_haut »), jamais noir,
## ombre portée pleine d'un ton plus sombre (Palette.plus_sombre), pas de transparence partielle.

const CONTOUR := "contour_haut"
const GRAINE := 1407

# Ciel : 5 paliers du haut vers l'horizon, bords crénelés plutôt que tramés
const PALIERS_CIEL := [[0.0, "ciel.1"], [0.14, "ciel.2"], [0.30, "ciel.3"], [0.48, "ciel.4"], [0.70, "ciel.5"]]
const CRENEAUX := [0, 1, 2, 1]

# Formes en caractères. Chiffres : indice dans la rampe choisie ; lettres : couleurs fixes.
const CLOCHE: PackedStringArray = [
	".......3332.......",
	".....34444332.....",
	"....3455444332....",
	"...345544443332...",
	"...345444443322...",
	"..34544MMMM33322..",
	"..3454McCCcM3322..",
	"..3454MccCcM3322..",
	"..3454MbccbM3322..",
	"..34544MMMM33222..",
	"..34444443333322..",
	".3444443333332221.",
	".MMMMMMMMMMMMMMMm.",
	".MrMrMrMrMrMrMrMm.",
	".mmmmmmmmmmmmmmmm.",
	"344544433333332221",
	"234444333333322211",
	"122222222222221111",
	".mmmmmmmmmmmmmmmm.",
]

const CLOCHE_PETITE: PackedStringArray = [
	"...3332...",
	"..354432..",
	".34MCcM32.",
	".344MM332.",
	".34433322.",
	"MrMrMrMrMm",
	"3443333221",
	"1222222211",
	".mmmmmmmm.",
]

const FILON: PackedStringArray = [
	"...5...",
	"..554..",
	"..543..",
	"5.543.4",
	"4554343",
	"4543332",
	"3543322",
	"3443322",
	"2333222",
	".22222.",
]

const FILON_PETIT: PackedStringArray = [
	".5..",
	".54.",
	"4543",
	"3432",
	"2332",
	".22.",
]

const CORAIL: PackedStringArray = [
	".3...4...3.",
	".4...4..34.",
	"34..34..4..",
	".34.3..33..",
	"..233.32...",
	"...2232....",
	"....221....",
	"....12.....",
	"...0110....",
]

const CORAIL_PETIT: PackedStringArray = [
	".3.4.",
	".4.3.",
	"..33.",
	"..2..",
	".010.",
]

const VENT: PackedStringArray = [
	"......22..",
	"........2.",
	"44444443..",
	"..........",
	".5555554..",
	"........4.",
	"...33332..",
]

const VENT_PETIT: PackedStringArray = [
	"...22",
	"3333.",
	".....",
	"4444.",
	".....",
	"..33.",
]
const COULEURS_CLOCHE := {
	"1": "or.1", "2": "or.2", "3": "or.3", "4": "or.4", "5": "or.5",
	"m": "metal.1", "M": "metal.2", "r": "or.4", "b": "cyan.1", "c": "cyan.2", "C": "cyan.3",
}

static var _cache: Dictionary = {}


# --- Couleurs ------------------------------------------------------------------------

static func c(nom: String) -> Color:
	return Palette.couleur(nom)


## Associe les chiffres d'un motif aux tons d'une rampe (décalage pour éclaircir ou assombrir).
static func couleurs_rampe(nom_rampe: String, decalage: int = 0) -> Dictionary:
	var tons := Palette.rampe(nom_rampe)
	var couleurs := {}
	for i in 7:
		couleurs[str(i)] = "%s.%d" % [nom_rampe, clampi(i + decalage, 0, tons.size() - 1)]
	return couleurs


## Couleur du ciel à une hauteur (sans les créneaux) : sert aux ombres des objets qui volent.
static func couleur_ciel(y: float, hauteur: float) -> Color:
	var nom: String = PALIERS_CIEL[0][1]
	for palier: Array in PALIERS_CIEL:
		if y >= float(palier[0]) * hauteur:
			nom = palier[1]
	return c(nom)


# --- Fond de l'île : ciel, soleil, île (mis en cache) ------------------------------

static func fond_ile(k: float) -> ImageTexture:
	var cle := "fond:%s" % k
	if _cache.has(cle):
		return _cache[cle]
	var taille := Vector2i(roundi(640 * k), roundi(360 * k))
	var image := Image.create(taille.x, taille.y, false, Image.FORMAT_RGBA8)
	peindre_ciel(image)
	peindre_soleil(image, Vector2i(roundi(560 * k), roundi(58 * k)), maxi(roundi(13 * k), 5))
	peindre_ile(image, k)
	var texture := ImageTexture.create_from_image(image)
	_cache[cle] = texture
	return texture


static func peindre_ciel(image: Image) -> void:
	var largeur := image.get_width()
	var hauteur := image.get_height()
	var dent := maxi(roundi(largeur / 213.0), 1)
	for i in PALIERS_CIEL.size():
		var debut := roundi(float(PALIERS_CIEL[i][0]) * hauteur)
		var fin := hauteur if i == PALIERS_CIEL.size() - 1 else roundi(float(PALIERS_CIEL[i + 1][0]) * hauteur)
		image.fill_rect(Rect2i(0, debut, largeur, fin - debut), c(PALIERS_CIEL[i][1]))
		if i == 0:
			continue
		# Bord crénelé : le palier clair mord sur le précédent par petites marches
		var echelle := 1 if hauteur < 300 else 2
		for x in largeur:
			var marche: int = CRENEAUX[(x / dent) % CRENEAUX.size()] * echelle / 2 + (1 if echelle == 1 and (x / dent) % 4 == 2 else 0)
			for y in range(debut - marche, debut):
				image.set_pixel(x, y, c(PALIERS_CIEL[i][1]))


static func peindre_soleil(image: Image, centre: Vector2i, rayon: int) -> void:
	for y in range(-rayon - 5, rayon + 6):
		for x in range(-rayon - 5, rayon + 6):
			var d := Vector2(x, y).length()
			var p := centre + Vector2i(x, y)
			if d < rayon:
				var lumiere := -(x + y) / float(rayon) * 0.6
				var indice := clampi(3 + roundi(1.6 * (1.0 - d / rayon) + lumiere), 3, 5)
				image.set_pixelv(p, c("or.%d" % indice))
			elif d < rayon + 1:
				image.set_pixelv(p, c("or.2"))
			elif d >= rayon + 3 and d < rayon + 4 and (x + y) % 2 == 0:
				image.set_pixelv(p, c("ciel.5"))


## L'île : herbe en touffes, couche de terre, roche en pavés avec cristaux incrustés,
## contour brun, ombre portée d'un ton plus sombre sur le ciel, treuil dessous.
static func peindre_ile(image: Image, k: float) -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = GRAINE
	var x0 := roundi(140 * k)
	var largeur := roundi(360 * k)
	var haut := roundi(197 * k)
	var profondeur := roundi(92 * k)
	var herbe := maxi(roundi(6 * k), 3)
	var terre := maxi(roundi(4 * k), 2)

	# Profil du dessous, avec de petites stalactites
	var bas: Array[int] = []
	for x in largeur:
		var u := (x + 0.5) / largeur * 2.0 - 1.0
		bas.append(haut + maxi(roundi(profondeur * pow(1.0 - u * u, 0.75)), herbe + terre + 2))
	var x := 2
	while x < largeur - 2:
		if hasard.randf() < 0.09:
			var large := hasard.randi_range(2, maxi(roundi(5 * k), 2))
			var longueur := hasard.randi_range(maxi(roundi(2 * k), 1), maxi(roundi(6 * k), 2))
			for i in large:
				if x + i < largeur:
					var pointe := 1.0 - absf((i + 0.5) / large * 2.0 - 1.0)
					bas[x + i] += roundi(longueur * pointe)
			x += large + 2
		x += 1

	var dans := func(lx: int, y: int) -> bool:
		return lx >= 0 and lx < largeur and y >= haut and y <= bas[lx]

	# 1. Ombre portée sur le ciel
	var decalage := maxi(roundi(2 * k), 1)
	for lx in largeur:
		for y in range(haut, bas[lx] + 1):
			if not dans.call(lx + decalage, y + decalage):
				var p := Vector2i(x0 + lx + decalage, y + decalage)
				image.set_pixelv(p, Palette.plus_sombre(image.get_pixelv(p)))

	# 2. Roche : plus claire en haut à gauche, plus sombre en bas à droite
	var ton_roche := func(lx: int, y: int) -> int:
		var f := float(y - haut) / maxf(float(bas[lx] - haut), 1.0)
		var u := (lx + 0.5) / largeur * 2.0 - 1.0
		return clampi(5 - int(f * 4.6) - (1 if u > 0.4 else 0), 1, 5)
	for lx in largeur:
		for y in range(haut, bas[lx] + 1):
			image.set_pixel(x0 + lx, y, c("roche.%d" % ton_roche.call(lx, y)))

	# 3. Pavés : chacun éclairé en haut à gauche, ombré en bas à droite, avec un joint sombre
	var nombre_paves := roundi(170 * k * k) + 20
	for i in nombre_paves:
		var lx := hasard.randi_range(0, largeur - 1)
		var y := hasard.randi_range(haut + herbe + terre, bas[lx])
		if not dans.call(lx, y):
			continue
		var rayon := hasard.randf_range(1.5, 4.5) * maxf(k, 0.6)
		var base := clampi(ton_roche.call(lx, y) + hasard.randi_range(-1, 0), 1, 5)
		for dy in range(-ceili(rayon), ceili(rayon) + 2):
			for dx in range(-ceili(rayon * 1.4), ceili(rayon * 1.4) + 1):
				var px := lx + dx
				var py := y + dy
				if not dans.call(px, py) or py < haut + herbe + terre:
					continue
				var e := Vector2(dx / 1.4, dy).length() / rayon
				if e <= 1.0:
					var biais := (dx / 1.4 + dy) / rayon
					var ton := base + (1 if biais < -0.7 else 0) - (1 if biais > 0.6 else 0)
					image.set_pixel(x0 + px, py, c("roche.%d" % clampi(ton, 0, 5)))
				elif e <= 1.0 + 1.0 / rayon and dy > 0:
					image.set_pixel(x0 + px, py, c("roche.%d" % clampi(base - 2, 0, 5)))

	# 4. Cristaux incrustés (or et cyan), sertis de roche sombre
	var petits := k < 0.75
	var cristal: PackedStringArray = [".k.", "k3k", ".k."] if petits else ["..k..", ".k3k.", "k432k", "k432k", ".k2k.", "..k.."]
	for i in roundi(8 * k) + 2:
		var lx := hasard.randi_range(roundi(largeur * 0.15), roundi(largeur * 0.85))
		var f := hasard.randf_range(0.3, 0.7)
		var y := haut + herbe + terre + roundi((bas[lx] - haut - herbe - terre) * f)
		var nom_rampe := "cyan" if i % 2 == 0 else "or"
		for dy in cristal.size():
			for dx in cristal[dy].length():
				var caractere := cristal[dy][dx]
				var px := lx + dx - cristal[dy].length() / 2
				var py := y + dy
				if caractere == "." or not dans.call(px, py):
					continue
				var nom := "roche.0" if caractere == "k" else "%s.%d" % [nom_rampe, mini(int(caractere), Palette.rampe(nom_rampe).size() - 1)]
				image.set_pixel(x0 + px, py, c(nom))

	# 5. Terre : bande sous l'herbe, racines irrégulières
	for lx in largeur:
		var racines := hasard.randi_range(0, maxi(roundi(2 * k), 1))
		for y in range(haut + herbe, haut + herbe + terre + racines):
			if not dans.call(lx, y):
				continue
			var ton := 2 if y == haut + herbe else 1
			if y >= haut + herbe + terre:
				ton = 0
			elif hasard.randf() < 0.08:
				ton = 3
			image.set_pixel(x0 + lx, y, c("terre.%d" % ton))

	# 6. Herbe : surface claire, fond plus sombre, quelques coulures sur la terre
	for lx in largeur:
		for y in range(haut, haut + herbe):
			var rang := y - haut
			var ton := 4 if rang < herbe / 2 else (3 if rang < herbe - 1 else 2)
			var tirage := hasard.randf()
			if tirage < 0.10:
				ton += 1
			elif tirage < 0.18:
				ton -= 1
			image.set_pixel(x0 + lx, y, c("herbe.%d" % clampi(ton, 1, 5)))
		if hasard.randf() < 0.18:
			for y in range(haut + herbe, haut + herbe + hasard.randi_range(1, maxi(roundi(2 * k), 1))):
				if dans.call(lx, y):
					image.set_pixel(x0 + lx, y, c("herbe.2"))

	# 7. Contour brun autour de l'île
	var contour := c(CONTOUR)
	for lx in range(-1, largeur + 1):
		for y in range(haut - 1, haut + profondeur + roundi(10 * k)):
			if dans.call(lx, y):
				continue
			if dans.call(lx + 1, y) or dans.call(lx - 1, y) or dans.call(lx, y + 1) or dans.call(lx, y - 1):
				image.set_pixel(x0 + lx, y, contour)

	# 8. Touffes d'herbe au-dessus du bord, quelques fleurs
	var lx2 := hasard.randi_range(1, 4)
	while lx2 < largeur - 2:
		var brins := hasard.randi_range(2, 3)
		var fonce := hasard.randf() < 0.3
		for b in brins:
			var hauteur_brin := hasard.randi_range(1, maxi(roundi(3 * k), 1)) + (1 if b == 1 else 0)
			for h in hauteur_brin:
				var ton := 5 if h == hauteur_brin - 1 else 4
				if fonce:
					ton -= 1
				image.set_pixel(x0 + lx2 + b, haut - 1 - h, c("herbe.%d" % ton))
			if hasard.randf() < 0.07:
				image.set_pixel(x0 + lx2 + b, haut - 1 - hauteur_brin, c("interface.5" if hasard.randf() < 0.5 else "or.4"))
		lx2 += brins + hasard.randi_range(maxi(roundi(2 * k), 1), maxi(roundi(6 * k), 2))

	# 9. Treuil sous l'île
	var treuil := Rect2i(x0 + largeur / 2 - roundi(8 * k), haut + profondeur - roundi(6 * k), roundi(16 * k), maxi(roundi(7 * k), 3))
	image.fill_rect(treuil.grow(1), contour)
	image.fill_rect(treuil, c("metal.2"))
	image.fill_rect(Rect2i(treuil.position, Vector2i(treuil.size.x, 1)), c("metal.3"))
	image.fill_rect(Rect2i(treuil.position + Vector2i(0, treuil.size.y - 1), Vector2i(treuil.size.x, 1)), c("metal.1"))


# --- Sprites ---------------------------------------------------------------------------

## Nuage en volume : lumière chaude en haut à gauche, ombre bleutée en bas, contour bleu-gris.
static func nuage(largeur: int, hauteur: int) -> ImageTexture:
	var cle := "nuage:%d:%d" % [largeur, hauteur]
	if _cache.has(cle):
		return _cache[cle]
	var image := Image.create(largeur, hauteur, false, Image.FORMAT_RGBA8)
	var bosses := [
		[Vector2(largeur * 0.27, hauteur * 0.62), hauteur * 0.36],
		[Vector2(largeur * 0.50, hauteur * 0.44), hauteur * 0.44],
		[Vector2(largeur * 0.74, hauteur * 0.60), hauteur * 0.34],
	]
	var dans := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= largeur or y >= hauteur:
			return false
		if y >= int(hauteur * 0.6) and x >= int(largeur * 0.16) and x < int(largeur * 0.86):
			return true
		for bosse: Array in bosses:
			if Vector2(x + 0.5, y + 0.5).distance_to(bosse[0]) <= float(bosse[1]):
				return true
		return false
	for y in hauteur:
		for x in largeur:
			if not dans.call(x, y):
				continue
			var ton := 3
			if y > hauteur * 0.66:
				ton = 2
			for bosse: Array in bosses:
				var ecart: Vector2 = (Vector2(x + 0.5, y + 0.5) - bosse[0]) / float(bosse[1])
				if ecart.length() <= 1.0 and ecart.x + ecart.y < -0.75:
					ton = 4
			if not dans.call(x, y - 1):
				ton = 4
			if not dans.call(x, y + 1):
				ton = 1
			image.set_pixel(x, y, c("nuage.%d" % ton))
	var texture := ImageTexture.create_from_image(Pixel.contourner(image, c("nuage.0")))
	_cache[cle] = texture
	return texture


## Pales de l'éolienne (voiles crème bordées de brun), pour un angle donné (12 images par tiers de tour).
static func pales(k: float, angle: float) -> ImageTexture:
	var image_n := posmod(roundi(angle / (TAU / 3.0) * 12.0), 12)
	var cle := "pales:%s:%d" % [k, image_n]
	if _cache.has(cle):
		return _cache[cle]
	var longueur := maxi(roundi(13 * k), 6)
	var cote := longueur * 2 + 5
	var image := Image.create(cote, cote, false, Image.FORMAT_RGBA8)
	var centre := Vector2(cote / 2, cote / 2)
	var angle_image := image_n * (TAU / 3.0) / 12.0
	for i in 3:
		var direction := Vector2.from_angle(angle_image + i * TAU / 3.0)
		var normale := Vector2(-direction.y, direction.x)
		for t in range(2, longueur + 1):
			var p := (centre + direction * t).round()
			image.set_pixelv(Vector2i(p), c("interface.5"))
			if k >= 0.75:
				image.set_pixelv(Vector2i((centre + direction * t + normale).round()), c("interface.4"))
	var moyeu := Vector2i(centre)
	image.fill_rect(Rect2i(moyeu - Vector2i.ONE, Vector2i(3, 3)) if k >= 0.75 else Rect2i(moyeu, Vector2i.ONE), c("or.4"))
	var texture := ImageTexture.create_from_image(Pixel.contourner(image, c(CONTOUR)))
	_cache[cle] = texture
	return texture


static func cloche(k: float, contour: String = CONTOUR) -> ImageTexture:
	return Pixel.motif(CLOCHE if k >= 0.75 else CLOCHE_PETITE, COULEURS_CLOCHE, contour)


static func filon(k: float, plein: bool) -> ImageTexture:
	return Pixel.motif(FILON if k >= 0.75 else FILON_PETIT,
		couleurs_rampe("or") if plein else couleurs_rampe("roche"), CONTOUR)


## Icône d'une ressource (inventaire, barre de ressources).
static func icone(id: String, k: float) -> Texture2D:
	var grand := k >= 0.75
	match id:
		"vent":
			return Pixel.motif(VENT if grand else VENT_PETIT, couleurs_rampe("ciel", -1), CONTOUR)
		"nuage":
			return nuage(16, 9) if grand else nuage(8, 5)
		"cristal_solaire":
			return filon(k, true)
		"cristal_lagon":
			return Pixel.motif(FILON if grand else FILON_PETIT, couleurs_rampe("cyan", -2), CONTOUR)
		"corail":
			return Pixel.motif(CORAIL if grand else CORAIL_PETIT, couleurs_rampe("corail"), CONTOUR)
	return Pixel.disque(3, c("roche.3"))


# --- Interface : cadres épais (liseré sombre, or en relief, fond crème) ----------------------

## fond : ton de crème du centre (« interface.4 » normal, « .5 » survol, « .3 » appui).
static func cadre(k: float, fond: String = "interface.4", bord: String = "or") -> StyleBoxTexture:
	var cle := "cadre:%s:%s:%s" % [k, fond, bord]
	if _cache.has(cle):
		return _cache[cle]
	var epais := k >= 0.75
	var cote := 16 if epais else 8
	var image := Image.create(cote, cote, false, Image.FORMAT_RGBA8)
	image.fill(c(fond))
	var anneaux: Array = (
		[[c(CONTOUR), c(CONTOUR)], [c(bord + ".4"), c(bord + ".2")], [c(bord + ".3"), c(bord + ".3")],
			[c("interface.1"), c("interface.1")], [c("interface.5"), c(fond)]]
		if epais else
		[[c(CONTOUR), c(CONTOUR)], [c(bord + ".4"), c(bord + ".2")], [c("interface.1"), c("interface.1")]]
	)
	for i in anneaux.size():
		var clair: Color = anneaux[i][0]
		var sombre: Color = anneaux[i][1]
		var n := cote - 1 - i
		for t in range(i, n + 1):
			image.set_pixel(t, i, clair)        # haut
			image.set_pixel(i, t, clair)        # gauche
			image.set_pixel(t, n, sombre)       # bas
			image.set_pixel(n, t, sombre)       # droite
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var marge := anneaux.size()
	style.texture_margin_left = marge
	style.texture_margin_top = marge
	style.texture_margin_right = marge
	style.texture_margin_bottom = marge
	style.content_margin_left = marge + (4 if epais else 2)
	style.content_margin_right = marge + (4 if epais else 2)
	style.content_margin_top = marge + (1 if epais else 1)
	style.content_margin_bottom = marge + (1 if epais else 0)
	_cache[cle] = style
	return style
