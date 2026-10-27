extends SceneTree
## Joue un scénario automatique et enregistre 5 captures PNG dans docs/captures/.
## Nécessite un affichage (Xvfb + Mesa logiciel) : voir tests/captures.sh.

const SCENE_PLONGEE := "res://scenes/dive.tscn"
const DOSSIER := "res://docs/captures/"
const ECHELLE := 2  # 640x360 agrandi ×2 en « plus proche voisin » pour rester lisible

var _plongee: Node
var _bell: CharacterBody2D


func _initialize() -> void:
	_scenario()


func _scenario() -> void:
	await process_frame
	_plongee = load(SCENE_PLONGEE).instantiate()
	root.add_child(_plongee)
	_bell = _plongee.get_node("Bell")
	await _images(30)

	# 1. En surface
	await _capturer("01-surface")

	# 2. Zone 1 : un gisement de cristal en vue, cloche juste à côté (hors de portée)
	var cristal := _gisement_proche("cristal", 450.0)
	_placer_pres_de(cristal, Vector2(-48.0, -22.0))
	await _images(20)
	await _capturer("02-zone1-gisement")

	# 3. Minage en cours : cloche sur le gisement, touche interact maintenue
	_placer_pres_de(cristal, Vector2(18.0, 8.0))
	Input.action_press("interact")
	await _images(33)
	await _capturer("03-minage-jauge")
	Input.action_release("interact")

	# 4. Zone 2 : un gisement de corail, annonce du nom de la zone
	var corail := _gisement_proche("corail", 2200.0)
	_placer_pres_de(corail, Vector2(-48.0, -22.0))
	await _images(20)
	await _capturer("04-zone2")

	# 5. Remontée automatique avec un sac plein : message de perte en surface
	for i in 5:
		_plongee._sac.ajouter("cristal")
	for i in 3:
		_plongee._sac.ajouter("corail")
	_plongee._rafraichir_sac()
	_plongee.oxygene = 0.0
	var images := 0
	while images < 60 * 60:
		await _images(1)
		images += 1
		if images > 5 and not _bell.remontee_auto:
			break
	await _images(15)
	await _capturer("05-perte-de-butin")

	quit(0)


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


func _capturer(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	if image.get_width() != 640 * ECHELLE:
		image.resize(640 * ECHELLE, 360 * ECHELLE, Image.INTERPOLATE_NEAREST)
	var chemin := ProjectSettings.globalize_path(DOSSIER + nom + ".png")
	var erreur := image.save_png(chemin)
	print("%s  %s (%dx%d)" % ["OK  " if erreur == OK else "ERREUR", chemin, image.get_width(), image.get_height()])
