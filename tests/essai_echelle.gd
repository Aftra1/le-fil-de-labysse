extends SceneTree
## Essai comparatif de taille de pixel : la même vue de l'île rendue
## A. en 640x360 (affichée ×2), B. en 320x180 (affichée ×4), C. hybride : monde en 320x180 agrandi ×2
## sous une interface en 640x360. Chaque variante a une police adaptée, une vue avec l'inventaire
## ouvert, et chaque image est vérifiée (toutes ses couleurs dans la palette).
## Images : docs/captures/essai-*.png. Lancement : tests/essai_echelle.sh (Xvfb + Mesa).

const DOSSIER := "res://docs/captures/"
const DOT := "res://assets/fonts/DotGothic16-Regular.ttf"
const SILK := "res://assets/fonts/Silkscreen-Regular.ttf"
const ESSAIS := [
	{ "nom": "A-640x360", "k_monde": 1.0, "k_ui": 1.0, "zoom": 2, "police": DOT, "taille": 16 },
	{ "nom": "B-320x180", "k_monde": 0.5, "k_ui": 0.5, "zoom": 4, "police": SILK, "taille": 8 },
	{ "nom": "C-hybride", "k_monde": 0.5, "k_ui": 1.0, "zoom": 2, "police": DOT, "taille": 16 },
]
const RESSOURCES := ["vent", "nuage", "cristal_solaire", "cristal_lagon", "corail"]
const NOMS := ["Vent", "Ouate de nuage", "Cristal solaire", "Cristal de lagon", "Corail luisant"]
const QUANTITES := [12, 3, 7, 0, 2]
const FILONS := [Vector2(292, 192), Vector2(356, 191), Vector2(424, 192)]
const NUAGES := [Vector2(150, 70), Vector2(300, 46), Vector2(470, 96)]
const EOLIENNE := Vector2(206, 150)
const CLOCHE := Vector2(320, 318)
const ATTACHE := Vector2(320, 289)

var _palette: Dictionary = {}
var _hors_palette := 0


func _initialize() -> void:
	_lancer()


func _lancer() -> void:
	await process_frame
	for nom: String in Palette.noms():
		_palette[Palette.couleur(nom).to_rgba32()] = true
	for essai: Dictionary in ESSAIS:
		await _rendre(essai)
	print("PALETTE : %s" % ("OK" if _hors_palette == 0 else "%d image(s) hors palette" % _hors_palette))
	quit(0 if _hors_palette == 0 else 1)


func _rendre(essai: Dictionary) -> void:
	var k_monde: float = essai["k_monde"]
	var k_ui: float = essai["k_ui"]
	var monde := await _photo(Vector2i(Vector2(640, 360) * k_monde), func(vue: SubViewport) -> void:
		var dessin := Node2D.new()
		dessin.draw.connect(_dessiner.bind(dessin, k_monde))
		vue.add_child(dessin))
	var texture_monde := ImageTexture.create_from_image(monde)
	var zoom: int = essai["zoom"]
	for avec_inventaire in [false, true]:
		var ecran := await _photo(Vector2i(Vector2(640, 360) * k_ui), func(vue: SubViewport) -> void:
			var fond := TextureRect.new()
			fond.texture = texture_monde
			fond.stretch_mode = TextureRect.STRETCH_SCALE
			fond.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			fond.size = Vector2(640, 360) * k_ui
			vue.add_child(fond)
			vue.add_child(_interface(essai, avec_inventaire)))
		_verifier(ecran, str(essai["nom"]))
		ecran.resize(ecran.get_width() * zoom, ecran.get_height() * zoom, Image.INTERPOLATE_NEAREST)
		var suffixe := "-inventaire" if avec_inventaire else ""
		ecran.save_png(ProjectSettings.globalize_path(DOSSIER + "essai-%s%s.png" % [essai["nom"], suffixe]))
	# Détail : le centre de l'île, affiché à la même taille (×8 par rapport au 640x360)
	var detail := monde.get_region(Rect2i(Vector2i(Vector2(250, 140) * k_monde), Vector2i(Vector2(160, 90) * k_monde)))
	var facteur := roundi(8 / (k_monde * 2))
	detail.resize(detail.get_width() * facteur, detail.get_height() * facteur, Image.INTERPOLATE_NEAREST)
	detail.save_png(ProjectSettings.globalize_path(DOSSIER + "essai-%s-detail.png" % essai["nom"]))
	print("OK    essai %s" % essai["nom"])


## Rend une scène dans un SubViewport de la taille donnée et renvoie l'image (taille native).
func _photo(taille: Vector2i, remplir: Callable) -> Image:
	var vue := SubViewport.new()
	vue.size = taille
	vue.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vue.snap_2d_transforms_to_pixel = true
	vue.snap_2d_vertices_to_pixel = true
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vue)
	remplir.call(vue)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := vue.get_texture().get_image()
	root.remove_child(vue)
	vue.queue_free()
	return image


func _dessiner(toile: Node2D, k: float) -> void:
	toile.draw_texture(ArtIle.fond_ile(k), Vector2.ZERO)
	var hauteur := 360.0 * k
	# Nuages (ombre d'un ton plus sombre que le ciel derrière)
	for i in NUAGES.size():
		var taille := Vector2i(roundi(32 * k), roundi(16 * k))
		var texture := ArtIle.nuage(taille.x, taille.y)
		var centre: Vector2 = (NUAGES[i] * k).round()
		Pixel.sprite_ombre(toile, texture, centre, Palette.plus_sombre(ArtIle.couleur_ciel(centre.y, hauteur)),
			Vector2.ONE * maxf(roundf(2 * k), 1.0))
	# Éolienne : mât en bois, ombre au sol, pales
	var moyeu := (EOLIENNE * k).round()
	var sol := roundf(197 * k)
	var epaisseur := 3.0 if k >= 0.75 else 1.0
	toile.draw_rect(Rect2(moyeu.x - epaisseur / 2.0 - 1.0 + 2.0, sol - 1.0, epaisseur + 6.0 * k, 1.0), Palette.couleur("herbe.2"))
	toile.draw_rect(Rect2(moyeu.x - floorf(epaisseur / 2.0) - 1.0, moyeu.y, epaisseur + 2.0, sol - moyeu.y), Palette.couleur(ArtIle.CONTOUR))
	toile.draw_rect(Rect2(moyeu.x - floorf(epaisseur / 2.0), moyeu.y, epaisseur, sol - moyeu.y - 1.0), Palette.couleur("terre.2"))
	if k >= 0.75:
		toile.draw_rect(Rect2(moyeu.x - 1.0, moyeu.y, 1.0, sol - moyeu.y - 1.0), Palette.couleur("terre.3"))
	Pixel.sprite(toile, ArtIle.pales(k, 0.5), moyeu)
	# Filons de cristal solaire, ombre sur l'herbe
	for position_filon: Vector2 in FILONS:
		Pixel.sprite_ombre(toile, ArtIle.filon(k, true), (position_filon * k).round(), Palette.couleur("herbe.3"))
	# Cloche amarrée sous l'île
	var cloche := (CLOCHE * k).round()
	var texture_cloche := ArtIle.cloche(k)
	var haut_cloche := cloche.y - texture_cloche.get_height() / 2.0
	var attache := (ATTACHE * k).round()
	toile.draw_rect(Rect2(attache.x, attache.y, 1.0, haut_cloche - attache.y + 1.0), Palette.couleur("terre.1"))
	Pixel.sprite_ombre(toile, texture_cloche, cloche, Palette.plus_sombre(ArtIle.couleur_ciel(cloche.y, hauteur)))


func _interface(essai: Dictionary, avec_inventaire: bool) -> Control:
	var k: float = essai["k_ui"]
	var racine := Control.new()
	racine.size = Vector2(640, 360) * k
	var theme := Theme.new()
	theme.default_font = load(str(essai["police"]))
	theme.default_font_size = int(essai["taille"])
	theme.set_color("font_color", "Label", Palette.couleur(ArtIle.CONTOUR))
	theme.set_color("font_color", "Button", Palette.couleur(ArtIle.CONTOUR))
	racine.theme = theme
	var marge := roundf(6 * k)

	var bouton := Button.new()
	bouton.text = "Inventaire (I)"
	bouton.add_theme_stylebox_override("normal", ArtIle.cadre(k))
	bouton.position = Vector2(marge, marge)
	racine.add_child(bouton)

	var barre := PanelContainer.new()
	barre.add_theme_stylebox_override("panel", ArtIle.cadre(k))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", roundi(6 * k))
	for i in RESSOURCES.size():
		var icone := TextureRect.new()
		icone.texture = ArtIle.icone(RESSOURCES[i], k)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ligne.add_child(icone)
		var nombre := Label.new()
		nombre.text = str(QUANTITES[i])
		ligne.add_child(nombre)
	barre.add_child(ligne)
	_ancrer(barre, 1.0, 0.0, marge)
	racine.add_child(barre)

	var aide := PanelContainer.new()
	aide.add_theme_stylebox_override("panel", ArtIle.cadre(k))
	var texte := Label.new()
	texte.text = "Clique sur la cloche pour plonger"
	aide.add_child(texte)
	_ancrer(aide, 0.0, 1.0, marge)
	racine.add_child(aide)

	if avec_inventaire:
		racine.add_child(_inventaire(k))
	return racine


## Panneau d'inventaire opaque (pas de voile), cases en relief.
func _inventaire(k: float) -> Control:
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", ArtIle.cadre(k))
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", roundi(4 * k))
	var titre := Label.new()
	titre.text = "Inventaire"
	colonne.add_child(titre)
	var cases := HBoxContainer.new()
	cases.add_theme_constant_override("separation", roundi(4 * k))
	for i in RESSOURCES.size():
		var case := PanelContainer.new()
		case.add_theme_stylebox_override("panel", ArtIle.cadre(k, "interface.5", "interface"))
		case.custom_minimum_size = Vector2(80, 96) * k
		var contenu := VBoxContainer.new()
		contenu.alignment = BoxContainer.ALIGNMENT_CENTER
		var icone := TextureRect.new()
		icone.texture = ArtIle.icone(RESSOURCES[i], k)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		contenu.add_child(icone)
		var nom := Label.new()
		nom.text = NOMS[i]
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.custom_minimum_size = Vector2(72 * k, 0)
		contenu.add_child(nom)
		var nombre := Label.new()
		nombre.text = "×%d" % QUANTITES[i]
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contenu.add_child(nombre)
		case.add_child(contenu)
		cases.add_child(case)
	colonne.add_child(cases)
	var pied := Label.new()
	pied.text = "Fermer : I, Tab ou Échap"
	colonne.add_child(pied)
	panneau.add_child(colonne)
	_ancrer(panneau, 0.5, 0.5, 0.0)
	return panneau


## Ancre un panneau dans un coin (0, 0.5 ou 1 sur chaque axe) ; il grandit vers l'intérieur.
func _ancrer(controle: Control, ax: float, ay: float, marge: float) -> void:
	controle.anchor_left = ax
	controle.anchor_right = ax
	controle.anchor_top = ay
	controle.anchor_bottom = ay
	controle.offset_left = marge if ax == 0.0 else (-marge if ax == 1.0 else 0.0)
	controle.offset_right = controle.offset_left
	controle.offset_top = marge if ay == 0.0 else (-marge if ay == 1.0 else 0.0)
	controle.offset_bottom = controle.offset_top
	controle.grow_horizontal = Control.GROW_DIRECTION_END if ax == 0.0 else (Control.GROW_DIRECTION_BEGIN if ax == 1.0 else Control.GROW_DIRECTION_BOTH)
	controle.grow_vertical = Control.GROW_DIRECTION_END if ay == 0.0 else (Control.GROW_DIRECTION_BEGIN if ay == 1.0 else Control.GROW_DIRECTION_BOTH)


func _verifier(image: Image, nom: String) -> void:
	var hors := {}
	for y in image.get_height():
		for x in image.get_width():
			var couleur := image.get_pixel(x, y)
			couleur.a = 1.0
			if not _palette.has(couleur.to_rgba32()):
				hors[couleur.to_html(false)] = true
	if hors.is_empty():
		print("      palette OK : essai %s" % nom)
	else:
		_hors_palette += 1
		print("      HORS PALETTE : essai %s (%d couleurs, ex. %s)" % [nom, hors.size(), hors.keys().slice(0, 5)])
