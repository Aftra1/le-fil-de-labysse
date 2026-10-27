extends SceneTree
## Tests de logique (étapes 1 et 2). Lancement : voir tests/lancer.sh ou le README.
## Chaque vérification affiche PASS ou FAIL, puis un total ; code de sortie 1 s'il y a un échec.

const SCENE_PLONGEE := "res://scenes/dive.tscn"
const IMAGES_PAR_S := 60.0

var _reussis := 0
var _total := 0
var _dive_script: GDScript  # chargé après le démarrage des autoloads (dive.gd utilise « Game »)
var _plongee: Node
var _bell: CharacterBody2D
var _jeu: Node


func _initialize() -> void:
	_lancer()


func _lancer() -> void:
	await process_frame
	_jeu = root.get_node("Game")
	_dive_script = load("res://scripts/dive.gd")

	_titre("Étape 1 : cloche, inertie, flottabilité")
	await _test_inertie()
	await _test_flottabilite()
	await _test_bornes()

	_titre("Étape 1 : oxygène et remontée automatique")
	await _test_oxygene_baisse_et_recharge()
	await _test_remontee_automatique()

	_titre("Budget d'oxygène (aller-retour à 300 m, plongée à pleine vitesse)")
	await _test_budget_oxygene()

	_titre("Étape 2 : sac")
	_test_sac()

	_titre("Étape 2 : placement des gisements")
	await _test_placement()

	_titre("Étape 2 : minage")
	await _test_minage()
	await _test_minage_hors_portee()
	await _test_sac_plein()

	_titre("Étape 2 : remontée automatique et perte de butin")
	await _test_perte_de_butin()

	print("")
	print("TOTAL : %d/%d PASS" % [_reussis, _total])
	quit(0 if _reussis == _total else 1)


# --- Outils -----------------------------------------------------------------

func _titre(texte: String) -> void:
	print("")
	print("== %s" % texte)


func _verifier(condition: bool, nom: String, detail: String = "") -> void:
	_total += 1
	if condition:
		_reussis += 1
	var suite := " (%s)" % detail if detail != "" else ""
	print("%s  %s%s" % ["PASS" if condition else "FAIL", nom, suite])


func _images(nombre: int) -> void:
	for i in nombre:
		await physics_frame


func _secondes(duree: float) -> void:
	await _images(int(round(duree * IMAGES_PAR_S)))


func _demarrer() -> void:
	_jeu.stock_ile = {}
	_plongee = load(SCENE_PLONGEE).instantiate()
	root.add_child(_plongee)
	await physics_frame
	_bell = _plongee.get_node("Bell")


func _terminer() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "interact"]:
		Input.action_release(action)
	root.remove_child(_plongee)
	_plongee.queue_free()
	await physics_frame


func _gisements() -> Array[Gisement]:
	var liste: Array[Gisement] = []
	for enfant in _plongee.get_node("Gisements").get_children():
		if not enfant.is_queued_for_deletion():
			liste.append(enfant as Gisement)
	return liste


# --- Étape 1 ----------------------------------------------------------------

func _test_inertie() -> void:
	await _demarrer()
	_bell.position.y = 500.0
	Input.action_press("move_down")
	await _secondes(0.1)
	var vitesse_depart: float = _bell.velocity.y
	_verifier(vitesse_depart > 0.0 and vitesse_depart < Cloche.VITESSE_MAX,
		"inertie : la vitesse monte progressivement", "%.0f px/s après 0,1 s" % vitesse_depart)
	await _secondes(1.0)
	_verifier(is_equal_approx(_bell.velocity.y, Cloche.VITESSE_MAX),
		"inertie : vitesse max atteinte", "%.0f px/s" % _bell.velocity.y)
	Input.action_release("move_down")
	await _secondes(0.2)
	_verifier(_bell.velocity.y > 0.0,
		"inertie : la cloche glisse encore après avoir lâché", "%.0f px/s après 0,2 s" % _bell.velocity.y)
	await _terminer()


func _test_flottabilite() -> void:
	await _demarrer()
	_bell.position.y = 500.0
	await _secondes(3.0)
	_verifier(_bell.position.y < 500.0, "flottabilité : la cloche remonte seule", "y = %.0f" % _bell.position.y)
	_verifier(is_equal_approx(_bell.velocity.y, -Cloche.VITESSE_FLOTTAISON),
		"flottabilité : montée douce à vitesse constante", "%.1f px/s" % _bell.velocity.y)
	await _terminer()


func _test_bornes() -> void:
	await _demarrer()
	Input.action_press("move_up")
	await _secondes(1.0)
	_verifier(_bell.position.y >= 0.0, "bornes : la cloche ne sort pas par le haut", "y = %.1f" % _bell.position.y)
	Input.action_release("move_up")
	Input.action_press("move_left")
	await _secondes(4.0)
	_verifier(is_equal_approx(_bell.position.x, -Cloche.DEMI_LARGEUR_ZONE),
		"bornes : la cloche reste dans la largeur de la zone", "x = %.0f" % _bell.position.x)
	await _terminer()


func _test_oxygene_baisse_et_recharge() -> void:
	await _demarrer()
	_verifier(is_equal_approx(_plongee.oxygene, _dive_script.OXYGENE_MAX), "oxygène : plein au départ")
	_bell.position.y = 500.0
	Input.action_press("move_down")
	await _secondes(2.0)
	_verifier(_plongee.oxygene < _dive_script.OXYGENE_MAX, "oxygène : baisse sous l'eau", "%.1f" % _plongee.oxygene)
	Input.action_release("move_down")
	_bell.position.y = 0.0
	_bell.velocity = Vector2.ZERO
	await _secondes(1.5)
	_verifier(is_equal_approx(_plongee.oxygene, _dive_script.OXYGENE_MAX), "oxygène : rechargé à la surface")
	await _terminer()


func _test_remontee_automatique() -> void:
	await _demarrer()
	_bell.position.y = 1000.0
	_plongee.oxygene = 0.0
	await _images(3)
	_verifier(_bell.remontee_auto, "remontée auto : déclenchée à 0 d'oxygène")
	Input.action_press("move_down")
	await _secondes(0.5)
	_verifier(_bell.velocity.y < 0.0, "remontée auto : les touches sont ignorées", "%.0f px/s" % _bell.velocity.y)
	Input.action_release("move_down")
	var secondes := 0.0
	while _bell.remontee_auto and secondes < 30.0:
		await _secondes(0.5)
		secondes += 0.5
	_verifier(not _bell.remontee_auto and _bell.position.y <= _dive_script.SEUIL_SURFACE,
		"remontée auto : s'arrête en surface", "%.1f s, y = %.0f" % [secondes, _bell.position.y])
	_bell.velocity = Vector2.ZERO
	await _secondes(5.0)
	_verifier(is_equal_approx(_plongee.oxygene, _dive_script.OXYGENE_MAX), "remontée auto : oxygène rechargé en surface")
	await _terminer()


func _test_budget_oxygene() -> void:
	await _demarrer()
	Input.action_press("move_down")
	var t := 0.0
	var mesure_150 := false
	var mesure_300 := false
	var o2_150 := 0.0
	var t_150 := 0.0
	var o2_300 := 0.0
	var t_300 := 0.0
	while not mesure_300 and t < 60.0:
		await _images(1)
		t += 1.0 / IMAGES_PAR_S
		if not mesure_150 and _bell.position.y >= 1500.0:
			mesure_150 = true
			o2_150 = _plongee.oxygene
			t_150 = t
		if _bell.position.y >= _dive_script.PROFONDEUR_MAX - 0.5:
			mesure_300 = true
			o2_300 = _plongee.oxygene
			t_300 = t
	Input.action_release("move_down")
	Input.action_press("move_up")
	var t_retour := 0.0
	while _bell.position.y > _dive_script.SEUIL_SURFACE and t_retour < 60.0:
		await _images(1)
		t_retour += 1.0 / IMAGES_PAR_S
	var o2_retour: float = _plongee.oxygene
	var auto: bool = _bell.remontee_auto
	print("   150 m : %.1f s, oxygène restant %.1f" % [t_150, o2_150])
	print("   300 m : %.1f s, oxygène restant %.1f" % [t_300, o2_300])
	print("   retour en surface : %.1f s, oxygène restant %.1f" % [t_retour, o2_retour])
	_verifier(absf(t_150 - 13.9) < 0.6 and absf(o2_150 - 83.6) < 1.5, "budget : 150 m ≈ 13,9 s, ≈ 84 d'oxygène")
	_verifier(absf(t_300 - 27.5) < 0.8 and absf(o2_300 - 60.7) < 1.5, "budget : 300 m ≈ 27,5 s, ≈ 61 d'oxygène")
	_verifier(not auto and o2_retour > 15.0, "budget : l'aller-retour à 300 m se fait sans remontée d'urgence")
	var secondes_de_minage: float = o2_retour / (_dive_script.CONSOMMATION_PAR_S * 1.4)
	_verifier(secondes_de_minage >= 8.0, "budget : au moins 8 s de minage possibles en zone 2", "%.1f s" % secondes_de_minage)
	await _terminer()


# --- Étape 2 ----------------------------------------------------------------

func _test_sac() -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 1
	var sac := Sac.new()
	_verifier(sac.nombre() == 0 and not sac.est_plein(), "sac : vide au départ")
	for i in Sac.CAPACITE:
		sac.ajouter("cristal")
	_verifier(sac.est_plein() and sac.nombre() == Sac.CAPACITE, "sac : plein à %d unités" % Sac.CAPACITE)
	_verifier(not sac.ajouter("cristal") and sac.nombre() == Sac.CAPACITE, "sac : refuse une unité de trop")
	var perdues := sac.perdre(0.4, hasard)
	_verifier(int(perdues.get("cristal", 0)) == 3 and sac.nombre() == 5, "sac : 8 unités à 40 % → 3 perdues, 5 gardées")

	var petit := Sac.new()
	petit.ajouter("cristal")
	petit.ajouter("corail")
	_verifier(petit.perdre(0.4, hasard).is_empty() and petit.nombre() == 2, "sac : 2 unités à 40 % → rien perdu (arrondi à l'inférieur)")

	var melange := Sac.new()
	for i in 4:
		melange.ajouter("cristal")
	for i in 4:
		melange.ajouter("corail")
	melange.perdre(0.4, hasard)
	var restes := melange.compter()
	_verifier(melange.nombre() == 5 and int(restes.get("cristal", 0)) + int(restes.get("corail", 0)) == 5,
		"sac : la perte est tirée parmi toutes les unités", str(restes))
	var contenu := melange.vider()
	_verifier(melange.nombre() == 0 and int(contenu.get("cristal", 0)) + int(contenu.get("corail", 0)) == 5, "sac : vider renvoie le contenu")


func _test_placement() -> void:
	var ecart_min := 1e9
	var y_min := 1e9
	var x_max := 0.0
	var y_max := 0.0
	var comptes_ok := true
	for generation in 5:
		await _demarrer()
		var liste := _gisements()
		var cristaux := 0
		var coraux := 0
		for gisement in liste:
			y_min = minf(y_min, gisement.position.y)
			y_max = maxf(y_max, gisement.position.y)
			x_max = maxf(x_max, absf(gisement.position.x))
			if gisement.minerai == "cristal":
				cristaux += 1
				comptes_ok = comptes_ok and gisement.position.y < 1500.0
			else:
				coraux += 1
				comptes_ok = comptes_ok and gisement.position.y >= 1500.0
		comptes_ok = comptes_ok and cristaux == 12 and coraux == 8
		for i in liste.size():
			for j in range(i + 1, liste.size()):
				ecart_min = minf(ecart_min, liste[i].position.distance_to(liste[j].position))
		await _terminer()
	_verifier(comptes_ok, "placement : 12 cristaux en zone 1, 8 coraux en zone 2 (5 tirages)")
	_verifier(ecart_min >= _dive_script.ESPACEMENT_MIN, "placement : espacement ≥ 40 px", "min %.1f px" % ecart_min)
	_verifier(y_min >= _dive_script.DISTANCE_MIN_SURFACE, "placement : aucun gisement dans les 10 premiers mètres", "y min %.0f px" % y_min)
	_verifier(x_max <= Cloche.DEMI_LARGEUR_ZONE - _dive_script.MARGE_BORD, "placement : marge par rapport aux bords", "x max %.0f px" % x_max)
	_verifier(y_max <= _dive_script.PROFONDEUR_MAX - _dive_script.MARGE_FOND, "placement : marge au fond", "y max %.0f px" % y_max)


func _test_minage() -> void:
	await _demarrer()
	var gisement := _gisements()[0]
	var stock_avant := gisement.stock
	_bell.position = gisement.position
	_bell.velocity = Vector2.ZERO
	await _images(2)
	_verifier(gisement.en_evidence, "minage : le gisement à portée est mis en évidence")
	Input.action_press("interact")
	await _secondes(0.5)
	_verifier(gisement.progres > 0.4 and gisement.progres < 0.6 and _plongee._sac.nombre() == 0,
		"minage : la jauge avance (mi-parcours à 0,5 s)", "%.2f" % gisement.progres)
	await _secondes(0.6)
	_verifier(_plongee._sac.nombre() == 1 and gisement.stock == stock_avant - 1,
		"minage : 1 unité au sac après ~1 s", "stock %d → %d" % [stock_avant, gisement.stock])
	Input.action_release("interact")
	await _terminer()


func _test_minage_hors_portee() -> void:
	await _demarrer()
	var gisement := _gisements()[0]
	_bell.position = gisement.position
	_bell.velocity = Vector2.ZERO
	Input.action_press("interact")
	await _secondes(0.6)
	_bell.position = gisement.position + Vector2(60.0, 0.0)
	await _images(3)
	_verifier(gisement.progres == 0.0, "minage : la jauge repart à zéro hors de portée")
	_verifier(_plongee._sac.nombre() == 0, "minage : on ne perd que l'unité en cours, rien n'est gagné")
	await _terminer()


func _test_sac_plein() -> void:
	await _demarrer()
	var gisement := _gisements()[0]
	for i in Sac.CAPACITE:
		_plongee._sac.ajouter("cristal")
	_plongee._rafraichir_sac()
	_bell.position = gisement.position
	_bell.velocity = Vector2.ZERO
	Input.action_press("interact")
	await _secondes(1.5)
	_verifier(_plongee._sac.nombre() == Sac.CAPACITE, "sac plein : le minage est bloqué")
	_verifier(gisement.grise, "sac plein : les gisements sont grisés")
	var message: String = _plongee._message_bas(true)
	_verifier(message.contains("remonte"), "sac plein : le message invite à remonter", message)
	await _terminer()


func _test_perte_de_butin() -> void:
	await _demarrer()
	_bell.position.y = 800.0
	for i in 5:
		_plongee._sac.ajouter("cristal")
	for i in 3:
		_plongee._sac.ajouter("corail")
	_plongee.oxygene = 0.0
	var secondes := 0.0
	await _images(3)
	_verifier(_bell.remontee_auto, "perte : remontée automatique déclenchée")
	while _bell.remontee_auto and secondes < 30.0:
		await _secondes(0.5)
		secondes += 0.5
	var stock := 0
	for minerai: String in _jeu.stock_ile:
		stock += int(_jeu.stock_ile[minerai])
	_verifier(stock == 5, "perte : 8 unités → 3 perdues, 5 sauvées sur l'île", str(_jeu.stock_ile))
	_verifier(_plongee._sac.nombre() == 0, "perte : le sac est vide à l'arrivée")
	_verifier(_gisements().size() == 20, "perte : les gisements sont régénérés (20)")
	await _terminer()

	# Remontée volontaire : rien n'est perdu
	await _demarrer()
	_bell.position.y = 800.0
	for i in 8:
		_plongee._sac.ajouter("cristal")
	_plongee._rafraichir_sac()
	Input.action_press("move_up")
	await _secondes(12.0)
	var stock_volontaire := 0
	for minerai: String in _jeu.stock_ile:
		stock_volontaire += int(_jeu.stock_ile[minerai])
	_verifier(stock_volontaire == 8, "remontée volontaire : aucune perte (8 sauvées)", str(_jeu.stock_ile))
	await _terminer()
