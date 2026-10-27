extends SceneTree
## Joue deux scénarios automatiques et enregistre les captures PNG dans docs/captures/ :
## 00 : la palette ; 01-05 : la plongée seule (dive.tscn) ; 06-13 : le jeu complet (île, transitions, plongée).
## Chaque capture est vérifiée : tous ses pixels doivent être des couleurs de data/palette.json
## (un antialiasing ou une transparence créerait des couleurs intermédiaires).
## Sur l'île, on vérifie aussi la grille du monde (320x180 affiché ×2) : interface masquée,
## chaque bloc de 2x2 pixels d'écran doit être d'une seule couleur (aucun pixel du monde plus petit).
## Nécessite un affichage (Xvfb + Mesa logiciel) : voir tests/captures.sh.

const DOSSIER := "res://docs/captures/"
const ECHELLE := 2  # 640x360 agrandi ×2 en « plus proche voisin » pour rester lisible

var _plongee: Node
var _bell: CharacterBody2D
var _palette: Dictionary = {}      # couleur RGBA8 -> nom
var _captures_hors_palette := 0


func _initialize() -> void:
	_scenarios()


func _scenarios() -> void:
	await process_frame
	for nom: String in Palette.noms():
		_palette[Palette.couleur(nom).to_rgba32()] = nom
	await _planche_palette()
	await _scenario_plongee()
	await _scenario_jeu()
	print("PALETTE : %s" % ("toutes les captures respectent la palette" if _captures_hors_palette == 0
		else "%d capture(s) avec des couleurs hors palette" % _captures_hors_palette))
	quit(0 if _captures_hors_palette == 0 else 1)


# --- 00 : planche de la palette ------------------------------------------------------

func _planche_palette() -> void:
	var planche := Control.new()
	var fond := ColorRect.new()
	fond.color = Palette.couleur("interface.4")
	fond.size = Vector2(640, 360)
	planche.add_child(fond)
	var rampes := ["ciel", "nuage", "roche", "terre", "herbe", "or", "lagon", "corail", "abysse", "cyan", "interface", "metal"]
	for i in rampes.size():
		var y := 6 + i * 29
		var nom := Label.new()
		nom.text = rampes[i]
		nom.position = Vector2(12, y + 3)
		Pixel.texte(nom, "interface.0", "")
		planche.add_child(nom)
		var tons := Palette.rampe(rampes[i])
		for j in tons.size():
			var bord := ColorRect.new()
			bord.color = Palette.couleur("interface.0")
			bord.position = Vector2(140 + j * 50, y)
			bord.size = Vector2(46, 26)
			planche.add_child(bord)
			var echantillon := ColorRect.new()
			echantillon.color = tons[j]
			echantillon.position = Vector2(141 + j * 50, y + 1)
			echantillon.size = Vector2(44, 24)
			planche.add_child(echantillon)
	root.add_child(planche)
	await _images(3)
	await _capturer("00-palette")
	root.remove_child(planche)
	planche.queue_free()


# --- 01-05 : plongée seule ------------------------------------------------------

func _scenario_plongee() -> void:
	_plongee = load("res://scenes/dive.tscn").instantiate()
	root.add_child(_plongee)
	_bell = _plongee.get_node("Bell")
	await _images(30)

	await _capturer("01-surface")

	var cristal := _gisement_proche("cristal_lagon", 450.0)
	_placer_pres_de(cristal, Vector2(-48.0, -22.0))
	await _images(20)
	await _capturer("02-zone1-gisement")

	_placer_pres_de(cristal, Vector2(18.0, 8.0))
	Input.action_press("interact")
	await _images(33)
	await _capturer("03-minage-jauge")
	Input.action_release("interact")

	var corail := _gisement_proche("corail", 2200.0)
	_placer_pres_de(corail, Vector2(-48.0, -22.0))
	await _images(20)
	await _capturer("04-zone2")

	# Remontée automatique en cours (le message de perte s'affiche désormais sur l'île : capture 13)
	for i in 5:
		_plongee._sac.ajouter("cristal_lagon")
	_plongee._rafraichir_sac()
	_plongee.oxygene = 0.0
	await _images(90)
	await _capturer("05-remontee-automatique")

	root.remove_child(_plongee)
	_plongee.queue_free()
	await _images(2)


# --- 06-13 : jeu complet -------------------------------------------------------------

func _scenario_jeu() -> void:
	var jeu: Node = load("res://scenes/jeu.tscn").instantiate()
	root.add_child(jeu)
	var ile: Node = jeu.get_node("Ile")
	var transition: Node = jeu.get_node("Transition")
	await _images(30)
	await _capturer("06-ile")
	await _verifier_grille_monde(ile)

	# Récolte : éolienne et un nuage d'un clic, puis un filon en maintenant le clic
	var eolienne: Node2D = ile._eolienne
	await _cliquer(eolienne.position)
	var nuage: Node2D = ile.get_node("Nuages").get_child(0)
	await _cliquer(nuage.position)
	var filon: Node2D = ile._filons[1]
	_souris(filon.position)
	await _images(2)
	_bouton(filon.position, true)
	await _images(33)
	await _capturer("07-recolte-filon")
	await _images(40)
	_bouton(filon.position, false)
	await _images(5)

	_touche(KEY_I)
	await _images(5)
	await _capturer("08-inventaire")
	_touche(KEY_I)
	await _images(5)

	# Descente : clic sur la cloche, images figées à 25 % et 75 %
	_souris(Vector2(320, 318))
	await _images(2)
	await _cliquer(Vector2(320, 318))
	transition.afficher_image(0.25)
	await _images(2)
	await _capturer("09-descente-25")
	transition.afficher_image(0.75)
	await _images(2)
	await _capturer("10-descente-75")
	transition.reprendre()
	while jeu.etat != 2:  # PLONGEE
		await _images(1)
	await _images(2)
	await _capturer("11-plongee-arrivee")

	# Remontée d'urgence avec un sac plein : image figée à 50 %, puis retour sur l'île
	var plongee: Node = jeu.plongee()
	plongee.get_node("Bell").position.y = 400.0
	for i in 5:
		plongee._sac.ajouter("cristal_lagon")
	for i in 3:
		plongee._sac.ajouter("corail")
	plongee._rafraichir_sac()
	await _images(5)
	plongee.oxygene = 0.0
	while jeu.etat != 3:  # REMONTEE
		await _images(1)
	transition.afficher_image(0.5)
	await _images(2)
	await _capturer("12-remontee-50")
	transition.reprendre()
	while jeu.etat != 0:  # ILE
		await _images(1)
	await _images(10)
	await _capturer("13-retour-ile-perte")


# --- Outils --------------------------------------------------------------------------

func _images(nombre: int) -> void:
	for i in nombre:
		await physics_frame


func _gisement_proche(minerai: String, profondeur_px: float) -> Node2D:
	var meilleur: Node2D = null
	for enfant in _plongee.get_node("Gisements").get_children():
		if enfant.minerai != minerai:
			continue
		if meilleur == null or absf(enfant.position.y - profondeur_px) < absf(meilleur.position.y - profondeur_px):
			meilleur = enfant
	return meilleur


func _placer_pres_de(gisement: Node2D, decalage: Vector2) -> void:
	_bell.position = gisement.position + decalage
	_bell.velocity = Vector2.ZERO


## Les évènements souris sont envoyés en coordonnées fenêtre (le jeu les ramène en 640x360).
func _vers_fenetre(point: Vector2) -> Vector2:
	return root.get_final_transform() * point


func _souris(point: Vector2) -> void:
	var mouvement := InputEventMouseMotion.new()
	mouvement.position = _vers_fenetre(point)
	mouvement.global_position = mouvement.position
	Input.parse_input_event(mouvement)


func _bouton(point: Vector2, appuye: bool) -> void:
	var bouton := InputEventMouseButton.new()
	bouton.button_index = MOUSE_BUTTON_LEFT
	bouton.pressed = appuye
	bouton.position = _vers_fenetre(point)
	bouton.global_position = bouton.position
	Input.parse_input_event(bouton)


func _cliquer(point: Vector2) -> void:
	_souris(point)
	await _images(2)
	_bouton(point, true)
	await _images(2)
	_bouton(point, false)
	await _images(2)


func _touche(code: Key) -> void:
	for appuye in [true, false]:
		var touche := InputEventKey.new()
		touche.physical_keycode = code
		touche.pressed = appuye
		Input.parse_input_event(touche)


func _capturer(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	_verifier_palette(nom, image)
	if image.get_width() != 640 * ECHELLE:
		image.resize(640 * ECHELLE, 360 * ECHELLE, Image.INTERPOLATE_NEAREST)
	var chemin := ProjectSettings.globalize_path(DOSSIER + nom + ".png")
	var erreur := image.save_png(chemin)
	print("%s  %s (%dx%d)" % ["OK  " if erreur == OK else "ERREUR", chemin, image.get_width(), image.get_height()])


func _verifier_palette(nom: String, image: Image) -> void:
	var hors := {}
	for y in image.get_height():
		for x in image.get_width():
			var couleur := image.get_pixel(x, y)
			couleur.a = 1.0
			if not _palette.has(couleur.to_rgba32()):
				hors[couleur.to_html(false)] = int(hors.get(couleur.to_html(false), 0)) + 1
	if hors.is_empty():
		print("      palette OK : %s" % nom)
	else:
		_captures_hors_palette += 1
		var exemples := hors.keys().slice(0, 5)
		print("      HORS PALETTE : %s (%d couleurs, ex. %s)" % [nom, hors.size(), exemples])


func _verifier_grille_monde(ile: Node) -> void:
	ile.get_node("HUD").visible = false
	await _images(3)
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	ile.get_node("HUD").visible = true
	var ecarts := 0
	for y in range(0, image.get_height() - 1, 2):
		for x in range(0, image.get_width() - 1, 2):
			var couleur := image.get_pixel(x, y)
			if image.get_pixel(x + 1, y) != couleur or image.get_pixel(x, y + 1) != couleur \
					or image.get_pixel(x + 1, y + 1) != couleur:
				ecarts += 1
	if ecarts == 0:
		print("      grille du monde OK : tous les pixels de l'île font 2x2 pixels d'écran")
	else:
		_captures_hors_palette += 1
		print("      GRILLE DU MONDE : %d blocs 2x2 non uniformes" % ecarts)

