class_name ArtIle
extends RefCounted
## Pixel art du monde du haut (île, ciel, nuages, cloche, interface), généré en code.
## Tout est paramétré par une échelle k : 1 pour 640x360, 0.5 pour 320x180 (essai comparatif).
## Les grandes images (fond de l'île) sont peintes une fois dans une Image, puis mises en cache.
## Règles : couleurs de la palette uniquement, contour brun foncé (« contour_haut »), jamais noir,
## ombre portée pleine d'un ton plus sombre (Palette.plus_sombre), pas de transparence partielle.

const CONTOUR := "contour_haut"
const GRAINE := 1407

# Ciel : une seule colonne de paliers, de l'écran de l'île (y = 0) jusqu'à la mer (y = HAUTEUR_CIEL),
# en pixels du monde (320x180). L'île, la transition et la plongée la dessinent toutes les trois :
# leurs ciels se raccordent donc sans saut. Bords de paliers crénelés plutôt que tramés.
const PALIERS_CIEL := [[0, "ciel.1"], [25, "ciel.2"], [54, "ciel.3"], [86, "ciel.4"], [126, "ciel.5"], [750, "nuage.3"]]
const HAUTEUR_CIEL := 900        # surface de la mer, en pixels du monde (1800 en 640x360)
const CRENEAUX := [0, 1, 2, 1]
const DENT := 3

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
const CABANE: PackedStringArray = [
	"...........cc...",
	".......oo..cc...",
	"......oOOo.cc...",
	".....oOOOOocc...",
	"....oOOOOOOcc...",
	"...oOOOOOOOOo...",
	"..oooooooooooo..",
	"...wWWWWWWWWw...",
	"...wWffWWWWWw...",
	"...wWffWWddWw...",
	"...wWWWWWddWw...",
	"...wWWWWWddWw...",
	"...wwwwwwddww...",
]
const FIL_NUAGE: PackedStringArray = [
	"tttttttt",
	".nnnnnn.",
	".NnNnNn.",
	".nnnnnn.",
	".NnNnNn.",
	"TTTTTTTT",
]
const LENTILLE: PackedStringArray = [
	"..OOOo..",
	".OCCcco.",
	"OCCccccd",
	"OCcccccd",
	"occcccd.",
	".occccd.",
	"..dddd..",
]
const POCHE_AIR: PackedStringArray = [
	"...tt...",
	"..tttt..",
	".bBBbbb.",
	"bBBbbbbs",
	"bBbbbbbs",
	"bbbbbbss",
	".bbbbss.",
	"..ssss..",
]
const ICONE_CABLE: PackedStringArray = [
	"..MMMMM..",
	".M.....M.",
	"M..mmm..M",
	"M.m...m.M",
	"M..mmm..M",
	".M.....M.",
	"..MMMMM..",
]
const ICONE_LANTERNE: PackedStringArray = [
	"..mmm..",
	"...m...",
	".MMMMM.",
	".MCCcM.",
	".MCccM.",
	".MccbM.",
	".MMMMM.",
	"..mmm..",
]
const ICONE_RESERVOIR: PackedStringArray = [
	"..mmmm..",
	".MMMMMm.",
	"MMCcMMMm",
	"MMccMMMm",
	"MMMMMMMm",
	"MMMMMMMm",
	".MMMMMm.",
	"..mmmm..",
]
const ICONE_PASSERELLE: PackedStringArray = [
	"T.......T",
	"TNNNNNNNT",
	"T.N...N.T",
	"TtTtTtTtT",
	".T.....T.",
]
const ICONE_MOULIN: PackedStringArray = [
	"N.......N",
	".N.....N.",
	"..N.T.N..",
	"...TOT...",
	"..NtttN..",
	".N.tdt.N.",
	"N..tdt..N",
	"...tdt...",
	"..ttttt..",
]
const ICONE_FILET: PackedStringArray = [
	"T.......T",
	"TnNnNnNnT",
	"T.n.n.n.T",
	"TnNnNnNnT",
	"T.n.n.n.T",
	"TnBnNnBnT",
	"T.......T",
	"T.......T",
]
const ICONE_FOREUSE: PackedStringArray = [
	"TmmmmmT",
	".T.M.T.",
	".T.M.T.",
	"..TMT..",
	"..TmT..",
	"..oOo..",
	".oOOOd.",
	"oOOOOOd",
]
const ICONE_ENTREPOT: PackedStringArray = [
	"...TTT...",
	"..TTTTT..",
	".TTTTTTT.",
	"TttttttdT",
	".tTTtTTt.",
	".tTdddTt.",
	".tTdddTto",
	".tttttttO",
]
const ICONE_SAC: PackedStringArray = [
	"..TTTT..",
	".T....T.",
	".tttttt.",
	"tTttttTt",
	"tttoottt",
	"tttttttt",
	"tTttttTt",
	".tttttt.",
]
const ICONE_PONT: PackedStringArray = [
	"T.......T",
	"TN.....NT",
	"T.N...N.T",
	"T..NNN..T",
	"Tt.....tT",
	".tTt.tTt.",
	"...tTt...",
]
const ICONE_FOURNEAU: PackedStringArray = [
	"....MM..",
	"..rrMr..",
	".rRRRRr.",
	"rRRRRRRr",
	"rRRooRRr",
	"rRoOOoRr",
	"rRoOOoRr",
	"rrrrrrrr",
]
const ICONE_SONDE: PackedStringArray = [
	"TMMMMM.",
	"T....M.",
	"T....M.",
	"T....M.",
	"T...mcm",
	"T...cCc",
	"T...mcm",
	"TT.....",
]
const VERRE: PackedStringArray = [
	"..cCCc..",
	".cCBBCc.",
	"cCBCCCCc",
	"cCCCCCCs",
	"cCCCCCss",
	".cCCCss.",
	"..csss..",
]
const NACRE: PackedStringArray = [
	"..nNNn..",
	".nNBBNn.",
	"nNBNNNNn",
	"nNNNNNNs",
	".nNNNNs.",
	"..nnss..",
]
const LINGOT: PackedStringArray = [
	"..OOOOOO",
	".OOOOOOd",
	"oooooodd",
	"ooooood.",
	"dddddd..",
]
const COULEURS_CABANE := {
	"c": "roche.2", "o": "or.2", "O": "or.3", "w": "terre.1", "W": "terre.2", "d": "interface.1", "f": "or.5",
}
const COULEURS_OBJETS := {
	"t": "terre.2", "T": "terre.1", "n": "nuage.3", "N": "nuage.4",
	"o": "or.3", "O": "or.4", "d": "or.1", "c": "cyan.2", "C": "cyan.3",
	"b": "ciel.3", "B": "nuage.4", "s": "ciel.2",
	"m": "metal.2", "M": "metal.3", "r": "roche.2", "R": "roche.3",
}

const COULEURS_CLOCHE := {
	"1": "or.1", "2": "or.2", "3": "or.3", "4": "or.4", "5": "or.5",
	"m": "metal.1", "M": "metal.2", "r": "or.4", "b": "cyan.1", "c": "cyan.2", "C": "cyan.3",
}

static var _cache: Dictionary = {}


static func vider_cache() -> void:
	_cache.clear()


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


## Couleur du ciel à une hauteur de la colonne (sans les créneaux) : sert aux ombres des objets qui volent.
static func couleur_ciel_monde(y: float) -> Color:
	return c(PALIERS_CIEL[_palier_ciel(y)][1])


## Couleur exacte d'un pixel du ciel (x, y en pixels du monde de la colonne), créneaux compris.
static func couleur_ciel_pixel(x: int, y: int) -> Color:
	var i := _palier_ciel(y)
	if i + 1 < PALIERS_CIEL.size() and y >= int(PALIERS_CIEL[i + 1][0]) - _creneau(x):
		i += 1
	return c(PALIERS_CIEL[i][1])


## Dessine le ciel sur une toile ; un point de la toile (x, y) est le pixel (x + dx, y + dy) de la colonne.
static func dessiner_ciel(toile: CanvasItem, zone: Rect2, dx: int, dy: int) -> void:
	var haut := int(zone.position.y) + dy
	var bas := int(zone.end.y) + dy
	for i in PALIERS_CIEL.size():
		var debut: int = maxi(int(PALIERS_CIEL[i][0]), haut)
		var fin: int = bas if i + 1 == PALIERS_CIEL.size() else mini(int(PALIERS_CIEL[i + 1][0]), bas)
		if fin > debut:
			toile.draw_rect(Rect2(zone.position.x, debut - dy, zone.size.x, fin - debut), c(PALIERS_CIEL[i][1]))
		if i == 0:
			continue
		var bord := int(PALIERS_CIEL[i][0])
		if bord - 2 > bas or bord < haut:
			continue
		var x := floori((zone.position.x + dx) / float(DENT)) * DENT
		while x < zone.end.x + dx:
			var marche := _creneau(x)
			if marche > 0:
				toile.draw_rect(Rect2(x - dx, bord - marche - dy, DENT, marche), c(PALIERS_CIEL[i][1]))
			x += DENT


static func _palier_ciel(y: float) -> int:
	var indice := 0
	for i in PALIERS_CIEL.size():
		if y >= float(PALIERS_CIEL[i][0]):
			indice = i
	return indice


static func _creneau(x: int) -> int:
	return CRENEAUX[posmod(floori(x / float(DENT)), CRENEAUX.size())]


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
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, couleur_ciel_pixel(x, y))


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


## Cabane de l'atelier (monde 320x180) ; fenêtre allumée quand une fabrication est possible.
static func cabane(allumee: bool) -> ImageTexture:
	var couleurs := COULEURS_CABANE.duplicate()
	if not allumee:
		couleurs["f"] = "or.1"
	return Pixel.motif(CABANE, couleurs, CONTOUR)


## Îlot flottant (monde 320x180) : herbe, terre, roche effilée vers le bas, contour brun.
## Tant qu'il n'est pas relié, chaque pixel est assombri d'un ton (toujours dans la palette).
const LARGEUR_ILOT := 34
const HAUTEUR_ILOT := 20

static func ilot(relie: bool) -> ImageTexture:
	var cle := "ilot:%s" % relie
	if _cache.has(cle):
		return _cache[cle]
	var hasard := RandomNumberGenerator.new()
	hasard.seed = GRAINE + 7
	var image := Image.create(LARGEUR_ILOT, HAUTEUR_ILOT, false, Image.FORMAT_RGBA8)
	for x in LARGEUR_ILOT:
		var u := (x + 0.5) / LARGEUR_ILOT * 2.0 - 1.0
		var bas := 6 + roundi(13.0 * pow(maxf(1.0 - u * u, 0.0), 0.8))
		for y in mini(bas, HAUTEUR_ILOT):
			var nom := ""
			if y == 0:
				nom = "herbe.5" if hasard.randf() < 0.3 else "herbe.4"
			elif y <= 2:
				nom = "herbe.3" if y == 1 else "herbe.2"
			elif y <= 4:
				nom = "terre.2" if y == 3 else "terre.1"
			else:
				var tirage := hasard.randf()
				nom = "roche.4" if tirage < 0.15 else ("roche.2" if tirage < 0.45 else "roche.3")
				if y == bas - 1:
					nom = "roche.1"
			image.set_pixel(x, y, c(nom))
	# Deux éclats de cristal de lagon dans la roche
	for eclat: Vector2i in [Vector2i(11, 8), Vector2i(22, 10)]:
		image.set_pixelv(eclat, c("lagon.5"))
	image = Pixel.contourner(image, c(CONTOUR))
	if not relie:
		for y in image.get_height():
			for x in image.get_width():
				var teinte := image.get_pixel(x, y)
				if teinte.a > 0.0:
					image.set_pixel(x, y, Palette.plus_sombre(teinte))
	var texture := ImageTexture.create_from_image(image)
	_cache[cle] = texture
	return texture


## Icône d'une construction (atelier).
static func icone_construction(id: String) -> Texture2D:
	if id == "pont":
		return Pixel.motif(ICONE_PONT, COULEURS_OBJETS, CONTOUR)
	return Pixel.motif(ICONE_PASSERELLE, COULEURS_OBJETS, CONTOUR)


## Icône d'une machine de l'île (atelier, onglet Machines).
static func icone_machine(id: String) -> Texture2D:
	match id:
		"moulin":
			return Pixel.motif(ICONE_MOULIN, COULEURS_OBJETS, CONTOUR)
		"filet":
			return Pixel.motif(ICONE_FILET, COULEURS_OBJETS, CONTOUR)
		"foreuse":
			return Pixel.motif(ICONE_FOREUSE, COULEURS_OBJETS, CONTOUR)
		"entrepot":
			return Pixel.motif(ICONE_ENTREPOT, COULEURS_OBJETS, CONTOUR)
		"fourneau":
			return Pixel.motif(ICONE_FOURNEAU, COULEURS_OBJETS, CONTOUR)
		"sonde":
			return Pixel.motif(ICONE_SONDE, COULEURS_OBJETS, CONTOUR)
	return Pixel.disque(3, c("roche.3"))


## Icône d'une amélioration de la cloche (atelier).
static func icone_amelioration(id: String) -> Texture2D:
	match id:
		"cable":
			return Pixel.motif(ICONE_CABLE, COULEURS_OBJETS, CONTOUR)
		"lanterne":
			return Pixel.motif(ICONE_LANTERNE, COULEURS_OBJETS, CONTOUR)
		"reservoir":
			return Pixel.motif(ICONE_RESERVOIR, COULEURS_OBJETS, CONTOUR)
		"sac":
			return Pixel.motif(ICONE_SAC, COULEURS_OBJETS, CONTOUR)
	return Pixel.disque(3, c("roche.3"))


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
		"pierre_braise":
			return Pixel.motif(ArtAbysse.BRAISE, couleurs_rampe("or"), CONTOUR)
		"fil_nuage":
			return Pixel.motif(FIL_NUAGE, COULEURS_OBJETS, CONTOUR)
		"lentille":
			return Pixel.motif(LENTILLE, COULEURS_OBJETS, CONTOUR)
		"poche_air":
			return Pixel.motif(POCHE_AIR, COULEURS_OBJETS, CONTOUR)
		"verre_lagon":
			return Pixel.motif(VERRE, COULEURS_OBJETS, CONTOUR)
		"nacre":
			return Pixel.motif(NACRE, COULEURS_OBJETS, CONTOUR)
		"lingot_solaire":
			return Pixel.motif(LINGOT, COULEURS_OBJETS, CONTOUR)
	return Pixel.disque(3, c("roche.3"))


# --- Interface : cadres épais (liseré sombre, or en relief, fond crème) ----------------------

## fond : ton de crème du centre (« interface.4 » normal, « .5 » survol, « .3 » appui).
static func cadre(k: float, fond: String = "interface.4", bord: String = "or") -> StyleBoxTexture:
	var cle := "cadre:%s:%s:%s" % [k, fond, bord]
	if _cache.has(cle):
		return _cache[cle]
	var style := style_anneaux([
		[c(CONTOUR), c(CONTOUR)], [c(bord + ".4"), c(bord + ".2")], [c(bord + ".3"), c(bord + ".3")],
		[c("interface.1"), c("interface.1")], [c("interface.5"), c(fond)],
	], c(fond))
	_cache[cle] = style
	return style


## Cadre épais en 9 parties à partir d'anneaux [couleur haut/gauche, couleur bas/droite], de l'extérieur
## vers l'intérieur : le relief vient de l'opposition clair en haut à gauche / sombre en bas à droite.
static func style_anneaux(anneaux: Array, fond: Color) -> StyleBoxTexture:
	var cote := 16
	var image := Image.create(cote, cote, false, Image.FORMAT_RGBA8)
	image.fill(fond)
	for i in anneaux.size():
		var clair: Color = anneaux[i][0]
		var sombre: Color = anneaux[i][1]
		var n := cote - 1 - i
		for t in range(i, n + 1):
			image.set_pixel(t, i, clair)
			image.set_pixel(i, t, clair)
			image.set_pixel(t, n, sombre)
			image.set_pixel(n, t, sombre)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var marge := anneaux.size()
	style.texture_margin_left = marge
	style.texture_margin_top = marge
	style.texture_margin_right = marge
	style.texture_margin_bottom = marge
	style.content_margin_left = marge + 4
	style.content_margin_right = marge + 4
	style.content_margin_top = marge + 1
	style.content_margin_bottom = marge + 1
	return style


## Ancre un panneau dans un coin ou au centre (0, 0.5 ou 1 sur chaque axe) ; il grandit vers l'intérieur.
static func ancrer(controle: Control, ax: float, ay: float, marge: float) -> void:
	controle.anchor_left = ax
	controle.anchor_right = ax
	controle.anchor_top = ay
	controle.anchor_bottom = ay
	controle.offset_left = marge if ax == 0.0 else (-marge if ax == 1.0 else 0.0)
	controle.offset_right = controle.offset_left
	controle.offset_top = marge if ay == 0.0 else (-marge if ay == 1.0 else 0.0)
	controle.offset_bottom = controle.offset_top
	controle.grow_horizontal = Control.GROW_DIRECTION_END if ax == 0.0 \
		else (Control.GROW_DIRECTION_BEGIN if ax == 1.0 else Control.GROW_DIRECTION_BOTH)
	controle.grow_vertical = Control.GROW_DIRECTION_END if ay == 0.0 \
		else (Control.GROW_DIRECTION_BEGIN if ay == 1.0 else Control.GROW_DIRECTION_BOTH)


## Style des boutons de l'interface du haut (cadre or et crème, relief inversé à l'appui).
static func styler_bouton(bouton: Button) -> void:
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.add_theme_stylebox_override("normal", cadre(1.0))
	bouton.add_theme_stylebox_override("hover", cadre(1.0, "interface.5"))
	bouton.add_theme_stylebox_override("pressed", cadre(1.0, "interface.3"))
	for etat in ["font_color", "font_hover_color", "font_pressed_color"]:
		bouton.add_theme_color_override(etat, c(CONTOUR))
	# Bouton inactif : crème plus sombre, texte grisé (toujours dans la palette).
	bouton.add_theme_stylebox_override("disabled", cadre(1.0, "interface.3", "interface"))
	bouton.add_theme_color_override("font_disabled_color", c("interface.2"))
