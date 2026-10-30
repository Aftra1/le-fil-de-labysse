extends SceneTree
## Tests de logique (étapes 1 à 5). Lancement : voir tests/lancer.sh ou le README.
## Chaque vérification affiche PASS ou FAIL, puis un total ; code de sortie 1 s'il y a un échec.

const SCENE_PLONGEE := "res://scenes/dive.tscn"
const SCENE_ILE := "res://scenes/ile.tscn"
const SCENE_JEU := "res://scenes/jeu.tscn"
const ETAT_ILE := 0
const ETAT_DESCENTE := 1
const ETAT_PLONGEE := 2
const ETAT_REMONTEE := 3
const IMAGES_PAR_S := 60.0
## La vraie sauvegarde n'est jamais touchée : les tests écrivent dans un autre fichier de user://.
const SAUVEGARDE_TESTS := "user://tests_sauvegarde.json"

var _reussis := 0
var _total := 0
# Scripts chargés après le démarrage des autoloads (ils utilisent « Game ») :
# on ne peut donc pas écrire leurs noms de classe (Ile, PanneauInventaire…) dans ce fichier.
var _dive_script: GDScript
var _ile_script: GDScript
var _plongee: Node
var _bell: CharacterBody2D
var _jeu: Node
var _retours: Array = []           # signaux retour_ile reçus : [gardees, perdues, urgence]
var _quitter_demande := 0          # appels au bouton Quitter (remplacé : les tests continuent)


func _initialize() -> void:
	_lancer()


func _lancer() -> void:
	await process_frame
	_jeu = root.get_node("Game")
	Sauvegarde.chemin = SAUVEGARDE_TESTS
	_effacer_sauvegarde()
	_dive_script = load("res://scripts/dive.gd")
	_ile_script = load("res://scripts/ile.gd")

	_titre("Étape 1 : cloche, inertie, flottabilité")
	await _test_inertie()
	await _test_flottabilite()
	await _test_bornes()

	_titre("Étape 1 : oxygène et remontée automatique")
	await _test_oxygene_baisse_et_recharge()
	await _test_remontee_automatique()

	_titre("Budget d'oxygène (aller-retour à 300 m, plongée à pleine vitesse)")
	await _test_budget_oxygene()

	_titre("Étape 4 (partie 2) : budget d'oxygène jusqu'au fond de la Faille (450 m)")
	await _test_budget_faille()

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

	_titre("Étape 3 : retour à l'île seulement après être descendu sous 10 m")
	await _test_armement()

	_titre("Étape 3 : inventaire")
	_test_inventaire()

	_titre("Étape 3 : sources de l'île (recharge)")
	_test_sources()

	_titre("Étape 3 : récolte sur l'île (vrais évènements souris)")
	await _test_recolte()
	await _test_panneau_inventaire()
	await _test_lancer_plongee_depuis_ile()

	_titre("Étape 3 : jeu complet, transitions")
	await _test_scene_principale()
	await _test_transitions()

	_titre("HUD de plongée : entrée et sortie en glissant")
	await _test_glissement_hud()

	_titre("Étape 3 : recharge de l'île pendant la plongée")
	await _test_recharge_pendant_plongee()

	_titre("Étape 3 : remontée d'urgence, butin rangé dans l'inventaire")
	await _test_flux_urgence()

	_titre("Étape 4 : atelier (composants et améliorations)")
	_test_atelier_logique()
	await _test_atelier_ile()

	_titre("Étape 4 : améliorations de la cloche en plongée")
	await _test_limite_cable()
	await _test_reservoir()
	_test_obscurite_regles()
	_test_lueur_braise()

	_titre("Étape 4 : équilibre (sans grind)")
	_test_equilibre()

	_titre("Étape 5 : sauvegarde (fichier, version, fichiers abîmés)")
	_test_sauvegarde_fichier()
	_test_sauvegarde_contenu()

	_titre("Étape 5 : sauvegarde dans le jeu")
	await _test_sauvegarde_jeu()
	await _test_sauvegarde_automatique()

	_titre("Étape 5 : écran titre")
	await _test_ecran_titre()

	_titre("Étape 5 : menu pause et Échap")
	await _test_pause_ile()
	await _test_pause_plongee()
	await _test_echap_transition()

	_titre("Étape 5 : îlot, passerelle de nuage et bassin de lumière")
	_test_ilot_logique()
	await _test_ilot_ile()
	await _test_ilot_sauvegarde()

	_titre("Machines (palier 1) : emplacements, moulin à vent, filet à nuages")
	_test_machines_logique()
	await _test_machines_ile()
	await _test_machines_sauvegarde()

	_titre("Palier 2 : îlot du nord, foreuse solaire, entrepôt, sac à 12 places, améliorations")
	_test_palier2_logique()
	await _test_palier2_ile()
	await _test_palier2_sauvegarde()
	await _test_sac_12()

	_titre("Clics : un nuage qui passe devant ne vole jamais le clic")
	await _test_nuages_devant()

	_titre("Trouvailles rares et carnet de collection")
	_test_carnet_logique()
	await _test_trouvailles_plongee()
	await _test_carnet_panneau()
	await _test_carnet_sauvegarde()

	_titre("Palier 3 : fourneau et raffinés, sonde, arche de braise, sac à 16 places, niveaux 2")
	_test_palier3_logique()
	await _test_palier3_ile()
	await _test_palier3_sauvegarde()

	_titre("Marchand de vent : passages, échanges, répliques")
	_test_marchand_logique()
	await _test_marchand_ile()
	await _test_marchand_plongee_et_sauvegarde()

	_titre("Équilibrage final et confort (PR E)")
	_test_equilibrage_final()
	await _test_confort_carnet()
	await _test_confort_interface()

	_titre("Audio : synthèse, bus, volumes, sauvegarde")
	_test_synthese()
	_test_bus_et_volumes()
	await _test_ambiances()

	_titre("Audio : sons déclenchés par le jeu")
	await _test_sons_ile()
	await _test_sons_plongee()
	await _test_sons_transitions()
	await _test_volumes_sauvegarde()

	_titre("Rendu pixel art")
	_test_rendu_pixel()
	await _test_monde_320()
	await _test_camera_plongee()

	_effacer_sauvegarde()
	print("")
	print("TOTAL : %d/%d PASS" % [_reussis, _total])
	await _couper_son_et_quitter(0 if _reussis == _total else 1)


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
	_jeu.inventaire = Inventaire.new()
	_retours.clear()
	_plongee = load(SCENE_PLONGEE).instantiate()
	_plongee.retour_ile.connect(func(gardees: Dictionary, perdues: Dictionary, urgence: bool) -> void:
		_retours.append([gardees, perdues, urgence]))
	root.add_child(_plongee)
	await physics_frame
	_bell = _plongee.get_node("Bell")


func _terminer() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "interact"]:
		Input.action_release(action)
	root.remove_child(_plongee)
	_plongee.queue_free()
	await physics_frame


func _somme(butin: Dictionary) -> int:
	var total := 0
	for id: String in butin:
		total += int(butin[id])
	return total


## Évènements souris envoyés en coordonnées fenêtre (le jeu les ramène en 640x360).
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
	_bell.position.y = 50.0   # 5 m : sous l'eau, mais au-dessus du seuil de retour à l'île (10 m)
	_bell.stabilisee = true
	await _secondes(2.0)
	_verifier(_plongee.oxygene < _dive_script.OXYGENE_MAX, "oxygène : baisse sous l'eau", "%.1f" % _plongee.oxygene)
	_bell.stabilisee = false
	_bell.position.y = 0.0
	_bell.velocity = Vector2.ZERO
	await _secondes(1.5)
	_verifier(is_equal_approx(_plongee.oxygene, _dive_script.OXYGENE_MAX), "oxygène : rechargé à la surface")
	await _terminer()


func _test_remontee_automatique() -> void:
	# À 8 m (au-dessus du seuil de 10 m) : la remontée automatique de l'étape 1 reste dans la plongée.
	await _demarrer()
	_bell.position.y = 80.0
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

	# En profondeur : à l'arrivée en surface, la plongée se termine et la cloche repart vers l'île.
	await _demarrer()
	_bell.position.y = 1000.0
	_plongee.oxygene = 0.0
	secondes = 0.0
	while _retours.is_empty() and secondes < 30.0:
		await _secondes(0.5)
		secondes += 0.5
	_verifier(_retours.size() == 1 and _retours[0][2] == true,
		"remontée auto en profondeur : retour vers l'île (signal, urgence)", "%.1f s" % secondes)
	await _terminer()

func _test_budget_oxygene() -> void:
	await _demarrer()
	# Le câble de départ s'arrête à 150 m : on installe le câble tressé (300 m) pour mesurer le budget.
	_jeu.atelier.niveaux["cable"] = 1
	_plongee.appliquer_ameliorations()
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
		if _bell.position.y >= _plongee.limite_px - 0.5:
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
	_verifier(absf(t_300 - 27.5) < 0.8 and absf(o2_300 - 59.1) < 1.5, "budget : 300 m ≈ 27,5 s, ≈ 59 d'oxygène")
	_verifier(not auto and o2_retour > 15.0, "budget : l'aller-retour à 300 m se fait sans remontée d'urgence")
	var conso_coraux := float(Donnees.charger_json("res://data/zones.json")[1]["conso_oxygene"])
	var secondes_de_minage: float = o2_retour / (_dive_script.CONSOMMATION_PAR_S * conso_coraux)
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
	var zones: Array = Donnees.charger_json("res://data/zones.json")
	var y_min_cristal := 1e9
	var y_min_corail := 1e9
	var y_min_braise := 1e9
	for generation in 5:
		await _demarrer()
		var liste := _gisements()
		var cristaux := 0
		var coraux := 0
		var braises := 0
		for gisement in liste:
			y_min = minf(y_min, gisement.position.y)
			y_max = maxf(y_max, gisement.position.y)
			x_max = maxf(x_max, absf(gisement.position.x))
			if gisement.minerai == "trouvaille":
				continue    # les éclats de trouvaille sont vérifiés à part (espacement et marges ci-dessus)
			if gisement.minerai == "cristal_lagon":
				cristaux += 1
				y_min_cristal = minf(y_min_cristal, gisement.position.y)
				comptes_ok = comptes_ok and gisement.position.y < 1500.0
			elif gisement.minerai == "corail":
				coraux += 1
				y_min_corail = minf(y_min_corail, gisement.position.y)
				comptes_ok = comptes_ok and gisement.position.y >= 1500.0 and gisement.position.y < 3000.0
			else:
				braises += 1
				y_min_braise = minf(y_min_braise, gisement.position.y)
				comptes_ok = comptes_ok and gisement.minerai == "pierre_braise" and gisement.position.y >= 3000.0
		comptes_ok = comptes_ok and cristaux == int(zones[0]["gisements"]) and coraux == int(zones[1]["gisements"]) \
			and braises == int(zones[2]["gisements"])
		for i in liste.size():
			for j in range(i + 1, liste.size()):
				ecart_min = minf(ecart_min, liste[i].position.distance_to(liste[j].position))
		await _terminer()
	_verifier(comptes_ok, "placement : %d cristaux en zone 1, %d coraux en zone 2, %d pierres de braise en zone 3 (5 tirages)"
		% [int(zones[0]["gisements"]), int(zones[1]["gisements"]), int(zones[2]["gisements"])])
	_verifier(y_min_braise >= 3050.0, "placement : pierres de braise à partir de 305 m (hors de portée du câble de 300 m)",
		"y min %.0f px" % y_min_braise)
	_verifier(y_min_cristal >= 300.0, "placement : cristaux de lagon à partir de 30 m", "y min %.0f px" % y_min_cristal)
	_verifier(y_min_corail >= 1550.0, "placement : coraux à partir de 155 m (hors de portée du câble de 150 m)",
		"y min %.0f px" % y_min_corail)
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
	# Vers le centre : près du bord, la cloche serait ramenée à portée par la limite de la zone.
	_bell.position = gisement.position + Vector2(-60.0 if gisement.position.x > 0.0 else 60.0, 0.0)
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
		_plongee._sac.ajouter("cristal_lagon")
	for i in 3:
		_plongee._sac.ajouter("corail")
	_plongee.oxygene = 0.0
	var secondes := 0.0
	await _images(3)
	_verifier(_bell.remontee_auto, "perte : remontée automatique déclenchée")
	while _retours.is_empty() and secondes < 30.0:
		await _secondes(0.5)
		secondes += 0.5
	var recu: Array = _retours[0] if not _retours.is_empty() else [{}, {}, false]
	_verifier(_somme(recu[0]) == 5 and _somme(recu[1]) == 3 and recu[2] == true,
		"perte : 8 unités → 3 perdues, 5 sauvées (envoyées à l'île)", "gardées %s, perdues %s" % [recu[0], recu[1]])
	_verifier(_plongee._sac.nombre() == 0, "perte : le sac est vide à l'arrivée")
	await _images(30)
	_verifier(_retours.size() == 1, "perte : la fin de plongée n'est signalée qu'une fois")
	await _terminer()

	# Remontée volontaire : rien n'est perdu
	await _demarrer()
	_bell.position.y = 800.0
	for i in 8:
		_plongee._sac.ajouter("cristal_lagon")
	_plongee._rafraichir_sac()
	Input.action_press("move_up")
	await _secondes(12.0)
	recu = _retours[0] if not _retours.is_empty() else [{}, {}, true]
	_verifier(_somme(recu[0]) == 8 and recu[1].is_empty() and recu[2] == false,
		"remontée volontaire : aucune perte (8 sauvées)", str(recu[0]))
	await _terminer()


# --- Étape 3 ----------------------------------------------------------------

func _test_armement() -> void:
	await _demarrer()
	var profondeur_max := 0.0
	Input.action_press("move_down")
	for i in 15:
		await _images(1)
		profondeur_max = maxf(profondeur_max, _bell.position.y)
	Input.action_release("move_down")
	Input.action_press("move_up")
	for i in 120:
		await _images(1)
		profondeur_max = maxf(profondeur_max, _bell.position.y)
	Input.action_release("move_up")
	_verifier(_bell.position.y <= _dive_script.SEUIL_SURFACE and _retours.is_empty(),
		"manœuvre près de la surface : rien ne se déclenche", "profondeur max %.1f m" % (profondeur_max / 10.0))

	_bell.position.y = 80.0
	_bell.velocity = Vector2.ZERO
	Input.action_press("move_up")
	await _secondes(2.0)
	Input.action_release("move_up")
	_verifier(_bell.position.y <= _dive_script.SEUIL_SURFACE and _retours.is_empty(),
		"descente à 8 m puis surface : rien ne se déclenche")
	_verifier(_bell.controle_actif, "descente à 8 m puis surface : on garde le contrôle")

	_bell.position.y = 120.0
	_bell.velocity = Vector2.ZERO
	await _images(2)
	Input.action_press("move_up")
	await _secondes(2.0)
	Input.action_release("move_up")
	_verifier(_retours.size() == 1 and _retours[0][2] == false,
		"descente à 12 m puis surface : retour vers l'île", "%d signal(aux)" % _retours.size())
	_verifier(not _bell.controle_actif, "après le retour : la cloche ne se pilote plus")
	_verifier(is_equal_approx(_dive_script.PROFONDEUR_ARMEMENT_M, 10.0), "seuil de retour : constante à 10 m")
	await _terminer()


func _test_inventaire() -> void:
	var inventaire := Inventaire.new()
	_verifier(inventaire.total() == 0 and inventaire.quantite("vent") == 0, "inventaire : vide au départ")
	inventaire.ajouter("vent", 3)
	inventaire.ajouter("corail")
	_verifier(inventaire.quantite("vent") == 3 and inventaire.quantite("corail") == 1 and inventaire.total() == 4,
		"inventaire : ajouter et compter")
	var ajoute := inventaire.ajouter("nuage", 120)
	_verifier(ajoute == Inventaire.PLAFOND and inventaire.quantite("nuage") == Inventaire.PLAFOND,
		"inventaire : plafond de %d par ressource" % Inventaire.PLAFOND, "ajouté %d" % ajoute)
	var refuse := inventaire.ajouter_tout({ "nuage": 2, "cristal_lagon": 5 })
	_verifier(int(refuse.get("nuage", 0)) == 2 and inventaire.quantite("cristal_lagon") == 5,
		"inventaire : un butin trop gros renvoie ce qui n'entre pas", str(refuse))
	_verifier(inventaire.retirer("vent", 2) and inventaire.quantite("vent") == 1, "inventaire : retirer")
	_verifier(not inventaire.retirer("vent", 5) and inventaire.quantite("vent") == 1, "inventaire : retrait impossible refusé")


func _source(plafond: int, recharge_s: float) -> SourceRessource:
	var source := SourceRessource.new()
	source.plafond = plafond
	source.recharge_s = recharge_s
	source.stock = 0
	return source


func _test_sources() -> void:
	var reglages: Dictionary = Donnees.charger_json("res://data/ile.json")
	var eolienne: Dictionary = reglages["eolienne"]
	var filons: Dictionary = reglages["filons"]

	var vent := _source(int(eolienne["plafond"]), float(eolienne["recharge_s"]))
	vent.recharger(5.0)
	_verifier(vent.stock == 0, "éolienne vide + 5 s : presque rien", "%d/%d" % [vent.stock, vent.plafond])
	vent.recharger(55.0)
	_verifier(vent.stock == vent.plafond, "éolienne vide + 60 s : pleine", "%d/%d" % [vent.stock, vent.plafond])
	vent.recharger(600.0)
	_verifier(vent.stock == vent.plafond, "éolienne : ne dépasse jamais son plafond")
	_verifier(vent.prendre(10) == vent.plafond and vent.stock == 0, "éolienne : vider la réserve d'un coup")

	var filon := _source(int(filons["plafond"]), float(filons["recharge_s"]))
	filon.recharger(5.0)
	_verifier(filon.stock == 0, "filon vide + 5 s : presque rien")
	filon.recharger(55.0)
	_verifier(filon.stock == filon.plafond, "filon vide + 60 s : plein", "%d/%d" % [filon.stock, filon.plafond])

	var progressif := _source(5, 12.0)
	for i in 300:
		progressif.recharger(0.1)
	_verifier(progressif.stock == 2, "recharge par petits pas = recharge d'un coup (30 s → 2)", str(progressif.stock))
	vent.free()
	filon.free()
	progressif.free()


func _ouvrir_ile() -> Node:
	_jeu.inventaire = Inventaire.new()
	var ile: Node = load(SCENE_ILE).instantiate()
	root.add_child(ile)
	await _images(3)
	return ile


func _fermer_ile(ile: Node) -> void:
	_bouton(Vector2.ZERO, false)
	root.remove_child(ile)
	ile.queue_free()
	await _images(2)


## Premier nuage de l'île, immobile et cliquable. Les nuages naissent au hasard entre y = 52 et 86, sous
## les boutons du haut ; par prudence, s'il touchait le bouton « Inventaire » (un clic ouvrirait alors
## l'inventaire, qui bloque tous les clics suivants), on le déplace (c'est le premier des nuages parcourus
## au survol : un autre nuage au même endroit ne gêne pas).
func _nuage_degage(ile: Node) -> SourceRessource:
	var nuage: SourceRessource = ile.get_node("Nuages").get_child(0)
	nuage.derive = 0.0
	var bouton: Control = ile.get_node("HUD").bouton_inventaire
	if bouton.get_global_rect().grow(4.0).has_point(nuage.position):
		nuage.position = Vector2(320.0, 90.0)
	return nuage


func _test_recolte() -> void:
	var ile := await _ouvrir_ile()

	var nuage := _nuage_degage(ile)
	var prises: int = nuage.stock
	await _cliquer(nuage.position)
	_verifier(_jeu.inventaire.quantite("nuage") == 2 and nuage.stock == prises - 1,
		"nuage : un clic = deux ouates de nuage (une prise)", "stock %d → %d" % [prises, nuage.stock])

	var eolienne: SourceRessource = ile._eolienne
	var reserve: int = eolienne.stock
	await _cliquer(eolienne.position)
	_verifier(reserve > 0 and _jeu.inventaire.quantite("vent") == reserve and eolienne.stock == 0,
		"éolienne : un clic récupère toute la réserve", "%d vent" % reserve)

	var filon: SourceRessource = ile._filons[0]
	var stock_filon: int = filon.stock
	_souris(filon.position)
	await _images(2)
	_bouton(filon.position, true)
	await _secondes(0.5)
	_verifier(filon.progres > 0.4 and filon.progres < 0.6 and _jeu.inventaire.quantite("cristal_solaire") == 0,
		"filon : la jauge avance en maintenant le clic", "%.2f" % filon.progres)
	await _secondes(0.6)
	_verifier(_jeu.inventaire.quantite("cristal_solaire") == 1 and filon.stock == stock_filon - 1,
		"filon : 1 cristal solaire après ~1 s de maintien")
	await _secondes(0.5)
	_souris(filon.position + Vector2(0.0, 60.0))  # sous l'île : aucune source
	await _images(2)
	_verifier(filon.progres == 0.0, "filon : la jauge repart à zéro si la souris s'écarte")
	await _secondes(1.0)
	_bouton(filon.position, false)
	_verifier(_jeu.inventaire.quantite("cristal_solaire") == 1, "filon : rien n'est gagné hors du filon")

	filon.stock = 0
	await _cliquer(filon.position)
	_bouton(filon.position, true)
	await _secondes(1.2)
	_bouton(filon.position, false)
	_verifier(_jeu.inventaire.quantite("cristal_solaire") == 1, "filon vide : on ne récolte rien")
	await _fermer_ile(ile)


func _test_panneau_inventaire() -> void:
	var ile := await _ouvrir_ile()
	var panneau: Node = ile.get_node("Inventaire")
	_touche(KEY_I)
	await _images(2)
	_verifier(panneau.est_ouvert(), "inventaire : la touche I ouvre le panneau")
	_touche(KEY_I)
	await _images(2)
	_verifier(not panneau.est_ouvert(), "inventaire : la touche I le referme")
	_touche(KEY_TAB)
	await _images(2)
	var ouvert_tab: bool = panneau.est_ouvert()
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(ouvert_tab and not panneau.est_ouvert(), "inventaire : Tab ouvre, Échap ferme")

	var nuage: SourceRessource = ile.get_node("Nuages").get_child(0)
	nuage.derive = 0.0
	nuage.position = Vector2(24.0, 346.0)  # hors du panneau (sinon le clic tombe sur le panneau)
	panneau.ouvrir()
	await _cliquer(nuage.position)
	_verifier(_jeu.inventaire.quantite("nuage") == 0, "inventaire ouvert : un clic ne récolte pas")
	_verifier(not panneau.est_ouvert(), "inventaire ouvert : un clic à côté ferme le panneau")

	ile._interface.bouton_inventaire.pressed.emit()
	await _images(2)
	_verifier(panneau.est_ouvert(), "inventaire : le bouton ouvre le panneau")
	panneau.fermer()
	await _fermer_ile(ile)


func _test_lancer_plongee_depuis_ile() -> void:
	var ile := await _ouvrir_ile()
	var demandes := [0]
	ile.plongee_demandee.connect(func() -> void: demandes[0] += 1)
	await _cliquer(_ile_script.POSITION_CLOCHE)
	_verifier(demandes[0] == 1, "île : un clic sur la cloche lance la plongée")
	_touche(KEY_E)
	await _images(2)
	_verifier(demandes[0] == 2, "île : E lance aussi la plongée")
	await _fermer_ile(ile)


func _ouvrir_jeu(avec_titre: bool = false) -> Node:
	_jeu.inventaire = Inventaire.new()
	var jeu: Node = load(SCENE_JEU).instantiate()
	jeu.avec_titre = avec_titre
	jeu.action_quitter = func() -> void: _quitter_demande += 1
	root.add_child(jeu)
	await _images(3)
	return jeu


func _fermer_jeu(jeu: Node) -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "interact"]:
		Input.action_release(action)
	root.remove_child(jeu)
	jeu.queue_free()
	await _images(2)


## Attend un état du jeu ; renvoie le temps écoulé (ou -1 si dépassé).
func _attendre_etat(jeu: Node, etat: int, limite: float = 30.0) -> float:
	var secondes := 0.0
	while jeu.etat != etat:
		if secondes > limite:
			return -1.0
		await _images(1)
		secondes += 1.0 / IMAGES_PAR_S
	return secondes


## Termine la plongée en cours : la cloche passe sous 10 m puis revient en surface.
func _remonter(jeu: Node) -> void:
	var cloche: CharacterBody2D = jeu.plongee().get_node("Bell")
	cloche.position.y = 150.0
	cloche.velocity = Vector2.ZERO
	await _images(2)
	cloche.position.y = 0.0
	await _images(2)


func _test_scene_principale() -> void:
	_verifier(ProjectSettings.get_setting("application/run/main_scene") == SCENE_JEU, "la scène principale est jeu.tscn")


func _test_transitions() -> void:
	var jeu := await _ouvrir_jeu()
	_verifier(jeu.etat == ETAT_ILE, "le jeu commence sur l'île")
	await _cliquer(_ile_script.POSITION_CLOCHE)
	_verifier(jeu.etat == ETAT_DESCENTE, "clic sur la cloche : la descente commence")
	var duree := await _attendre_etat(jeu, ETAT_PLONGEE)
	_verifier(absf(duree - 2.5) < 0.15, "descente : dure environ 2,5 s", "%.2f s" % duree)
	var cloche: Node2D = jeu.plongee().get_node("Bell")
	_verifier(cloche.position == Vector2.ZERO, "descente : la plongée commence avec la cloche en surface")
	_verifier(not jeu.get_node("Ile").visible, "plongée : l'île est cachée")

	await _remonter(jeu)
	_verifier(jeu.etat == ETAT_REMONTEE, "retour en surface (après 10 m) : la remontée commence")
	await _secondes(0.3)
	_touche(KEY_SPACE)
	var reste := await _attendre_etat(jeu, ETAT_ILE)
	_verifier(reste >= 0.0 and reste < 0.5, "remontée : une touche la termine en moins de 0,5 s", "%.2f s" % reste)
	_verifier(jeu.get_node("Ile").visible and jeu.get_node("Ile").position == Vector2.ZERO,
		"remontée : l'île est de retour à sa place")

	_touche(KEY_E)
	await _images(2)
	_verifier(jeu.etat == ETAT_DESCENTE, "E sur l'île : nouvelle descente")
	await _secondes(0.2)
	_bouton(Vector2(100.0, 100.0), true)
	_bouton(Vector2(100.0, 100.0), false)
	var reste_clic := await _attendre_etat(jeu, ETAT_PLONGEE)
	_verifier(reste_clic >= 0.0 and reste_clic < 0.5, "descente : un clic la termine en moins de 0,5 s", "%.2f s" % reste_clic)
	_verifier(is_equal_approx(jeu.plongee().oxygene, _dive_script.OXYGENE_MAX), "nouvelle plongée : oxygène à 100 %")
	await _fermer_jeu(jeu)


## Vide les sources de l'île, plonge « duree » secondes, revient ;
## renvoie [vent, plafond vent, cristaux, plafond cristaux, temps sous l'eau].
func _plongee_de(duree: float) -> Array:
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	ile._eolienne.stock = 0
	ile._eolienne._accumulateur = 0.0
	for filon: SourceRessource in ile._filons:
		filon.stock = 0
		filon._accumulateur = 0.0
	_touche(KEY_E)
	await _images(2)
	jeu.get_node("Transition").passer()
	await _attendre_etat(jeu, ETAT_PLONGEE)
	await _secondes(duree)
	await _remonter(jeu)
	jeu.get_node("Transition").passer()
	await _attendre_etat(jeu, ETAT_ILE)
	var cristaux := 0
	var plafond_cristaux := 0
	for filon: SourceRessource in ile._filons:
		cristaux += filon.stock
		plafond_cristaux += filon.plafond
	var resultat := [ile._eolienne.stock, ile._eolienne.plafond, cristaux, plafond_cristaux, jeu.temps_plongee]
	await _fermer_jeu(jeu)
	return resultat


func _test_recharge_pendant_plongee() -> void:
	var courte := await _plongee_de(5.0)
	_verifier(courte[0] + courte[2] <= 1, "plongée courte (5 s) : l'île ne recharge presque rien",
		"vent %d/%d, cristaux %d/%d, %.1f s sous l'eau" % courte)
	var longue := await _plongee_de(60.0)
	var part := float(longue[0] + longue[2]) / float(longue[1] + longue[3])
	_verifier(part >= 0.9, "plongée longue (60 s) : l'île a presque tout rechargé",
		"vent %d/%d, cristaux %d/%d, %.1f s sous l'eau" % longue)
	_verifier(longue[0] <= longue[1] and longue[2] <= longue[3], "recharge pendant la plongée : plafonds respectés")


func _test_flux_urgence() -> void:
	var jeu := await _ouvrir_jeu()
	_touche(KEY_E)
	await _images(2)
	jeu.get_node("Transition").passer()
	await _attendre_etat(jeu, ETAT_PLONGEE)
	var plongee: Node = jeu.plongee()
	plongee.get_node("Bell").position.y = 400.0
	for i in 5:
		plongee._sac.ajouter("cristal_lagon")
	for i in 3:
		plongee._sac.ajouter("corail")
	await _images(3)
	plongee.oxygene = 0.0
	var duree := await _attendre_etat(jeu, ETAT_REMONTEE)
	_verifier(duree > 0.0, "urgence : la cloche remonte seule puis repart vers l'île", "%.1f s" % duree)
	_verifier(_somme({ "a": _jeu.inventaire.quantite("cristal_lagon"), "b": _jeu.inventaire.quantite("corail") }) == 0,
		"urgence : le butin n'est rangé qu'après la transition")
	await _attendre_etat(jeu, ETAT_ILE)
	var ranges: int = _jeu.inventaire.quantite("cristal_lagon") + _jeu.inventaire.quantite("corail")
	_verifier(ranges == 5, "urgence : 5 unités sur 8 rangées dans l'inventaire", "%d" % ranges)
	var annonce: String = jeu.get_node("Ile/HUD").texte_annonce()
	_verifier(annonce.contains("perdu 3"), "urgence : l'île annonce la perte", annonce)
	await _fermer_jeu(jeu)


# --- Rendu pixel art ------------------------------------------------------------

func _test_rendu_pixel() -> void:
	var noms := Palette.noms()
	_verifier(noms.size() >= 48 and noms.size() <= 64, "palette : entre 48 et 64 couleurs", "%d" % noms.size())
	var rampes_ok := true
	for nom_rampe in ["ciel", "nuage", "roche", "herbe", "or", "lagon", "corail", "abysse", "interface"]:
		rampes_ok = rampes_ok and Palette.rampe(nom_rampe).size() >= 4
	_verifier(rampes_ok, "palette : une rampe de tons par matière (ciel, nuage, roche, herbe, or, lagon, corail, abysse, interface)")
	var ombre := Palette.plus_sombre(Palette.couleur("herbe.4"))
	_verifier(ombre == Palette.couleur("herbe.3") and Palette.plus_sombre(Palette.couleur("herbe.0")) == Palette.couleur("herbe.0"),
		"palette : « un ton plus sombre » descend d'un cran dans la même rampe")

	var inconnues: Array = []
	var ressources: Dictionary = Donnees.charger_json("res://data/ressources.json")
	for id: String in ressources:
		if not Palette.contient(str(ressources[id]["couleur"])):
			inconnues.append(ressources[id]["couleur"])
	for zone: Dictionary in Donnees.charger_json("res://data/zones.json"):
		for nom: String in zone["paliers"]:
			if not Palette.contient(nom):
				inconnues.append(nom)
	_verifier(inconnues.is_empty(), "données : toutes les couleurs sont des noms de la palette", str(inconnues))

	var police: FontFile = load("res://assets/fonts/DotGothic16-Regular.ttf")
	_verifier(police.antialiasing == TextServer.FONT_ANTIALIASING_NONE
		and police.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED,
		"police : sans antialiasing ni positionnement sous-pixel")
	_verifier(ProjectSettings.get_setting("gui/theme/custom_font") == "res://assets/fonts/DotGothic16-Regular.ttf",
		"police : DotGothic16 est la police du projet")
	_verifier(FileAccess.file_exists("res://assets/fonts/OFL-DotGothic16.txt"), "police : licence OFL fournie")
	_verifier(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0,
		"textures : filtrage « nearest »")

	var cloche := Pixel.motif(Cloche.MOTIF, Cloche.COULEURS_MOTIF)
	_verifier(cloche.get_width() >= 16 and cloche.get_width() <= 24 and cloche.get_height() >= 16 and cloche.get_height() <= 24,
		"cloche : sprite de 16 à 24 px", "%dx%d" % [cloche.get_width(), cloche.get_height()])
	var lignes_regulieres := true
	for motif: PackedStringArray in [Cloche.MOTIF, Gisement.CRISTAL, Gisement.CORAIL, SourceRessource.FILON]:
		for ligne in motif:
			lignes_regulieres = lignes_regulieres and ligne.length() == motif[0].length()
	_verifier(lignes_regulieres, "sprites : dessins rectangulaires (toutes les lignes ont la même largeur)")


func _test_monde_320() -> void:
	var ile := await _ouvrir_ile()
	var monde: Node = ile.get_node("Monde")
	_verifier(monde.taille_monde() == Vector2i(320, 180) and VueMonde.ECHELLE == 2,
		"île : le monde est rendu en 320x180, affiché ×2")
	var eolienne: Node2D = ile._eolienne
	_verifier(eolienne.position == Vector2(206, 150), "île : la logique garde ses positions en 640x360")
	await _fermer_ile(ile)

	# Un nuage lent avance d'un pixel du monde (2 px en 640x360) à intervalle fixe.
	var nuage := SourceRessource.new()
	nuage.derive = 8.0
	root.add_child(nuage)
	var pas_ok := true
	var intervalles: Array[int] = []
	var depuis := 0
	var x := nuage.position.x
	for i in 240:
		await physics_frame
		depuis += 1
		var avance := nuage.position.x - x
		if avance != 0.0:
			pas_ok = pas_ok and is_equal_approx(avance, 2.0)
			intervalles.append(depuis)
			depuis = 0
			x = nuage.position.x
	root.remove_child(nuage)
	nuage.free()
	var reguliers := intervalles.size() > 2
	for i in range(1, intervalles.size()):
		reguliers = reguliers and intervalles[i] == intervalles[1]
	_verifier(pas_ok, "nuages : chaque pas fait exactement un pixel du monde")
	_verifier(reguliers, "nuages : les pas sont réguliers (pas de saccades)", "un pas toutes les %s images" % [intervalles.slice(1, 4)])


func _test_camera_plongee() -> void:
	await _demarrer()
	_verifier(_plongee.get_node("Monde").taille_monde() == Vector2i(320, 180), "plongée : le monde est rendu en 320x180, affiché ×2")
	_bell.position.y = 1201.0
	_bell.velocity = Vector2.ZERO
	_bell.controle_actif = false   # cloche immobile (ni pilotage ni flottabilité)
	await _images(1)
	var cible: Vector2 = _plongee._cible_camera()
	_verifier(int(cible.y) % 2 == 0 and cible.y == roundf(cible.y),
		"caméra : vise la position dessinée de la cloche (pixel entier du monde)", "haut %.0f" % cible.y)
	var apres_une_image: float = _plongee._camera.y
	_verifier(apres_une_image > -90.0 and apres_une_image < cible.y,
		"caméra : rattrape la cloche en douceur (pas de saut)", "%.1f après une image, cible %.0f" % [apres_une_image, cible.y])
	await _secondes(2.0)
	_verifier(_plongee._camera == _plongee._cible_camera(), "caméra : s'arrête exactement sur sa cible (pas de tremblement)",
		"%s / %s, cloche %s" % [_plongee._camera, _plongee._cible_camera(), _bell.position])
	await _terminer()


func _test_glissement_hud() -> void:
	var jeu := await _ouvrir_jeu()
	var transition: Node = jeu.get_node("Transition")
	_touche(KEY_E)
	await _images(2)
	var interface: CanvasLayer = jeu.plongee().get_node("HUD")
	while transition.temps_restant() > 0.5:
		await _images(1)
	_verifier(not interface.visible, "descente : le HUD est absent avant les 0,3 dernières secondes")
	while transition.temps_restant() > 0.15:
		await _images(1)
	var progression: float = interface.progression_glissement()
	var decalage: Vector2 = interface.decalage_panneau_etat()
	_verifier(interface.visible and progression > 0.0 and progression < 1.0 and decalage.x < 0.0,
		"descente : le HUD glisse depuis le bord gauche pendant les 0,3 dernières secondes",
		"progression %.2f, décalage %s" % [progression, decalage])
	_verifier(decalage == decalage.round(), "glissement : décalage au pixel entier")
	await _attendre_etat(jeu, ETAT_PLONGEE)
	_verifier(interface.visible and interface.progression_glissement() == 1.0 and interface.decalage_panneau_etat() == Vector2.ZERO,
		"arrivée : le HUD est en place")
	var opaque := true
	for enfant in interface.get_children():
		if enfant is CanvasItem:
			opaque = opaque and (enfant as CanvasItem).modulate.a == 1.0 and (enfant as CanvasItem).self_modulate.a == 1.0
	_verifier(opaque, "glissement : aucune transparence")

	var label_profondeur: String = jeu.plongee()._interface._profondeur.text
	_verifier(label_profondeur != "", "le HUD est rempli dès son entrée", label_profondeur)

	await _remonter(jeu)
	await _secondes(0.1)
	progression = interface.progression_glissement()
	_verifier(interface.visible and progression > 0.0 and progression < 1.0 and interface.decalage_panneau_etat().x < 0.0,
		"remontée : le HUD ressort en glissant pendant les 0,3 premières secondes", "progression %.2f" % progression)
	await _secondes(0.4)
	_verifier(not interface.visible, "remontée : le HUD a disparu après 0,3 s")
	await _attendre_etat(jeu, ETAT_ILE)
	await _fermer_jeu(jeu)


# --- Étape 4 ----------------------------------------------------------------

func _test_atelier_logique() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	_verifier(not atelier.fabriquer("fil_nuage") and inventaire.quantite("fil_nuage") == 0,
		"atelier : fabrication refusée sans ingrédients", str(atelier.manquants(atelier.ingredients_composant("fil_nuage"))))
	inventaire.ajouter("nuage", 3)
	inventaire.ajouter("vent", 1)
	_verifier(atelier.fabriquer("fil_nuage") and inventaire.quantite("fil_nuage") == 1
		and inventaire.quantite("nuage") == 0 and inventaire.quantite("vent") == 0,
		"atelier : un fil de nuage consomme 3 nuages et 1 vent")
	_verifier(atelier.longueur_cable_m() == 150.0 and atelier.oxygene_max() == 100.0
		and atelier.rayon_halo() == 40.0 and atelier.obscurite_max() == 3,
		"atelier : valeurs de départ (câble 150 m, oxygène 100, halo 40, obscurité 3)")
	_verifier(not atelier.ameliorer("cable") and atelier.niveau("cable") == 0, "amélioration refusée sans ingrédients")
	inventaire.ajouter("fil_nuage", 2)
	inventaire.ajouter("cristal_lagon", 4)
	_verifier(atelier.ameliorer("cable") and atelier.niveau("cable") == 1 and atelier.longueur_cable_m() == 300.0
		and inventaire.quantite("fil_nuage") == 0 and inventaire.quantite("cristal_lagon") == 0,
		"câble tressé : installé, ingrédients retirés, câble à 300 m")
	inventaire.ajouter("fil_nuage", 9)
	inventaire.ajouter("cristal_lagon", 9)
	_verifier(not atelier.ameliorer("cable") and atelier.niveau("cable") == 1,
		"câble niveau 2 : refusé sans corail ni cristal solaire")
	inventaire.ajouter("corail", 2)
	inventaire.ajouter("cristal_solaire", 3)
	_verifier(atelier.ameliorer("cable") and atelier.niveau("cable") == 2 and atelier.longueur_cable_m() == 450.0,
		"câble niveau 2 : 4 fils de nuage, 2 coraux, 3 cristaux solaires ; câble à 450 m")
	inventaire.ajouter("fil_nuage", 9)
	inventaire.ajouter("corail", 9)
	inventaire.ajouter("cristal_solaire", 9)
	_verifier(not atelier.ameliorer("cable") and atelier.est_au_maximum("cable") and atelier.prochain_niveau("cable").is_empty(),
		"câble : niveau maximal (2) atteint, rien de plus à installer")
	inventaire.ajouter("lentille", 1)
	inventaire.ajouter("corail", 5)
	_verifier(atelier.ameliorer("lanterne") and atelier.rayon_halo() == 60.0 and atelier.obscurite_max() == 2,
		"lanterne de cristal : halo 40 → 60, obscurité 3 → 2 tons")
	inventaire.ajouter("poche_air", 2)
	_verifier(atelier.ameliorer("reservoir") and atelier.oxygene_max() == 150.0, "réservoir d'air : oxygène 100 → 150")
	inventaire.ajouter("poche_air", 3)
	inventaire.ajouter("cristal_lagon", 3)
	inventaire.ajouter("corail", 2)
	_verifier(atelier.ameliorer("reservoir") and atelier.oxygene_max() == 200.0, "réservoir niveau 2 : oxygène 150 → 200")
	inventaire.ajouter("lentille", 2)
	_verifier(not atelier.ameliorer("lanterne") and atelier.niveau("lanterne") == 1,
		"lanterne niveau 2 : refusée sans pierre de braise")
	inventaire.ajouter("pierre_braise", 4)
	_verifier(atelier.ameliorer("lanterne") and atelier.rayon_halo() == 80.0 and atelier.obscurite_max() == 1,
		"lanterne niveau 2 : 2 lentilles, 4 pierres de braise ; halo 80, obscurité au plus 1 ton")


func _test_atelier_ile() -> void:
	var ile := await _ouvrir_ile()
	var atelier: Node = ile.get_node("Atelier")
	_touche(KEY_C)
	await _images(2)
	_verifier(atelier.est_ouvert(), "atelier : la touche C l'ouvre")
	_touche(KEY_C)
	await _images(2)
	_verifier(not atelier.est_ouvert(), "atelier : la touche C le referme")
	await _cliquer(_ile_script.POSITION_CABANE)
	_verifier(atelier.est_ouvert(), "atelier : un clic sur la cabane l'ouvre")
	var nuage: SourceRessource = ile.get_node("Nuages").get_child(0)
	nuage.derive = 0.0
	nuage.position = Vector2(24.0, 346.0)   # hors du panneau de l'atelier, qui est large
	await _cliquer(nuage.position)
	_verifier(not atelier.est_ouvert() and _jeu.inventaire.quantite("nuage") == 0,
		"atelier ouvert : un clic à côté le ferme sans récolter")
	atelier.ouvrir()
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(not atelier.est_ouvert(), "atelier : Échap le ferme")

	atelier.ouvrir()
	atelier.choisir_onglet("composants")
	atelier.selectionner("fil_nuage")
	_verifier(atelier._bouton.disabled, "atelier : bouton Fabriquer inactif s'il manque des ingrédients")
	_jeu.inventaire.ajouter("nuage", 3)
	_jeu.inventaire.ajouter("vent", 1)
	atelier.rafraichir()
	_verifier(not atelier._bouton.disabled, "atelier : bouton Fabriquer actif quand tout est là")
	atelier._bouton.pressed.emit()
	await _images(2)
	var annonce: String = ile.get_node("HUD").texte_annonce()
	_verifier(_jeu.inventaire.quantite("fil_nuage") == 1 and annonce.contains("Fil de nuage"),
		"atelier : le bouton fabrique le composant et l'île l'annonce", annonce)
	atelier.fermer()
	await _fermer_ile(ile)


func _test_limite_cable() -> void:
	await _demarrer()
	_bell.position.y = 1400.0
	Input.action_press("move_down")
	await _secondes(3.0)
	_verifier(_bell.position.y <= 1500.0 and _bell.position.y >= 1499.0, "câble de départ : la cloche s'arrête à 150 m",
		"%.1f m" % (_bell.position.y / 10.0))
	var message: String = _plongee._message_bas(true)
	_verifier(message == "Câble au maximum (150 m)", "câble de départ : message au bout du câble", message)
	_jeu.atelier.niveaux["cable"] = 1
	_plongee.appliquer_ameliorations()
	await _secondes(2.0)
	Input.action_release("move_down")
	_verifier(_bell.position.y > 1600.0, "câble tressé : on descend plus bas que 150 m", "%.1f m" % (_bell.position.y / 10.0))
	await _terminer()


func _test_reservoir() -> void:
	await _demarrer()
	var largeur_base: float = _plongee._interface.largeur_jauge()
	await _terminer()
	_jeu.atelier.niveaux["reservoir"] = 1
	_plongee = load(SCENE_PLONGEE).instantiate()
	root.add_child(_plongee)
	await _images(2)
	_verifier(_plongee.oxygene == 150.0 and _plongee.oxygene_max == 150.0, "réservoir : la plongée commence avec 150 d'oxygène")
	_verifier(_plongee._interface.largeur_jauge() == largeur_base * 1.5, "réservoir : la jauge du HUD est 1,5 fois plus longue",
		"%.0f px" % _plongee._interface.largeur_jauge())
	root.remove_child(_plongee)
	_plongee.queue_free()
	await _images(2)
	_jeu.atelier.niveaux["reservoir"] = 2
	_plongee = load(SCENE_PLONGEE).instantiate()
	root.add_child(_plongee)
	await _images(2)
	_verifier(_plongee.oxygene_max == 200.0 and _plongee._interface.largeur_jauge() == largeur_base * 2.0,
		"réservoir niveau 2 : 200 d'oxygène, jauge 2 fois plus longue", "%.0f px" % _plongee._interface.largeur_jauge())
	root.remove_child(_plongee)
	_plongee.queue_free()
	_jeu.atelier.niveaux["reservoir"] = 0
	await _images(2)


func _test_obscurite_regles() -> void:
	_verifier(ArtAbysse.niveau_obscurite(30.0, 3) == 0 and ArtAbysse.niveau_obscurite(50.0, 3) == 1
		and ArtAbysse.niveau_obscurite(90.0, 3) == 2 and ArtAbysse.niveau_obscurite(140.0, 3) == 3,
		"obscurité : rien avant 40 m, puis un ton de plus tous les 40 m (3 au plus)")
	_verifier(ArtAbysse.niveau_obscurite(140.0, 2) == 2, "obscurité : la lanterne limite le noir à 2 tons")
	_verifier(ArtAbysse.crans_halo(0.0, 40.0) == 0 and ArtAbysse.crans_halo(45.0, 40.0) == 1
		and ArtAbysse.crans_halo(55.0, 40.0) == 2 and ArtAbysse.crans_halo(90.0, 40.0) == 3,
		"halo : anneaux de 10 pixels du monde autour de la cloche")
	var eau := Palette.couleur("lagon.3")
	_verifier(ArtAbysse.assombrir(eau, 140.0, 0.0, 40.0, 3) == eau, "halo : un pixel au centre n'est pas assombri")
	_verifier(ArtAbysse.assombrir(eau, 140.0, 200.0, 40.0, 3) == Palette.couleur("lagon.0"),
		"obscurité : loin de la cloche, un pixel perd exactement 3 tons dans sa rampe")
	_verifier(ArtAbysse.assombrir(Palette.couleur("cyan.3"), 140.0, 200.0, 40.0, 3) == Palette.couleur("cyan.3"),
		"obscurité : la bioluminescence n'est jamais assombrie")


## Simulation prudente de la boucle : entre deux plongées, l'île donne 5 vents, 6 nuages et 3 cristaux
## solaires ; une plongée rapporte un sac de 8 (lagon seulement tant que le câble fait 150 m).
## On fabrique ce qui sert à la prochaine amélioration. Tout doit être débloqué en 6 plongées au plus.
func _test_equilibre() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	var plongees := 0
	var installe := func() -> bool:
		return atelier.niveau("cable") >= 1 and atelier.niveau("lanterne") >= 1 and atelier.niveau("reservoir") >= 1
	while not installe.call() and plongees < 20:
		inventaire.ajouter("vent", 5)
		inventaire.ajouter("nuage", 6)
		inventaire.ajouter("cristal_solaire", 3)
		plongees += 1
		if atelier.niveau("cable") == 0:
			inventaire.ajouter("cristal_lagon", 8)
		else:
			inventaire.ajouter("cristal_lagon", 4)
			inventaire.ajouter("corail", 4)
		var encore := true
		while encore:
			encore = false
			for id: String in ["cable", "lanterne", "reservoir"]:
				if atelier.ameliorer(id):
					encore = true
			var besoins := {
				"fil_nuage": 3 if atelier.niveau("cable") == 0 else 0,
				"lentille": 1 if atelier.niveau("lanterne") == 0 else 0,
				"poche_air": 2 if atelier.niveau("reservoir") == 0 else 0,
			}
			for id: String in besoins:
				if inventaire.quantite(id) < int(besoins[id]) and atelier.fabriquer(id):
					encore = true
	_verifier(installe.call() and plongees <= 6, "les 3 améliorations de niveau 1 en 6 plongées au plus", "%d plongées" % plongees)



# --- Étape 5 : sauvegarde, écran titre, menu pause -------------------------------------

func _effacer_sauvegarde() -> void:
	var base := SAUVEGARDE_TESTS.get_basename()
	for chemin: String in [SAUVEGARDE_TESTS, base + ".bak", base + ".tmp", base + ".corrompue.json", base + ".version-99.json"]:
		if FileAccess.file_exists(chemin):
			DirAccess.remove_absolute(chemin)


func _ecrire_texte(chemin: String, texte: String) -> void:
	var fichier := FileAccess.open(chemin, FileAccess.WRITE)
	fichier.store_string(texte)
	fichier.close()


func _lire_texte(chemin: String) -> String:
	return FileAccess.get_file_as_string(chemin) if FileAccess.file_exists(chemin) else ""


func _partie_exemple() -> Dictionary:
	return {
		"inventaire": {"vent": 4, "fil_nuage": 2},
		"ameliorations": {"cable": 1, "lanterne": 0, "reservoir": 1},
		"ilots": [],
		"ile": {"eolienne": {"stock": 1, "recharge": 3.0}, "filons": [{"stock": 0, "recharge": 0.0}]},
	}


## Lecture et écriture du fichier : absent, aller-retour, copie de secours, fichiers abîmés, versions.
func _test_sauvegarde_fichier() -> void:
	var base := SAUVEGARDE_TESTS.get_basename()
	_verifier(ProjectSettings.get_setting("application/config/use_custom_user_dir") == true
		and ProjectSettings.get_setting("application/config/custom_user_dir_name") == "Le Fil de l'Abysse",
		"dossier utilisateur personnalisé : « Le Fil de l'Abysse » (%APPDATA% sous Windows)")
	_effacer_sauvegarde()
	var absente := Sauvegarde.lire()
	_verifier(absente["statut"] == Sauvegarde.Statut.ABSENTE and not Sauvegarde.existe(),
		"fichier absent : statut « absente », aucun plantage")

	var ecrit := Sauvegarde.ecrire(_partie_exemple(), 1000.0)
	var lu := Sauvegarde.lire()
	var partie: Dictionary = lu["partie"]
	_verifier(ecrit and lu["statut"] == Sauvegarde.Statut.OK, "écriture puis lecture : statut OK")
	_verifier(int(partie["version"]) == Sauvegarde.VERSION and float(partie["horodatage"]) == 1000.0,
		"le fichier porte le numéro de version et la date", "version %d" % int(partie["version"]))
	_verifier(int(partie["inventaire"]["vent"]) == 4 and int(partie["ameliorations"]["reservoir"]) == 1
		and int(partie["ile"]["eolienne"]["stock"]) == 1, "aller-retour : inventaire, améliorations et île identiques")
	_verifier(not FileAccess.file_exists(base + ".bak"), "première écriture : pas encore de copie de secours")

	Sauvegarde.ecrire({"inventaire": {"vent": 9}, "ameliorations": {}, "ilots": [], "ile": {}}, 2000.0)
	_verifier(FileAccess.file_exists(base + ".bak") and not FileAccess.file_exists(base + ".tmp"),
		"écriture sûre : l'ancienne partie devient la copie de secours, pas de fichier temporaire restant")
	_verifier(int(Sauvegarde.lire()["partie"]["inventaire"]["vent"]) == 9, "la nouvelle partie remplace l'ancienne")

	# JSON illisible : mis de côté, la copie de secours est reprise.
	_ecrire_texte(SAUVEGARDE_TESTS, "{ pas du json")
	var abimee := Sauvegarde.lire()
	_verifier(abimee["statut"] == Sauvegarde.Statut.RECUPEREE and int(abimee["partie"]["inventaire"]["vent"]) == 4,
		"fichier illisible : la copie de secours est reprise")
	_verifier(FileAccess.file_exists(base + ".corrompue.json") and _lire_texte(base + ".corrompue.json") == "{ pas du json",
		"fichier illisible : mis de côté tel quel (jamais supprimé)")
	_verifier(str(abimee["message"]) != "", "fichier illisible : un message l'explique", str(abimee["message"]))

	# Illisible et sans copie de secours : nouvelle partie, sans planter.
	_effacer_sauvegarde()
	_ecrire_texte(SAUVEGARDE_TESTS, "[1, 2, 3]")
	var corrompue := Sauvegarde.lire()
	_verifier(corrompue["statut"] == Sauvegarde.Statut.CORROMPUE and (corrompue["partie"] as Dictionary).is_empty(),
		"contenu qui n'est pas une sauvegarde, sans secours : statut « corrompue », partie vide")
	_effacer_sauvegarde()
	_ecrire_texte(SAUVEGARDE_TESTS, "")
	_verifier(Sauvegarde.lire()["statut"] == Sauvegarde.Statut.CORROMPUE, "fichier vide : statut « corrompue »")

	# Écriture interrompue : fichier principal absent, copie de secours présente.
	_effacer_sauvegarde()
	Sauvegarde.ecrire(_partie_exemple())
	DirAccess.rename_absolute(SAUVEGARDE_TESTS, base + ".bak")
	_verifier(Sauvegarde.lire()["statut"] == Sauvegarde.Statut.RECUPEREE, "fichier principal manquant : la copie de secours est reprise")

	# Version plus récente : jamais modifiée, mise de côté avant une nouvelle partie.
	_effacer_sauvegarde()
	var future := '{"version": 99, "inventaire": {"vent": 1}}'
	_ecrire_texte(SAUVEGARDE_TESTS, future)
	var recente := Sauvegarde.lire()
	_verifier(recente["statut"] == Sauvegarde.Statut.TROP_RECENTE and _lire_texte(SAUVEGARDE_TESTS) == future,
		"version plus récente : statut dédié, fichier intact")
	Sauvegarde.mettre_de_cote_version_recente()
	_verifier(not FileAccess.file_exists(SAUVEGARDE_TESTS) and _lire_texte(base + ".version-99.json") == future,
		"version plus récente : mise de côté avant une nouvelle partie, jamais écrasée")

	# Migration depuis la version 0 (premier format fictif, sans numéro de version).
	_effacer_sauvegarde()
	_ecrire_texte(SAUVEGARDE_TESTS, '{"inventaire": {"vent": 3}, "ameliorations": {"cable": 1}}')
	var ancienne := Sauvegarde.lire()
	var migree: Dictionary = ancienne["partie"]
	_verifier(ancienne["statut"] == Sauvegarde.Statut.OK and int(migree["version"]) == Sauvegarde.VERSION
		and migree["ilots"] is Array and migree["ile"] is Dictionary and int(migree["inventaire"]["vent"]) == 3,
		"version 0 : migrée vers la version actuelle (îlots et île ajoutés, inventaire gardé)")
	_effacer_sauvegarde()


## Valeurs fausses ou incomplètes : ignorées ou ramenées dans les limites.
func _test_sauvegarde_contenu() -> void:
	var migree := Sauvegarde.migrer({"version": 1, "inventaire": "faux", "ilots": 3, "horodatage": "hier"})
	_verifier(migree["inventaire"] is Dictionary and (migree["inventaire"] as Dictionary).is_empty()
		and migree["ameliorations"] is Dictionary and migree["ilots"] is Array and float(migree["horodatage"]) == 0.0,
		"champs de mauvais type ou manquants : remplacés par des valeurs vides")

	var inventaire := Inventaire.depuis_dictionnaire({"vent": 150, "nuage": -4, "inconnu": 3, "corail": "x"},
		_jeu.ressources.keys())
	_verifier(inventaire.quantite("vent") == 150 and inventaire.quantite("nuage") == 0
		and inventaire.quantite("inconnu") == 0 and inventaire.total() == 150,
		"inventaire lu : quantités bornées à 0..499 (plafond de l'entrepôt), ressources inconnues ignorées")
	Atelier.new(inventaire).charger_machines({})
	_verifier(inventaire.quantite("vent") == Inventaire.PLAFOND, "sans entrepôt : quantités ramenées à 99")
	_verifier(Inventaire.depuis_dictionnaire(Inventaire.depuis_dictionnaire({"vent": 7}, ["vent"]).vers_dictionnaire(),
		["vent"]).quantite("vent") == 7, "inventaire : aller-retour vers le dictionnaire")

	var atelier := Atelier.new(Inventaire.new())
	atelier.charger_niveaux({"cable": 7, "lanterne": -2, "reservoir": "x", "inconnue": 1})
	_verifier(atelier.niveau("cable") == atelier.niveau_max("cable") and atelier.niveau("lanterne") == 0
		and atelier.niveau("reservoir") == 0 and not atelier.niveaux.has("inconnue"),
		"améliorations : niveaux bornés, inconnues ignorées")

	var source := _source(5, 12.0)
	source.restaurer({"stock": 40, "recharge": 99.0})
	var trop_plein := source.stock == 5
	source.restaurer({"stock": 1, "recharge": 99.0})
	_verifier(trop_plein and source.stock == 1 and source.etat()["recharge"] == 12.0,
		"source : stock et recharge bornés", str(source.etat()))
	source.free()

	_verifier(Sauvegarde.secondes_depuis({"horodatage": 5000.0}, 1000.0) == 0.0
		and Sauvegarde.secondes_depuis({"horodatage": 1000.0}, 1300.0) == 300.0,
		"temps écoulé depuis la sauvegarde : jamais négatif (horloge reculée)")


## Sauvegarder une partie, puis la reprendre par l'écran titre ; rattrapage du temps jeu fermé.
func _test_sauvegarde_jeu() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	_jeu.inventaire.ajouter("vent", 6)
	_jeu.inventaire.ajouter("lentille", 1)
	_jeu.atelier.niveaux["cable"] = 1
	ile._eolienne.stock = 1
	for filon: SourceRessource in ile._filons:
		filon.stock = 0
	_verifier(jeu.sauvegarder(), "sur l'île : la partie est sauvegardée")
	var partie: Dictionary = jeu.donnees_partie()
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	_verifier(not jeu._titre.bouton_continuer.disabled, "sauvegarde présente : Continuer est actif")
	jeu._titre.bouton_continuer.pressed.emit()
	await _images(2)
	ile = jeu.get_node("Ile")
	_verifier(_jeu.inventaire.vers_dictionnaire() == partie["inventaire"], "Continuer : inventaire retrouvé",
		str(_jeu.inventaire.vers_dictionnaire()))
	_verifier(_jeu.atelier.niveau("cable") == 1 and _jeu.atelier.niveau("lanterne") == 0, "Continuer : améliorations retrouvées")
	_verifier(ile._eolienne.stock == 1 and ile._filons[0].stock == 0, "Continuer : état des sources retrouvé")
	_verifier(jeu.partie_en_cours and not paused, "Continuer : la partie reprend (jeu non figé)")
	await _fermer_jeu(jeu)

	# Jeu fermé 30 s : l'éolienne (1 vent / 8 s) gagne 3 vents ; filons (1 / 20 s) : 1 cristal.
	Sauvegarde.ecrire(partie, Time.get_unix_time_from_system() - 30.0)
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	ile = jeu.get_node("Ile")
	_verifier(ile._eolienne.stock == 4 and ile._filons[0].stock == 1, "hors jeu (30 s) : les sources ont rattrapé le temps",
		"éolienne %d, filon %d" % [ile._eolienne.stock, ile._filons[0].stock])
	await _fermer_jeu(jeu)

	# Jeu fermé une semaine : plafonné.
	Sauvegarde.ecrire(partie, Time.get_unix_time_from_system() - 7.0 * 24.0 * 3600.0)
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	ile = jeu.get_node("Ile")
	_verifier(ile._eolienne.stock == ile._eolienne.plafond and ile._filons[0].stock == ile._filons[0].plafond
		and _jeu.inventaire.quantite("vent") == 6, "hors jeu (une semaine) : sources pleines mais plafonnées, inventaire inchangé")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


func _inventaire_sauve() -> Dictionary:
	return Sauvegarde.lire()["partie"].get("inventaire", {})


## Moments de sauvegarde : fabrication, départ, fermeture en plongée (état du départ), retour.
func _test_sauvegarde_automatique() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	_jeu.inventaire.ajouter("nuage", 3)
	_jeu.inventaire.ajouter("vent", 1)
	var atelier: Node = ile.get_node("Atelier")
	atelier.ouvrir()
	atelier.choisir_onglet("composants")
	atelier.selectionner("fil_nuage")
	atelier.fabriquer_selection()
	atelier.fermer()
	await _images(2)
	_verifier(int(_inventaire_sauve().get("fil_nuage", 0)) == 1, "fabrication : la partie est sauvegardée")

	_jeu.inventaire.ajouter("vent", 2)
	await _cliquer(_ile_script.POSITION_CLOCHE)
	_verifier(jeu.etat == ETAT_DESCENTE and int(_inventaire_sauve().get("vent", 0)) == 2,
		"départ en plongée : la partie est sauvegardée")
	await _attendre_etat(jeu, ETAT_PLONGEE)
	# Butin en cours : ajouté à l'inventaire seulement au retour ; fermer maintenant garde l'état du départ.
	var avant := _lire_texte(SAUVEGARDE_TESTS)
	jeu.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_verifier(_lire_texte(SAUVEGARDE_TESTS) == avant, "fermeture en pleine plongée : la sauvegarde du départ est gardée")

	jeu.plongee()._sac.ajouter("corail")
	await _remonter(jeu)
	await _attendre_etat(jeu, ETAT_ILE)
	_verifier(int(_inventaire_sauve().get("corail", 0)) == 1, "retour sur l'île : la partie est sauvegardée avec le butin")

	_jeu.inventaire.ajouter("vent", 1)
	jeu.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_verifier(int(_inventaire_sauve().get("vent", 0)) == 3, "fermeture de la fenêtre sur l'île : la partie est sauvegardée")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


func _centre(controle: Control) -> Vector2:
	return controle.get_global_rect().get_center()


func _test_ecran_titre() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu(true)
	var titre: Node = jeu._titre
	var ile: Node = jeu.get_node("Ile")
	_verifier(titre.est_ouvert() and paused and not jeu.partie_en_cours, "démarrage : écran titre, jeu figé")
	_verifier(not ile.get_node("HUD").visible, "écran titre : l'interface de l'île est cachée")
	_verifier(titre.bouton_continuer.disabled, "sans sauvegarde : Continuer est grisé")
	await _cliquer(_centre(titre.bouton_continuer))
	_verifier(titre.est_ouvert(), "Continuer grisé : un clic ne fait rien")
	await _cliquer(_centre(titre.bouton_nouvelle))
	_verifier(not titre.est_ouvert() and jeu.partie_en_cours and not paused and ile.get_node("HUD").visible,
		"Nouvelle partie (clic) : le jeu commence sur l'île")
	_verifier(FileAccess.file_exists(SAUVEGARDE_TESTS), "Nouvelle partie : la partie est sauvegardée tout de suite")
	_jeu.inventaire.ajouter("vent", 5)
	jeu.sauvegarder()
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	titre = jeu._titre
	await _cliquer(_centre(titre.bouton_nouvelle))
	_verifier(titre.confirmation_ouverte() and titre.est_ouvert(), "partie existante : Nouvelle partie demande confirmation")
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(not titre.confirmation_ouverte() and titre.est_ouvert(), "confirmation : Échap annule")
	await _cliquer(_centre(titre.bouton_nouvelle))
	await _cliquer(_centre(titre.bouton_annuler))
	_verifier(not titre.confirmation_ouverte() and int(_inventaire_sauve().get("vent", 0)) == 5,
		"confirmation : Annuler garde la partie")
	await _cliquer(_centre(titre.bouton_nouvelle))
	await _cliquer(_centre(titre.bouton_remplacer))
	_verifier(not titre.est_ouvert() and _jeu.inventaire.total() == 0 and _inventaire_sauve().is_empty(),
		"confirmation : Remplacer lance une nouvelle partie (inventaire vide, sauvegardé)")
	await _fermer_jeu(jeu)

	_effacer_sauvegarde()   # sans copie de secours
	_ecrire_texte(SAUVEGARDE_TESTS, "{ abîmée")
	jeu = await _ouvrir_jeu(true)
	titre = jeu._titre
	_verifier(titre.bouton_continuer.disabled and titre.message() != "",
		"sauvegarde illisible : Continuer grisé et message à l'écran titre", titre.message())
	await _cliquer(_centre(titre.bouton_nouvelle))
	_verifier(not titre.est_ouvert() and jeu.partie_en_cours, "sauvegarde illisible : Nouvelle partie sans confirmation")
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	_quitter_demande = 0
	await _cliquer(_centre(jeu._titre.bouton_quitter))
	_verifier(_quitter_demande == 1, "écran titre : Quitter ferme le jeu")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


func _test_pause_ile() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var pause: Node = jeu._pause
	var ile: Node = jeu.get_node("Ile")
	ile.get_node("Inventaire").ouvrir()
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(not ile.get_node("Inventaire").est_ouvert() and not pause.est_ouvert(),
		"Échap avec un panneau ouvert : ferme le panneau, pas de pause")
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(pause.est_ouvert() and paused, "Échap sur l'île : menu pause, jeu figé")
	var stock_avant: int = ile._filons[0].stock
	ile._filons[0].stock = 0
	await _secondes(1.0)
	_verifier(ile._filons[0].stock == 0, "pause : les sources ne se rechargent pas")
	ile._filons[0].stock = stock_avant
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(not pause.est_ouvert() and not paused, "Échap dans le menu pause : reprend")
	_touche(KEY_ESCAPE)
	await _images(2)
	await _cliquer(_centre(pause.bouton_reprendre))
	_verifier(not pause.est_ouvert() and not paused, "bouton Reprendre : reprend")

	_jeu.inventaire.ajouter("cristal_solaire", 2)
	_touche(KEY_ESCAPE)
	await _images(2)
	await _cliquer(_centre(pause.bouton_titre))
	_verifier(jeu._titre.est_ouvert() and not pause.est_ouvert() and int(_inventaire_sauve().get("cristal_solaire", 0)) == 2,
		"Retour au titre depuis l'île : écran titre, partie sauvegardée")
	await _cliquer(_centre(jeu._titre.bouton_continuer))
	_verifier(not jeu._titre.est_ouvert() and _jeu.inventaire.quantite("cristal_solaire") == 2,
		"puis Continuer : la partie reprend")

	_jeu.inventaire.ajouter("cristal_solaire", 1)
	_touche(KEY_ESCAPE)
	await _images(2)
	_quitter_demande = 0
	await _cliquer(_centre(pause.bouton_quitter))
	_verifier(_quitter_demande == 1 and int(_inventaire_sauve().get("cristal_solaire", 0)) == 3,
		"Quitter depuis la pause : partie sauvegardée puis jeu fermé")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


func _test_pause_plongee() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var pause: Node = jeu._pause
	_jeu.inventaire.ajouter("vent", 4)
	_touche(KEY_E)
	await _attendre_etat(jeu, ETAT_PLONGEE)
	var plongee: Node = jeu.plongee()
	# Sous l'eau (en surface, l'oxygène se recharge).
	var cloche: CharacterBody2D = plongee.get_node("Bell")
	cloche.position.y = 150.0
	cloche.velocity = Vector2.ZERO
	await _secondes(0.5)
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(pause.est_ouvert() and paused, "Échap en plongée : menu pause")
	_verifier(pause.note().contains("butin"), "pause en plongée : rappelle que le butin sera perdu", pause.note())
	var oxygene: float = plongee.oxygene
	var temps: float = jeu.temps_plongee
	await _secondes(1.0)
	_verifier(plongee.oxygene == oxygene and jeu.temps_plongee == temps, "pause en plongée : l'oxygène ne baisse pas")
	await _cliquer(_centre(pause.bouton_reprendre))
	await _secondes(0.5)
	_verifier(plongee.oxygene < oxygene, "Reprendre : l'oxygène baisse de nouveau")

	plongee._sac.ajouter("corail")
	_touche(KEY_ESCAPE)
	await _images(2)
	await _cliquer(_centre(pause.bouton_titre))
	await _images(2)
	_verifier(jeu._titre.est_ouvert() and jeu.etat == ETAT_ILE and jeu.plongee() == null,
		"Retour au titre en plongée : la plongée est abandonnée")
	_verifier(_inventaire_sauve().get("corail", 0) == 0 and int(_inventaire_sauve().get("vent", 0)) == 4,
		"Retour au titre en plongée : la sauvegarde du départ est gardée (butin perdu)")
	await _cliquer(_centre(jeu._titre.bouton_continuer))
	var ile: Node = jeu.get_node("Ile")
	_verifier(ile.visible and ile.cloche_visible and ile.process_mode == Node.PROCESS_MODE_INHERIT
		and _jeu.inventaire.quantite("vent") == 4, "puis Continuer : retour sur l'île, comme au départ")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


## Échap pendant la descente et la remontée : ignoré (ni pause, ni transition passée).
func _test_echap_transition() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	_touche(KEY_E)
	await _secondes(0.5)
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(jeu.etat == ETAT_DESCENTE and not jeu._pause.est_ouvert(), "Échap pendant la descente : pas de pause")
	var reste := await _attendre_etat(jeu, ETAT_PLONGEE)
	_verifier(reste > 1.5, "Échap pendant la descente : la transition n'est pas passée",
		"%.2f s restantes" % reste)

	await _remonter(jeu)
	await _secondes(0.3)
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(jeu.etat == ETAT_REMONTEE and not jeu._pause.est_ouvert(), "Échap pendant la remontée : pas de pause")
	var reste_remontee := await _attendre_etat(jeu, ETAT_ILE)
	_verifier(reste_remontee > 1.0, "Échap pendant la remontée : la transition n'est pas passée",
		"%.2f s restantes" % reste_remontee)
	_verifier(not jeu._pause.est_ouvert(), "après la remontée : pas de menu pause en attente")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


# --- Étape 5 : îlot ---------------------------------------------------------------------

func _ingredients_passerelle(inventaire: Inventaire) -> void:
	inventaire.ajouter("fil_nuage", 4)
	inventaire.ajouter("cristal_solaire", 3)
	inventaire.ajouter("corail", 2)


func _test_ilot_logique() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	_verifier(not atelier.est_relie("ilot_est") and atelier.ilot_de("passerelle") == "ilot_est",
		"départ : l'îlot n'est pas relié")
	_verifier(not atelier.construire("passerelle") and atelier.ilots_relies.is_empty(), "passerelle refusée sans ingrédients")
	_ingredients_passerelle(inventaire)
	_verifier(atelier.construire("passerelle") and atelier.est_relie("ilot_est") and inventaire.total() == 0,
		"passerelle de nuage : 4 fils de nuage, 3 cristaux solaires, 2 coraux ; l'îlot est relié")
	_ingredients_passerelle(inventaire)
	_verifier(not atelier.peut_construire("passerelle") and not atelier.construire("passerelle")
		and atelier.ilots_relies.size() == 1, "passerelle : ne se construit qu'une fois")
	atelier.charger_ilots(["ilot_est", "inconnu", "ilot_est"])
	_verifier(atelier.ilots_relies == ["ilot_est"], "îlots lus d'une sauvegarde : inconnus et doublons ignorés")
	atelier.charger_ilots([])
	_verifier(not atelier.est_relie("ilot_est"), "îlots lus d'une sauvegarde : liste vide, rien de relié")


func _test_ilot_ile() -> void:
	var ile := await _ouvrir_ile()
	var bassin: SourceRessource = ile.bassin()
	var atelier: Node = ile.get_node("Atelier")
	_verifier(bassin.get_parent() == null, "îlot non relié : le bassin n'est pas sur l'île")
	bassin.stock = 0
	ile.rattraper(1000.0)
	_verifier(bassin.stock == 0, "îlot non relié : le bassin ne se remplit pas")
	bassin.stock = 1

	_souris(ile.centre_ilot())
	await _images(2)
	var aide: String = ile._texte_aide()
	_verifier(aide.contains("Îlot isolé") and aide.contains("passerelle"), "survol de l'îlot non relié : l'aide le dit", aide)
	_bouton(bassin.position, true)
	await _secondes(1.2)
	_bouton(bassin.position, false)
	await _images(2)
	_verifier(_jeu.inventaire.quantite("cristal_lagon") == 0, "îlot non relié : aucune récolte possible")
	_verifier(atelier.est_ouvert() and atelier.onglet == "construction",
		"clic sur l'îlot non relié : l'atelier s'ouvre sur l'onglet Construction")

	atelier.selectionner("passerelle")
	_verifier(atelier._bouton.disabled, "Construire inactif s'il manque des ingrédients")
	_ingredients_passerelle(_jeu.inventaire)
	atelier.rafraichir()
	_verifier(ile._fabrication_possible(), "passerelle possible : la cabane s'allume")
	atelier._bouton.pressed.emit()
	await _images(2)
	var annonce: String = ile.get_node("HUD").texte_annonce()
	_verifier(ile.ilot_relie() and bassin.get_parent() == ile.get_node("Sources") and annonce.contains("Îlot relié"),
		"Construire : l'îlot est relié, le bassin apparaît, l'île l'annonce", annonce)
	_verifier(atelier._effet.text.contains("Construite") and atelier._bouton.disabled,
		"atelier : la passerelle est indiquée comme construite")
	atelier.fermer()
	await _images(2)

	_souris(bassin.position)
	await _images(2)
	var aide_bassin: String = ile._texte_aide()
	_verifier(aide_bassin.contains("Cristal de lagon") and not aide_bassin.contains("Îlot isolé"),
		"îlot relié : survol du bassin", aide_bassin)
	_bouton(bassin.position, true)
	await _secondes(1.2)
	_bouton(bassin.position, false)
	await _images(2)
	_verifier(_jeu.inventaire.quantite("cristal_lagon") == 1 and bassin.stock == 0,
		"bassin de lumière : maintenir le clic donne 1 cristal de lagon", "stock %d" % bassin.stock)
	ile.rattraper(45.0)
	var apres_45 := bassin.stock
	ile.rattraper(10000.0)
	_verifier(apres_45 == 1 and bassin.stock == bassin.plafond and bassin.plafond == 3,
		"bassin : 1 cristal toutes les 45 s, 3 au plus", "%d puis %d" % [apres_45, bassin.stock])
	await _fermer_ile(ile)


## Aller-retour sauvegarde / chargement avec l'îlot relié (liste des îlots, stock du bassin).
func _test_ilot_sauvegarde() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	_ingredients_passerelle(_jeu.inventaire)
	var atelier: Node = ile.get_node("Atelier")
	atelier.ouvrir()
	atelier.choisir_onglet("construction")
	atelier.fabriquer_selection()
	atelier.fermer()
	await _images(2)
	var sauvee: Dictionary = Sauvegarde.lire()["partie"]
	_verifier(sauvee["ilots"] == ["ilot_est"], "construction : sauvegardée tout de suite (îlot relié)", str(sauvee["ilots"]))
	ile.bassin().stock = 2
	jeu.sauvegarder()
	sauvee = Sauvegarde.lire()["partie"]
	_verifier(int(sauvee["ile"]["bassin"]["stock"]) == 2, "le stock du bassin est sauvegardé")
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_continuer))
	ile = jeu.get_node("Ile")
	_verifier(_jeu.atelier.est_relie("ilot_est") and ile.ilot_relie() and ile.bassin().get_parent() == ile.get_node("Sources"),
		"Continuer : l'îlot est toujours relié, le bassin est là")
	_verifier(ile.bassin().stock == 2, "Continuer : stock du bassin retrouvé", "stock %d" % ile.bassin().stock)
	_verifier(jeu.donnees_partie()["ilots"] == sauvee["ilots"] and jeu.donnees_partie()["ile"]["bassin"]["stock"] == 2,
		"aller-retour complet : îlots et bassin identiques")
	await _fermer_jeu(jeu)

	# Nouvelle partie : l'îlot redevient isolé.
	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_nouvelle))
	await _cliquer(_centre(jeu._titre.bouton_remplacer))
	ile = jeu.get_node("Ile")
	_verifier(not ile.ilot_relie() and ile.bassin().get_parent() == null and (Sauvegarde.lire()["partie"]["ilots"] as Array).is_empty(),
		"Nouvelle partie : l'îlot n'est plus relié")
	await _fermer_jeu(jeu)

	# Sauvegarde sans le bassin (format de la PR précédente) : îlot relié, bassin au stock de départ.
	Sauvegarde.ecrire({"inventaire": {}, "ameliorations": {}, "ilots": ["ilot_est"], "ile": {}})
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	ile = jeu.get_node("Ile")
	_verifier(ile.ilot_relie() and ile.bassin().stock == 1, "sauvegarde sans état du bassin : stock de départ (1)")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


# --- Machines (palier 1) -------------------------------------------------------------------

func _ingredients_moulin(inventaire: Inventaire) -> void:
	inventaire.ajouter("fil_nuage", 2)
	inventaire.ajouter("cristal_lagon", 3)
	inventaire.ajouter("cristal_solaire", 2)


func _ingredients_filet(inventaire: Inventaire) -> void:
	inventaire.ajouter("fil_nuage", 3)
	inventaire.ajouter("cristal_lagon", 2)


func _test_machines_logique() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	_verifier(atelier.machines_disponibles() == ["moulin", "filet"], "palier 1 : moulin à vent et filet à nuages")
	_verifier(atelier.emplacements_libres() == ["ile_ouest", "ile_centre"],
		"au départ : les 2 emplacements de l'île ; ceux des îlots attendent qu'ils soient reliés",
		str(atelier.emplacements_libres()))
	_verifier(atelier.construire_machine("moulin") == "" and atelier.machines.is_empty(), "moulin refusé sans ingrédients")
	_ingredients_moulin(inventaire)
	_verifier(atelier.construire_machine("moulin", "ile_centre") == "ile_centre" and inventaire.total() == 0,
		"moulin : 2 fils de nuage, 3 cristaux de lagon, 2 cristaux solaires ; posé sur l'emplacement choisi")
	_ingredients_moulin(inventaire)
	_verifier(atelier.construire_machine("moulin", "ile_centre") == "ile_ouest" and atelier.nombre_machines("moulin") == 2,
		"emplacement déjà pris : deuxième moulin sur le premier emplacement libre")
	_ingredients_filet(inventaire)
	_verifier(not atelier.peut_construire_machine("filet") and atelier.construire_machine("filet") == "",
		"plus d'emplacement libre : construction refusée, ingrédients gardés")
	_verifier(inventaire.quantite("fil_nuage") == 3, "ingrédients non dépensés")
	atelier.ilots_relies.append("ilot_est")
	_verifier(atelier.construire_machine("filet") == "ilot_est" and inventaire.total() == 0,
		"îlot relié : son emplacement reçoit le filet (3 fils de nuage, 2 cristaux de lagon)")
	atelier.ilots_relies.clear()
	atelier.charger_machines({"ile_ouest": "filet", "ilot_est": "moulin", "nulle_part": "moulin", "ile_centre": "fusee"})
	_verifier(atelier.machines == {"ile_ouest": "filet"},
		"machines lues d'une sauvegarde : machine ou emplacement inconnu, îlot non relié ignorés", str(atelier.machines))


func _test_machines_ile() -> void:
	var son := _son()
	son.vider_historique()
	var ile := await _ouvrir_ile()
	var atelier: Node = ile.get_node("Atelier")
	var lieu := "ile_centre"
	var centre: Vector2 = ile.centre_emplacement(lieu)
	_souris(centre)
	await _images(2)
	var aide: String = ile._texte_aide()
	_verifier(aide.contains("Emplacement libre"), "survol d'un emplacement libre : l'aide le dit", aide)
	await _cliquer(centre)
	_verifier(atelier.est_ouvert() and atelier.onglet == "machines" and atelier.emplacement_cible == lieu,
		"clic sur l'emplacement : l'atelier s'ouvre sur l'onglet Machines, pour cet emplacement")
	_verifier(atelier._bouton.disabled and atelier._effet.text.contains("île, centre"),
		"sans ingrédients : Construire inactif ; l'emplacement visé est indiqué", atelier._effet.text)
	_ingredients_moulin(_jeu.inventaire)
	atelier.rafraichir()
	await _images(3)
	await _cliquer(atelier._bouton.get_global_rect().get_center())
	var moulin: SourceRessource = ile.machine(lieu)
	var annonce: String = ile.get_node("HUD").texte_annonce()
	_verifier(moulin != null and moulin.position == centre and moulin.forme == SourceRessource.Forme.MOULIN
		and annonce.contains("Moulin à vent") and son.a_joue("construction"),
		"Construire : le moulin apparaît sur l'emplacement cliqué, annonce et son", annonce)
	_verifier(not _jeu.atelier.emplacement_libre(lieu) and atelier._libelle("moulin").contains("×1"),
		"l'emplacement est pris ; l'atelier compte les moulins construits")
	atelier.fermer()
	await _images(2)

	_verifier(moulin.stock == 0, "un moulin neuf est vide")
	ile.rattraper(10.0)
	var apres_10 := moulin.stock
	ile.rattraper(10000.0)
	_verifier(apres_10 == 1 and moulin.stock == 8, "moulin : 1 vent toutes les 10 s, réserve de 8", "%d puis %d" % [apres_10, moulin.stock])
	# Deux mouvements : le premier, juste après le clic dans l'atelier refermé, n'arrive pas à l'île.
	_souris(moulin.position)
	await _images(2)
	_souris(moulin.position + Vector2(2, 0))
	await _images(2)
	aide = ile._texte_aide()
	_verifier(aide.contains("Moulin à vent") and aide.contains("(8)"), "survol du moulin : nom et réserve", aide)
	var vent_avant: int = _jeu.inventaire.quantite("vent")
	await _cliquer(moulin.position)
	_verifier(_jeu.inventaire.quantite("vent") == vent_avant + 8 and moulin.stock == 0 and son.a_joue("machine"),
		"un clic sur le moulin : toute la réserve (8 vents) passe dans l'inventaire, avec son")

	_ingredients_filet(_jeu.inventaire)
	atelier.ouvrir()
	atelier.choisir_onglet("machines")
	atelier.selectionner("filet")
	_verifier(atelier.fabriquer_selection() and atelier.dernier_emplacement == "ile_ouest",
		"atelier ouvert par la cabane : le filet va sur le premier emplacement libre")
	atelier.fermer()
	await _images(2)
	var filet: SourceRessource = ile.machine("ile_ouest")
	ile.rattraper(6.0)
	var apres_6 := filet.stock
	ile.rattraper(10000.0)
	_verifier(filet != null and filet.forme == SourceRessource.Forme.FILET and apres_6 == 1 and filet.stock == 10,
		"filet : 1 ouate toutes les 6 s, réserve de 10", "%d puis %d" % [apres_6, filet.stock])
	await _cliquer(filet.position)
	_verifier(_jeu.inventaire.quantite("nuage") == 10 and filet.stock == 0, "un clic sur le filet : 10 ouates")
	_verifier(_jeu.atelier.emplacements_libres().is_empty() and ile._emplacement_sous_souris() == "",
		"plus d'emplacement libre sur l'île tant que l'îlot n'est pas relié")
	await _fermer_ile(ile)


## Machines : sauvegarde, production pendant la plongée et jeu fermé (dans la limite de la réserve).
func _test_machines_sauvegarde() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	_ingredients_moulin(_jeu.inventaire)
	var atelier: Node = ile.get_node("Atelier")
	atelier.ouvrir_machines("ile_ouest")
	atelier.fabriquer_selection()
	atelier.fermer()
	await _images(2)
	var sauvee: Dictionary = Sauvegarde.lire()["partie"]
	_verifier(sauvee["machines"] == {"ile_ouest": "moulin"}, "construction d'une machine : sauvegardée tout de suite",
		str(sauvee["machines"]))
	ile.machine("ile_ouest").stock = 3
	var partie: Dictionary = jeu.donnees_partie()
	_verifier(int(partie["ile"]["machines"]["ile_ouest"]["stock"]) == 3, "la réserve de la machine est sauvegardée")
	# Partie enregistrée il y a 40 s : le moulin a produit 4 vents de plus, jeu fermé.
	Sauvegarde.ecrire(partie, Time.get_unix_time_from_system() - 40.0)
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_continuer))
	ile = jeu.get_node("Ile")
	var moulin: SourceRessource = ile.machine("ile_ouest")
	_verifier(moulin != null and moulin.stock == 7, "Continuer : moulin retrouvé, 3 + 4 vents produits jeu fermé",
		"stock %d" % (moulin.stock if moulin else -1))
	jeu.sauvegarder()
	Sauvegarde.ecrire(jeu.donnees_partie(), Time.get_unix_time_from_system() - 100000.0)
	await _fermer_jeu(jeu)
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	_verifier(jeu.get_node("Ile").machine("ile_ouest").stock == 8, "jeu fermé longtemps : la réserve s'arrête à 8")
	await _fermer_jeu(jeu)

	# Pendant une plongée : l'île rattrape le temps passé sous l'eau, machines comprises.
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	ile = jeu.get_node("Ile")
	moulin = ile.machine("ile_ouest")
	moulin.stock = 0
	ile.arriver(25.0, {}, {}, false)
	_verifier(moulin.stock == 2, "retour de plongée (25 s) : le moulin a produit 2 vents", "stock %d" % moulin.stock)
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_nouvelle))
	await _cliquer(_centre(jeu._titre.bouton_remplacer))
	ile = jeu.get_node("Ile")
	_verifier(ile.machine("ile_ouest") == null and (Sauvegarde.lire()["partie"]["machines"] as Dictionary).is_empty(),
		"Nouvelle partie : plus de machine")
	await _fermer_jeu(jeu)

	Sauvegarde.ecrire({"inventaire": {}, "ameliorations": {}, "ilots": [], "ile": {}})
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	_verifier(_jeu.atelier.machines.is_empty() and jeu.donnees_partie()["machines"] == {},
		"sauvegarde d'avant les machines : aucune machine, rien de cassé")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


# --- Palier 2 --------------------------------------------------------------------------------

## Compare des recettes en nombres entiers (le JSON donne des nombres décimaux).
func _meme_recette(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for id: String in b:
		if int(a.get(id, -1)) != int(b[id]):
			return false
	return true


func _ingredients(inventaire: Inventaire, ingredients: Dictionary) -> void:
	for id: String in ingredients:
		inventaire.ajouter(id, int(ingredients[id]))


func _test_palier2_logique() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	_verifier(atelier.palier == 1 and not atelier.decouvrir(["cristal_lagon", "vent"]), "palier 1 au départ")
	_ingredients(inventaire, atelier.machine("foreuse")["ingredients"])
	_verifier(not atelier.peut_construire_machine("foreuse"), "palier 1 : la foreuse n'est pas encore proposée")
	_verifier(atelier.decouvrir(["corail"]) and atelier.palier == 2
		and atelier.machines_disponibles() == ["moulin", "filet", "foreuse"],
		"premier corail rapporté : palier 2, foreuse solaire proposée (l'entrepôt attend le palier 3)")
	_verifier(atelier.construire_machine("foreuse", "ile_ouest") == "filon_1" and inventaire.total() == 0,
		"foreuse : 1 lentille, 4 coraux, 4 cristaux solaires ; toujours posée sur un filon (le premier libre)")
	_verifier(atelier.emplacements_libres() == ["ile_ouest", "ile_centre"] and atelier.emplacements_libres("foreuse") == ["filon_2", "filon_3"],
		"un filon n'est pas un emplacement au sol, et inversement")
	for i in 2:
		_ingredients(inventaire, atelier.machine("foreuse")["ingredients"])
		atelier.construire_machine("foreuse")
	_ingredients(inventaire, atelier.machine("foreuse")["ingredients"])
	_verifier(atelier.nombre_machines("foreuse") == 3 and not atelier.peut_construire_machine("foreuse"),
		"3 filons, 3 foreuses au plus")
	inventaire = Inventaire.new()
	atelier = Atelier.new(inventaire)
	atelier.palier = 2
	_ingredients(inventaire, atelier.machine("entrepot")["ingredients"])
	_verifier(not atelier.peut_construire_machine("entrepot"), "palier 2 : pas encore d'entrepôt")
	atelier.palier = 3
	_verifier(atelier.construire_machine("entrepot") != "" and inventaire.plafond == 199 and inventaire.ajouter("vent", 150) == 150,
		"entrepôt (palier 3) : 5 coraux, 4 fils de nuage, 4 cristaux de lagon ; l'inventaire garde jusqu'à 199")
	atelier.palier = 2
	_ingredients(inventaire, {"corail": 4, "fil_nuage": 4})
	_verifier(atelier.construire("pont") and atelier.est_relie("ilot_nord")
		and atelier.emplacements_libres().has("nord_ouest") and atelier.emplacements_libres().has("nord_est"),
		"pont suspendu : 4 coraux, 4 fils de nuage ; deux emplacements sur l'îlot du nord")

	_verifier(not atelier.peut_ameliorer_machine("moulin", "vitesse"), "amélioration impossible sans moulin construit")
	_ingredients(inventaire, atelier.machine("moulin")["ingredients"])
	atelier.construire_machine("moulin")
	_ingredients(inventaire, atelier.prochaine_amelioration_machine("moulin", "vitesse"))
	_ingredients(inventaire, atelier.prochaine_amelioration_machine("moulin", "capacite"))
	_verifier(atelier.ameliorer_machine("moulin", "vitesse") and is_equal_approx(atelier.recharge_machine("moulin"), 10.0 / 1.5),
		"moulin, vitesse niveau 1 : 1 vent toutes les 6,7 s au lieu de 10 s")
	_verifier(atelier.ameliorer_machine("moulin", "capacite") and atelier.plafond_machine("moulin") == 16,
		"moulin, réserve niveau 1 : 16 au lieu de 8")
	_verifier(_meme_recette(atelier.prochaine_amelioration_machine("moulin", "vitesse"), {"verre_lagon": 2})
		and not atelier.ameliorer_machine("moulin", "vitesse"), "niveau 2 : se paie en matériaux raffinés (2 verres de lagon)")
	_verifier(atelier.genres_amelioration("entrepot") == ["capacite"], "l'entrepôt ne s'améliore qu'en capacité")
	atelier.charger_niveaux_machines({"moulin": {"vitesse": 9, "inconnu": 1}, "fusee": {"vitesse": 1}, "filet": "x"})
	_verifier(atelier.niveaux_machines == {"moulin": {"vitesse": 2}}, "améliorations lues : bornées, inconnues ignorées",
		str(atelier.niveaux_machines))

	inventaire = Inventaire.new()
	atelier = Atelier.new(inventaire)
	_verifier(atelier.places_sac() == 8, "sac de départ : 8 places")
	_ingredients(inventaire, {"corail": 4, "poche_air": 2})
	_verifier(atelier.ameliorer("sac") and atelier.places_sac() == 12 and inventaire.total() == 0,
		"sac de plongée : 4 coraux, 2 poches d'air ; 12 places")
	atelier.niveaux["lanterne"] = 1
	atelier.charger_palier(null)
	_verifier(atelier.palier == 2, "sauvegarde sans palier : déduit de la lanterne déjà installée")


func _test_palier2_ile() -> void:
	var son := _son()
	son.vider_historique()
	var ile := await _ouvrir_ile()
	var atelier: Node = ile.get_node("Atelier")
	_jeu.atelier.palier = 2
	# Foreuse sur le premier filon, depuis l'atelier.
	_ingredients(_jeu.inventaire, _jeu.atelier.machine("foreuse")["ingredients"])
	atelier.ouvrir()
	atelier.choisir_onglet("machines")
	atelier.selectionner("foreuse")
	_verifier(atelier._effet.text.contains("filon de gauche"), "atelier : la foreuse ira sur le filon de gauche", atelier._effet.text)
	_verifier(atelier.fabriquer_selection(), "Construire : foreuse solaire")
	atelier.fermer()
	await _images(2)
	var foreuse: SourceRessource = ile.machine("filon_1")
	var filon: SourceRessource = ile._filons[0]
	_verifier(foreuse != null and foreuse.forme == SourceRessource.Forme.FOREUSE and filon.get_parent() == null
		and absf(foreuse.position.x - filon.position.x) < 0.5,
		"la foreuse prend la place du filon, qui ne se récolte plus à la main")
	ile.rattraper(15.0)
	var apres_15 := foreuse.stock
	ile.rattraper(10000.0)
	_verifier(apres_15 == 1 and foreuse.stock == 6, "foreuse : 1 cristal solaire toutes les 15 s, réserve de 6",
		"%d puis %d" % [apres_15, foreuse.stock])
	var solaire: int = _jeu.inventaire.quantite("cristal_solaire")
	await _cliquer(foreuse.position)
	_verifier(_jeu.inventaire.quantite("cristal_solaire") == solaire + 6 and son.a_joue("foreuse"),
		"un clic sur la foreuse : 6 cristaux solaires, avec son")

	# Îlot du nord : survol, construction du pont, emplacements, entrepôt.
	_souris(ile.centre_ilot("ilot_nord"))
	await _images(2)
	var aide: String = ile._texte_aide()
	_verifier(aide.contains("pont suspendu"), "survol de l'îlot du nord : l'aide parle du pont suspendu", aide)
	await _cliquer(ile.centre_ilot("ilot_nord"))
	_verifier(atelier.est_ouvert() and atelier.onglet == "construction" and atelier.selection == "pont",
		"clic sur l'îlot du nord : atelier, onglet Construction, pont suspendu choisi")
	_ingredients(_jeu.inventaire, {"corail": 4, "fil_nuage": 4})
	atelier.fabriquer_selection()
	atelier.fermer()
	await _images(2)
	var annonce: String = ile.get_node("HUD").texte_annonce()
	_verifier(ile.ilot_relie("ilot_nord") and annonce.contains("nord"), "pont construit : l'îlot du nord est relié", annonce)
	_jeu.atelier.palier = 3   # l'entrepôt arrive au palier 3
	_ingredients(_jeu.inventaire, _jeu.atelier.machine("entrepot")["ingredients"])
	await _cliquer(ile.centre_emplacement("nord_est"))
	_verifier(atelier.est_ouvert() and atelier.emplacement_cible == "nord_est", "clic sur un emplacement de l'îlot du nord")
	atelier.selectionner("entrepot")
	atelier.fabriquer_selection()
	atelier.fermer()
	await _images(2)
	var entrepot: SourceRessource = ile.machine("nord_est")
	_verifier(entrepot != null and entrepot.forme == SourceRessource.Forme.ENTREPOT and _jeu.inventaire.plafond == 199,
		"entrepôt (palier 3) sur l'îlot du nord : inventaire jusqu'à 199")
	_souris(entrepot.position)
	await _images(2)
	_souris(entrepot.position + Vector2(1, 0))
	await _images(2)
	aide = ile._texte_aide()
	_verifier(aide.contains("199"), "survol de l'entrepôt : son effet", aide)

	# Amélioration du moulin par les boutons de l'atelier.
	_ingredients(_jeu.inventaire, _jeu.atelier.machine("moulin")["ingredients"])
	_jeu.atelier.construire_machine("moulin", "ile_ouest")
	ile.actualiser_machines()
	_ingredients(_jeu.inventaire, _jeu.atelier.prochaine_amelioration_machine("moulin", "vitesse"))
	atelier.ouvrir()
	atelier.choisir_onglet("machines")
	atelier.selectionner("moulin")
	_verifier(atelier._modes.visible and not atelier._titre.visible, "palier 2 : boutons Construire, Vitesse, Réserve")
	atelier.choisir_mode("vitesse")
	_verifier(atelier._bouton.text == "Améliorer" and not atelier._bouton.disabled and atelier._effet.text.contains("6,7"),
		"mode Vitesse : effet et bouton Améliorer", atelier._effet.text)
	atelier._bouton.pressed.emit()
	atelier.fermer()
	await _images(2)
	_verifier(is_equal_approx(ile.machine("ile_ouest").recharge_s, 10.0 / 1.5) and son.a_joue("installation"),
		"Améliorer : le moulin produit plus vite, son d'installation")

	# Annonce du palier au retour d'une plongée (après celle du butin).
	_jeu.atelier.palier = 1
	ile.arriver(0.0, {"corail": 2}, {}, false)
	await _images(2)
	var butin: String = ile.get_node("HUD").texte_annonce()
	await _secondes(4.2)
	var palier: String = ile.get_node("HUD").texte_annonce()
	_verifier(butin.contains("Butin") and palier.contains("Palier 2") and palier.contains("foreuse"),
		"premier corail rapporté : annonce du butin, puis du palier 2", "%s / %s" % [butin, palier])
	await _fermer_ile(ile)


func _test_palier2_sauvegarde() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	var atelier: Atelier = _jeu.atelier
	atelier.palier = 3   # entrepôt compris
	_ingredients(_jeu.inventaire, atelier.machine("foreuse")["ingredients"])
	atelier.construire_machine("foreuse", "filon_2")
	_ingredients(_jeu.inventaire, {"corail": 4, "fil_nuage": 4})
	atelier.construire("pont")
	_ingredients(_jeu.inventaire, atelier.machine("entrepot")["ingredients"])
	atelier.construire_machine("entrepot", "nord_ouest")
	_ingredients(_jeu.inventaire, atelier.prochaine_amelioration_machine("foreuse", "capacite"))
	atelier.ameliorer_machine("foreuse", "capacite")
	_jeu.inventaire.ajouter("vent", 150)
	ile.actualiser_ilot()
	ile.actualiser_machines()
	ile.machine("filon_2").stock = 9
	jeu.sauvegarder()
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	ile = jeu.get_node("Ile")
	var foreuse: SourceRessource = ile.machine("filon_2")
	_verifier(_jeu.atelier.palier == 3 and foreuse != null and foreuse.plafond == 12 and foreuse.stock == 9
		and ile._filons[1].get_parent() == null,
		"Continuer : palier 3, foreuse sur le filon du milieu, réserve améliorée (12) et son stock")
	_verifier(_jeu.atelier.est_relie("ilot_nord") and ile.machine("nord_ouest") != null
		and _jeu.inventaire.plafond == 199 and _jeu.inventaire.quantite("vent") == 150,
		"Continuer : îlot du nord, entrepôt, 150 vents gardés")
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_nouvelle))
	await _cliquer(_centre(jeu._titre.bouton_remplacer))
	ile = jeu.get_node("Ile")
	_verifier(_jeu.atelier.palier == 1 and ile._filons[1].get_parent() != null and _jeu.inventaire.plafond == 99
		and not ile.ilot_relie("ilot_nord"), "Nouvelle partie : palier 1, filons libres, inventaire à 99, îlot du nord isolé")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


func _test_sac_12() -> void:
	await _demarrer()
	_jeu.atelier.niveaux["sac"] = 1
	_plongee.appliquer_ameliorations()
	_plongee._rafraichir_sac()
	var texte: String = _plongee.get_node("HUD")._sac.text
	_verifier(_plongee._sac.capacite == 12 and texte.contains("/12"), "sac de plongée installé : 12 places en plongée", texte)
	await _terminer()
	_jeu.atelier.niveaux["sac"] = 0


# --- Trouvailles et carnet ------------------------------------------------------------------------

func _test_carnet_logique() -> void:
	var carnet := Carnet.new()
	var total := 0
	var noms := {}
	var descriptions_ok := true
	var motifs_ok := true
	for page: Dictionary in carnet.pages():
		total += carnet.cases(str(page["id"])).size()
	for zone: String in Carnet.PAGES_TROUVAILLES:
		for id: String in carnet.cases(zone):
			var donnees := carnet.trouvaille(id)
			noms[str(donnees["nom"])] = true
			descriptions_ok = descriptions_ok and str(donnees["description"]).length() >= 40
			motifs_ok = motifs_ok and ArtTrouvailles.MOTIFS.has(id)
	_verifier(carnet.pages().size() == 4 and carnet.cases("lagon").size() == 6 and carnet.cases("coraux").size() == 6
		and carnet.cases("faille").size() == 6 and carnet.cases("machines").size() == 6 and total == 24,
		"carnet : 6 perles, 6 fossiles, 6 reliques et 6 machines (24 cases)")
	_verifier(noms.size() == 18 and descriptions_ok and motifs_ok,
		"18 trouvailles : chacune son nom, sa description (une histoire) et son pixel art")
	_verifier(not carnet.trouver("inconnue") and carnet.trouver("perle_lune") and not carnet.trouver("perle_lune")
		and carnet.pourcentage() == 4, "trouver : une seule fois ; 1/24 = 4 %")
	for id: String in carnet.cases("lagon"):
		carnet.trouver(id)
	_verifier(carnet.page_complete("lagon") and carnet.places_sac_bonus() == 1
		and carnet.facteur_minage("lagon") == 1.0 and carnet.restantes("lagon").is_empty(),
		"page des perles complète : une place de sac en plus")
	for id: String in carnet.cases("faille"):
		carnet.trouver(id)
	_verifier(is_equal_approx(carnet.facteur_oxygene("faille"), 0.8) and carnet.facteur_oxygene("lagon") == 1.0,
		"page des reliques complète : 20 % d'air en moins dans la Faille")
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	for id: String in carnet.cases("lagon"):
		atelier.carnet.trouver(id)
	_verifier(atelier.places_sac() == 9, "page des perles : sac de 9 places au lieu de 8", str(atelier.places_sac()))
	for id: String in atelier.liste_machines():
		atelier.carnet.voir_machine(id)
	_verifier(atelier.carnet.page_complete("machines") and is_equal_approx(atelier.recharge_machine("moulin"), 10.0 / 1.1),
		"page des machines complète : toutes les machines produisent 10 % plus vite")
	carnet.charger({"trouvailles": ["ammonite", "inconnue", "ammonite"], "machines": ["moulin", "fusee"]})
	_verifier(carnet.trouvees == ["ammonite"] and carnet.machines_vues == ["moulin"], "carnet lu : inconnus et doublons ignorés")


func _trouvailles_generees() -> Array[Gisement]:
	return _gisements().filter(func(g: Gisement) -> bool: return g.trouvaille != "")


func _test_trouvailles_plongee() -> void:
	await _demarrer()
	var zones: Array = Donnees.charger_json("res://data/zones.json")
	var une_par_zone := true
	var dans_le_bas := true
	var vues := 0
	for tirage in 30:
		_plongee._generer_gisements()
		await physics_frame
		var par_zone := {}
		for eclat in _trouvailles_generees():
			vues += 1
			par_zone[eclat.zone] = int(par_zone.get(eclat.zone, 0)) + 1
			for zone: Dictionary in zones:
				if str(zone["id"]) == eclat.zone:
					var milieu := (float(zone["debut_m"]) + float(zone["fin_m"])) / 2.0 * 10.0
					dans_le_bas = dans_le_bas and eclat.position.y >= milieu - 1.0 and eclat.position.y <= float(zone["fin_m"]) * 10.0
					dans_le_bas = dans_le_bas and _jeu.atelier.carnet.cases(eclat.zone).has(eclat.trouvaille)
		for zone: String in par_zone:
			une_par_zone = une_par_zone and int(par_zone[zone]) <= 1
	_verifier(une_par_zone and vues >= 45 and vues < 90, "au plus une trouvaille par zone et par plongée (environ 3 sur 4)",
		"%d sur 30 plongées" % vues)
	_verifier(dans_le_bas, "trouvailles dans la moitié basse de leur zone, parmi celles de la zone")

	# Ramassage, sac plein : la trouvaille ne prend pas de place et va droit au carnet.
	_jeu.atelier.niveaux["cable"] = 2
	_plongee.appliquer_ameliorations()
	while _trouvailles_generees().is_empty():
		_plongee._generer_gisements()
		await physics_frame
	var eclat: Gisement = _trouvailles_generees()[0]
	var id_eclat := eclat.trouvaille
	for i in _plongee._sac.capacite:
		_plongee._sac.ajouter("cristal_lagon")
	_plongee._rafraichir_sac()
	_bell.position = eclat.position + Vector2(0.0, -10.0)
	_bell.velocity = Vector2.ZERO
	await _images(2)
	var message: String = _plongee._message_bas(true)
	_son().vider_historique()
	Input.action_press("interact")
	await _secondes(2.3)
	Input.action_release("interact")
	var annonce: String = _plongee.get_node("HUD")._annonce.text
	_verifier(_jeu.atelier.carnet.a_trouve(id_eclat) and _plongee.trouvailles_plongee == [id_eclat]
		and _plongee._sac.nombre() == _plongee._sac.capacite and _son().a_joue("trouvaille"),
		"sac plein : la trouvaille se ramasse quand même (2 s), va au carnet, avec son")
	_verifier(message.contains("trouvaille") and annonce.contains("Trouvaille"), "message et annonce de la trouvaille", annonce)

	# Dernière perle : page complète, plus de perle dans le Lagon, minage plus rapide.
	var carnet: Carnet = _jeu.atelier.carnet
	for id: String in carnet.cases("lagon").slice(0, 5):
		carnet.trouver(id)
	var derniere: String = carnet.restantes("lagon")[0] if not carnet.restantes("lagon").is_empty() else ""
	if derniere != "":
		_plongee._ramasser_trouvaille(derniere)
	annonce = _plongee.get_node("HUD")._annonce.text
	_verifier(carnet.page_complete("lagon") and annonce.contains("Page complète"), "dernière perle : page complète annoncée", annonce)
	var perle := false
	for tirage in 10:
		_plongee._generer_gisements()
		await physics_frame
		for gisement in _gisements():
			perle = perle or gisement.zone == "lagon"
	_verifier(_plongee._sac.capacite == _jeu.atelier.places_sac() and _jeu.atelier.places_sac() == 9 and not perle,
		"page des perles complète : plus de perle à trouver, une place de sac en plus tout de suite",
		"sac %d" % _plongee._sac.capacite)
	_jeu.atelier.niveaux["cable"] = 0
	await _terminer()


func _test_carnet_panneau() -> void:
	var ile := await _ouvrir_ile()
	var carnet: Carnet = _jeu.atelier.carnet
	var panneau: Node = ile.get_node("Carnet")
	_touche(KEY_K)
	await _images(2)
	_verifier(panneau.est_ouvert() and ile.panneau_ouvert() and panneau._titre.text == "Carnet : 0 %",
		"K ouvre le carnet (0 %)")
	_verifier(panneau._nom.text == "Pas encore trouvée" and panneau._bonus.text.contains("0/6"),
		"case vide : silhouette, « Pas encore trouvée », page 0/6 et son bonus", panneau._bonus.text)
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(not panneau.est_ouvert(), "Échap ferme le carnet")
	carnet.trouver("ammonite")
	await _cliquer(_centre(ile.get_node("HUD").bouton_carnet))
	await _cliquer(_centre(panneau._onglets["coraux"]))
	panneau.selectionner("ammonite")
	_verifier(panneau.est_ouvert() and panneau._nom.text == "Ammonite spiralée" and panneau._description.text.contains("spirale")
		and panneau._titre.text == "Carnet : 4 %", "bouton Carnet, page des fossiles : l'ammonite, son nom et son histoire")
	# La fiche suit toujours la case choisie, sur chaque page (clic sur la case, comme un joueur).
	for id: String in carnet.cases("faille") + carnet.cases("lagon"):
		carnet.trouver(id)
	var fiches_ok := true
	for zone: String in ["faille", "lagon"]:
		await _cliquer(_centre(panneau._onglets[zone]))
		for case in panneau._grille.get_children():
			await _cliquer(_centre(case))
			fiches_ok = fiches_ok and panneau.selection == case.get_meta("id") \
				and panneau._nom.text == str(carnet.trouvaille(case.get_meta("id"))["nom"])
	_verifier(fiches_ok, "carnet : chaque case cliquée affiche sa propre fiche (reliques, perles)")
	await _cliquer(_centre(panneau._onglets["machines"]))
	_verifier(panneau.page == "machines" and panneau._grille.get_child_count() == 6, "page des machines : 6 cases")
	panneau.fermer()
	await _fermer_ile(ile)


func _test_carnet_sauvegarde() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	_jeu.atelier.carnet.trouver("cle_braise")
	_jeu.atelier.carnet.trouver("perle_noire")
	_ingredients(_jeu.inventaire, _jeu.atelier.machine("moulin")["ingredients"])
	_jeu.atelier.construire_machine("moulin")
	jeu.sauvegarder()
	await _fermer_jeu(jeu)
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	_verifier(_jeu.atelier.carnet.trouvees == ["cle_braise", "perle_noire"] and _jeu.atelier.carnet.machines_vues == ["moulin"],
		"Continuer : le carnet est retrouvé (2 trouvailles, le moulin)")
	await _fermer_jeu(jeu)
	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_nouvelle))
	await _cliquer(_centre(jeu._titre.bouton_remplacer))
	_verifier(_jeu.atelier.carnet.trouvees.is_empty(), "Nouvelle partie : carnet vide")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


# --- Nuages devant les éléments de l'île --------------------------------------------------------

func _test_nuages_devant() -> void:
	var ile := await _ouvrir_ile()
	var atelier: Node = ile.get_node("Atelier")
	var nuage := _nuage_degage(ile)
	var prises := nuage.stock
	var demandes := [0]
	ile.plongee_demandee.connect(func() -> void: demandes[0] += 1)

	nuage.position = ile.centre_emplacement("ile_centre")
	await _cliquer(nuage.position)
	_verifier(atelier.est_ouvert() and atelier.emplacement_cible == "ile_centre" and nuage.stock == prises,
		"nuage devant un emplacement libre : le clic ouvre l'atelier pour l'emplacement, le nuage reste")
	atelier.fermer()

	_ingredients(_jeu.inventaire, _jeu.atelier.machine("moulin")["ingredients"])
	_jeu.atelier.construire_machine("moulin", "ile_ouest")
	ile.actualiser_machines()
	var moulin: SourceRessource = ile.machine("ile_ouest")
	moulin.stock = 5
	nuage.position = moulin.position
	await _cliquer(moulin.position + Vector2(1, 0))
	_verifier(moulin.stock == 0 and _jeu.inventaire.quantite("vent") == 5 and nuage.stock == prises,
		"nuage devant une machine : le clic vide la machine, pas le nuage")

	nuage.position = _ile_script.POSITION_CLOCHE
	await _cliquer(_ile_script.POSITION_CLOCHE)
	_verifier(demandes[0] == 1 and nuage.stock == prises, "nuage devant la cloche : le clic lance la plongée")

	nuage.position = _ile_script.POSITION_CABANE
	await _cliquer(_ile_script.POSITION_CABANE)
	_verifier(atelier.est_ouvert() and nuage.stock == prises, "nuage devant la cabane : le clic ouvre l'atelier")
	atelier.fermer()

	nuage.position = ile.centre_ilot("ilot_nord")
	await _cliquer(ile.centre_ilot("ilot_nord"))
	_verifier(atelier.est_ouvert() and atelier.selection == "pont" and nuage.stock == prises,
		"nuage devant un îlot isolé : le clic ouvre la construction du pont")
	atelier.fermer()

	nuage.position = Vector2(400.0, 70.0)
	await _cliquer(nuage.position)
	_verifier(nuage.stock == prises - 1, "nuage seul sous la souris : il se récolte")
	await _fermer_ile(ile)


# --- Palier 3 --------------------------------------------------------------------------------

func _test_palier3_logique() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	atelier.palier = 2
	_verifier(atelier.decouvrir(["pierre_braise"]) and atelier.palier == 3
		and atelier.machines_disponibles().has("fourneau") and atelier.machines_disponibles().has("sonde"),
		"première pierre de braise : palier 3, fourneau et sonde proposés")
	_ingredients(inventaire, atelier.machine("fourneau")["ingredients"])
	var lieu := atelier.construire_machine("fourneau")
	_verifier(lieu == "ile_ouest" and inventaire.total() == 0 and atelier.recette_fourneau(lieu) == "",
		"fourneau : 3 pierres de braise, 3 coraux, 6 cristaux solaires ; à l'arrêt au départ")
	var tous_au_vent := true
	for raffine: String in atelier.raffines():
		tous_au_vent = tous_au_vent and atelier.recette_raffine(raffine).has("vent")
	_verifier(atelier.raffines() == ["verre_lagon", "nacre", "lingot_solaire"] and tous_au_vent,
		"3 raffinés (verre de lagon, nacre, lingot solaire), tous attisés au vent")
	_verifier(_meme_recette(atelier.recette_raffine("nacre"), {"corail": 1, "nuage": 8, "vent": 2})
		and _meme_recette(atelier.recette_raffine("lingot_solaire"), {"cristal_solaire": 5, "vent": 5})
		and _meme_recette(atelier.recette_raffine("verre_lagon"), {"cristal_lagon": 2, "vent": 6}),
		"recettes : ouates (filet), cristaux solaires (foreuse) et vent (moulin) en quantité")
	_verifier(not atelier.choisir_recette_fourneau(lieu, "or_massif") and not atelier.choisir_recette_fourneau("ile_centre", "nacre")
		and atelier.choisir_recette_fourneau(lieu, "lingot_solaire"), "recette du fourneau : raffiné et fourneau connus seulement")
	_verifier(not atelier.consommer_fourneau("lingot_solaire"), "fourneau sans ingrédients : il attend")
	_ingredients(inventaire, {"cristal_solaire": 5, "vent": 5})
	_verifier(atelier.consommer_fourneau("lingot_solaire") and inventaire.total() == 0
		and atelier.consomme_fourneau == {"cristal_solaire": 5, "vent": 5}, "un cycle prend ses ingrédients dans l'inventaire et les compte")
	atelier.charger_fourneaux({lieu: "nacre", "ile_centre": "nacre"})
	_verifier(atelier.recettes_fourneau == {lieu: "nacre"}, "recettes lues d'une sauvegarde : fourneaux connus seulement")

	# Arche de braise : 100 vents, plus que les 99 que garde l'inventaire sans entrepôt.
	_ingredients(inventaire, {"pierre_braise": 3, "lingot_solaire": 4, "vent": 150})
	_verifier(inventaire.quantite("vent") == 99 and not atelier.peut_construire("arche"),
		"arche de braise : 100 vents, impossible sans entrepôt (l'inventaire s'arrête à 99)")
	_ingredients(inventaire, atelier.machine("entrepot")["ingredients"])
	atelier.construire_machine("entrepot")
	inventaire.ajouter("vent", 10)
	_verifier(atelier.construire("arche") and atelier.est_relie("ilot_couchant") and atelier.emplacements_libres().has("couchant_ouest"),
		"avec un entrepôt : l'arche relie l'îlot du couchant (deux emplacements)")
	_ingredients(inventaire, {"lingot_solaire": 3, "verre_lagon": 3})
	_verifier(atelier.ameliorer_machine("entrepot", "capacite") and inventaire.plafond == 499,
		"entrepôt amélioré (3 lingots, 3 verres) : 499 de chaque ressource")

	_ingredients(inventaire, atelier.machine("moulin")["ingredients"])
	atelier.construire_machine("moulin")
	for niveau in 2:
		_ingredients(inventaire, atelier.prochaine_amelioration_machine("moulin", "vitesse"))
		_ingredients(inventaire, atelier.prochaine_amelioration_machine("moulin", "capacite"))
		atelier.ameliorer_machine("moulin", "vitesse")
		atelier.ameliorer_machine("moulin", "capacite")
	_verifier(is_equal_approx(atelier.recharge_machine("moulin"), 5.0) and atelier.plafond_machine("moulin") == 24,
		"moulin au niveau 2 : 1 vent toutes les 5 s, réserve de 24")
	_ingredients(inventaire, atelier.machine("sonde")["ingredients"])
	_verifier(atelier.construire_machine("sonde") != "" and atelier.en_plongee("sonde"),
		"sonde : 2 pierres de braise, 2 poches d'air, 1 lentille ; produit en plongée")
	atelier.niveaux["sac"] = 1
	_ingredients(inventaire, {"nacre": 3, "verre_lagon": 3})
	_verifier(atelier.ameliorer("sac") and atelier.places_sac() == 16, "sac de plongée niveau 2 (3 nacres, 3 verres) : 16 places")
	_verifier(int(atelier.depenses.get("vent", 0)) >= 100, "dépenses de l'atelier comptées (vent de l'arche)")


func _test_palier3_ile() -> void:
	var son := _son()
	son.vider_historique()
	var ile := await _ouvrir_ile()
	var atelier: Node = ile.get_node("Atelier")
	var logique: Atelier = _jeu.atelier
	logique.palier = 3
	_ingredients(_jeu.inventaire, logique.machine("fourneau")["ingredients"])
	logique.construire_machine("fourneau", "ile_centre")
	ile.actualiser_machines()
	var fourneau: SourceRessource = ile.machine("ile_centre")
	_souris(fourneau.position)
	await _images(2)
	var aide: String = ile._texte_aide()
	_verifier(fourneau.forme == SourceRessource.Forme.FOURNEAU and aide.contains("à l'arrêt"), "fourneau neuf : à l'arrêt", aide)
	await _cliquer(fourneau.position)
	_verifier(atelier.est_ouvert() and atelier.onglet == "fourneau" and not atelier._ligne_onglets.visible
		and atelier._entete.text == "Fourneau", "clic sur le fourneau : son panneau (sans onglets)")
	atelier.selectionner("lingot_solaire")
	_verifier(atelier._bouton.text == "Choisir" and not atelier._bouton.disabled, "choisir le lingot solaire")
	atelier._bouton.pressed.emit()
	atelier.fermer()
	await _images(2)
	_verifier(logique.recette_fourneau("ile_centre") == "lingot_solaire" and fourneau.id_ressource == "lingot_solaire"
		and son.a_joue("fourneau"), "le fourneau fabrique des lingots en boucle, avec son")
	_jeu.inventaire.ajouter("cristal_solaire", 10)
	_jeu.inventaire.ajouter("vent", 10)
	ile.rattraper(40.0)
	_verifier(fourneau.stock == 2 and _jeu.inventaire.quantite("cristal_solaire") == 0 and _jeu.inventaire.quantite("vent") == 0,
		"40 s : 2 lingots, ingrédients pris dans l'inventaire", "stock %d" % fourneau.stock)
	ile.rattraper(200.0)
	_verifier(fourneau.stock == 2, "sans ingrédients, le fourneau attend")
	_jeu.inventaire.ajouter("cristal_solaire", 5)
	_jeu.inventaire.ajouter("vent", 5)
	ile.rattraper(0.1)
	_verifier(fourneau.stock == 3, "ingrédients revenus : le cycle prêt repart aussitôt")
	ile.rattraper(1000.0)
	_souris(fourneau.position + Vector2(1, 0))
	await _images(2)
	aide = ile._texte_aide()
	_verifier(aide.contains("récupérer 3"), "aide : réserve à récupérer", aide)
	await _cliquer(fourneau.position + Vector2(1, 0))
	_verifier(_jeu.inventaire.quantite("lingot_solaire") == 3 and fourneau.stock == 0 and atelier.est_ouvert(),
		"un clic : 3 lingots dans l'inventaire, et le panneau du fourneau s'ouvre")
	atelier.fermer()

	_ingredients(_jeu.inventaire, logique.machine("sonde")["ingredients"])
	logique.construire_machine("sonde", "ile_ouest")
	ile.actualiser_machines()
	var sonde: SourceRessource = ile.machine("ile_ouest")
	ile.rattraper(1000.0)
	var sur_ile := sonde.stock
	ile.arriver(36.0, {}, {}, false)
	_verifier(sur_ile == 0 and sonde.stock == 3, "sonde : rien sur l'île, 3 cristaux de lagon pour 36 s de plongée",
		"%d puis %d" % [sur_ile, sonde.stock])

	_souris(ile.centre_ilot("ilot_couchant"))
	await _images(2)
	aide = ile._texte_aide()
	await _cliquer(ile.centre_ilot("ilot_couchant"))
	_verifier(aide.contains("arche") and atelier.onglet == "construction" and atelier.selection == "arche"
		and atelier._effet.text.contains("entrepôt"),
		"îlot du couchant : l'aide et l'atelier (l'arche demande 100 vents : il faut un entrepôt)", atelier._effet.text)
	atelier.fermer()
	await _fermer_ile(ile)


func _test_palier3_sauvegarde() -> void:
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	var ile: Node = jeu.get_node("Ile")
	var logique: Atelier = _jeu.atelier
	logique.palier = 3
	_ingredients(_jeu.inventaire, logique.machine("fourneau")["ingredients"])
	logique.construire_machine("fourneau", "ile_ouest")
	logique.choisir_recette_fourneau("ile_ouest", "nacre")
	ile.actualiser_machines()
	_ingredients(_jeu.inventaire, {"corail": 2, "nuage": 16, "vent": 4})
	# Partie enregistrée il y a 70 s : de quoi faire 2 nacres (3 cycles possibles en temps).
	Sauvegarde.ecrire(jeu.donnees_partie(), Time.get_unix_time_from_system() - 70.0)
	await _fermer_jeu(jeu)
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	ile = jeu.get_node("Ile")
	var fourneau: SourceRessource = ile.machine("ile_ouest")
	_verifier(_jeu.atelier.recette_fourneau("ile_ouest") == "nacre" and fourneau.id_ressource == "nacre" and fourneau.stock == 2
		and _jeu.inventaire.quantite("nuage") == 0, "Continuer : le fourneau a fait 2 nacres jeu fermé, avec l'inventaire",
		"stock %d" % fourneau.stock)
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


# --- Marchand de vent -------------------------------------------------------------------------

## Ressources de l'abysse (minerais des zones) et tout ce qui en est fabriqué (composants, raffinés).
func _issus_de_l_abysse() -> Array:
	var atelier := Atelier.new(Inventaire.new())
	var issus: Array = []
	for zone: Dictionary in Donnees.charger_json("res://data/zones.json"):
		issus.append(str(zone["minerai"]))
	for id: String in atelier.composants():
		for ingredient: String in atelier.ingredients_composant(id):
			if issus.has(ingredient) and not issus.has(id):
				issus.append(id)
	for id: String in atelier.raffines():
		for ingredient: String in atelier.recette_raffine(id):
			if issus.has(ingredient) and not issus.has(id):
				issus.append(id)
	return issus


func _test_marchand_logique() -> void:
	var marchand := Marchand.new()
	_verifier(not marchand.est_present() and is_equal_approx(marchand.attente, 240.0) and is_equal_approx(marchand.duree(), 60.0),
		"marchand : premier passage après 4 min de jeu, il reste 60 s")
	var issus := _issus_de_l_abysse()
	var jamais_abysse := true
	var surplus_seulement := true
	var par_palier := {1: 0, 2: 0, 3: 0}
	var ouates := {1: false, 2: false, 3: false}
	for donnees: Dictionary in marchand.echanges():
		for id: String in donnees["recoit"]:
			jamais_abysse = jamais_abysse and not issus.has(id) and not marchand.interdits().has(id)
		for id: String in donnees["donne"]:
			surplus_seulement = surplus_seulement and (id == "nuage" or id == "vent")
		par_palier[int(donnees["palier"])] += 1
		ouates[int(donnees["palier"])] = ouates[int(donnees["palier"])] or donnees["donne"].has("nuage")
	_verifier(jamais_abysse and issus.has("lentille") and issus.has("nacre") and issus.has("verre_lagon"),
		"aucun échange ne donne un minerai de l'abysse ni ce qui en est fait (aucune plongée rendue inutile)", str(issus))
	_verifier(surplus_seulement, "il ne rachète que des surplus : ouates et vents")
	_verifier(par_palier[1] >= 4 and par_palier[2] >= 4 and par_palier[3] >= 4 and ouates[1] and ouates[2] and ouates[3],
		"au moins 4 échanges par palier (3 tirés à chaque passage), chacun avec des ouates", str(par_palier))

	_verifier(marchand.avancer(239.0, true, 1) == "" and not marchand.est_present()
		and marchand.avancer(1.0, true, 1) == "arrivee" and marchand.est_present(), "4 min sur l'île : il arrive")
	var palier_1 := true
	for id: String in marchand.offres:
		palier_1 = palier_1 and int(marchand.echange(id)["palier"]) == 1
	_verifier(marchand.offres.size() == 3 and palier_1 and marchand.replique() == str(marchand.repliques()[0]),
		"3 échanges du palier 1 et sa première réplique", str(marchand.offres))
	var inventaire := Inventaire.new()
	var id_echange: String = marchand.offres[0]
	var donnees_echange := marchand.echange(id_echange)
	_verifier(not marchand.peut_echanger(id_echange, inventaire), "sans les ouates demandées : pas d'échange")
	for id: String in donnees_echange["donne"]:
		inventaire.ajouter(id, int(donnees_echange["donne"][id]))
	var recu: String = donnees_echange["recoit"].keys()[0]
	_verifier(marchand.echanger(id_echange, inventaire) and inventaire.quantite(recu) == int(donnees_echange["recoit"][recu])
		and inventaire.quantite("nuage") == 0 and marchand.faits == [id_echange]
		and int(marchand.vendu.get("nuage", 0)) == int(donnees_echange["donne"].get("nuage", 0)),
		"échange : les ouates partent, la ressource arrive, mesures comptées")
	for id: String in donnees_echange["donne"]:
		inventaire.ajouter(id, int(donnees_echange["donne"][id]))
	_verifier(not marchand.echanger(id_echange, inventaire), "chaque échange une seule fois par passage")
	var plein := Inventaire.new()
	var autre: String = marchand.offres[1]
	for id: String in marchand.echange(autre)["donne"]:
		plein.ajouter(id, int(marchand.echange(autre)["donne"][id]))
	for id: String in marchand.echange(autre)["recoit"]:
		plein.ajouter(id, 99)
	_verifier(not marchand.peut_echanger(autre, plein), "inventaire plein pour ce qu'il donne : pas d'échange")
	_verifier(marchand.avancer(59.0, true, 1) == "" and marchand.avancer(1.0, true, 1) == "depart"
		and not marchand.est_present() and marchand.offres.is_empty() and is_equal_approx(marchand.attente, 240.0),
		"après 60 s, il repart et revient 4 min plus tard")

	# Passage pendant une plongée : il attend le retour sur l'île, puis reste ses 60 s.
	_verifier(marchand.avancer(300.0, false, 2) == "" and not marchand.est_present() and marchand.attente == 0.0,
		"il arrive pendant une plongée : il attend le retour")
	_verifier(marchand.avancer(0.0, true, 2) == "arrivee" and is_equal_approx(marchand.restant, 60.0)
		and marchand.replique() != str(marchand.repliques()[0]), "retour sur l'île : il est là pour 60 s, avec une autre réplique")
	marchand.avancer(20.0, true, 2)
	marchand.avancer(500.0, false, 2)
	_verifier(marchand.est_present() and is_equal_approx(marchand.restant, 40.0), "pendant une plongée, son temps s'arrête")
	var paires := {}
	var repliques := {}
	var palier_ok := true
	for visite in 12:
		marchand.arriver(2)
		paires[str(marchand.offres)] = true
		repliques[marchand.replique()] = true
		for id: String in marchand.offres:
			palier_ok = palier_ok and int(marchand.echange(id)["palier"]) == 2
	_verifier(paires.size() >= 3 and repliques.size() == 12 and palier_ok,
		"les échanges changent d'un passage à l'autre ; une réplique différente à chaque visite",
		"%d tirages, %d répliques" % [paires.size(), repliques.size()])
	var copie := Marchand.new()
	copie.charger(marchand.vers_dictionnaire())
	_verifier(copie.offres == marchand.offres and is_equal_approx(copie.restant, marchand.restant) and copie.visites == marchand.visites,
		"marchand relu tel quel")
	copie.charger({"attente": -5, "restant": 900, "offres": ["fusee", 3], "faits": "x", "visites": "y"})
	_verifier(copie.attente == 0.0 and not copie.est_present() and copie.offres.is_empty() and copie.visites == 0,
		"marchand lu : valeurs fausses bornées ou ignorées")
	copie.charger({})
	_verifier(is_equal_approx(copie.attente, 240.0) and not copie.est_present(), "sauvegarde d'avant le marchand : premier passage après 4 min")


func _test_marchand_ile() -> void:
	var son := _son()
	son.vider_historique()
	var ile := await _ouvrir_ile()
	var marchand: Marchand = _jeu.atelier.marchand
	var panneau: Node = ile.get_node("Marchand")
	marchand.attente = 0.05
	await _images(6)
	var annonce: String = ile.get_node("HUD").texte_annonce()
	_verifier(marchand.est_present() and annonce.contains("marchand") and son.a_joue("marchand"),
		"il arrive : annonce et corne", annonce)
	var debut: Vector2 = ile.position_marchand()
	await _secondes(4.5)
	var arret: Vector2 = ile.position_marchand()
	_verifier(debut.x > arret.x + 100.0 and absf(arret.x - _ile_script.POSITION_MARCHAND.x) < 1.0
		and absf(arret.y - _ile_script.POSITION_MARCHAND.y) <= 2.0, "le dirigeable glisse depuis la droite et s'arrête au-dessus de l'île",
		"%s puis %s" % [debut, arret])
	_souris(arret)
	await _images(2)
	var aide: String = ile._texte_aide()
	_verifier(aide.contains("Marchand") and aide.contains("repart"), "survol du dirigeable : l'aide", aide)
	# Un nuage devant le dirigeable ne prend pas le clic.
	var nuage := _nuage_degage(ile)
	var prises := nuage.stock
	nuage.position = arret
	await _cliquer(ile.position_marchand())
	_verifier(panneau.est_ouvert() and ile.panneau_ouvert() and nuage.stock == prises
		and panneau._replique.text.contains(marchand.replique()) and panneau._lignes.get_child_count() == 3,
		"clic sur le dirigeable (même avec un nuage devant) : sa réplique et 3 échanges", panneau._replique.text)
	var id_echange: String = marchand.offres[0]
	var donnees := marchand.echange(id_echange)
	var bouton: Button = panneau.bouton(id_echange)
	_verifier(bouton.disabled and bouton.text == "Échanger", "sans ouates : bouton Échanger grisé")
	for id: String in donnees["donne"]:
		_jeu.inventaire.ajouter(id, int(donnees["donne"][id]))
	await _images(2)
	var recu: String = donnees["recoit"].keys()[0]
	var avant: int = _jeu.inventaire.quantite(recu)
	await _cliquer(_centre(bouton))
	annonce = ile.get_node("HUD").texte_annonce()
	_verifier(_jeu.inventaire.quantite(recu) == avant + int(donnees["recoit"][recu]) and bouton.text == "Fait" and bouton.disabled
		and son.a_joue("echange") and annonce.contains("Échangé"), "clic sur Échanger : ressource reçue, « Fait », son et annonce", annonce)
	_touche(KEY_ESCAPE)
	await _images(2)
	_verifier(not panneau.est_ouvert(), "Échap ferme le panneau du marchand")
	await _cliquer(ile.position_marchand())
	marchand.restant = 0.2
	await _secondes(0.5)
	annonce = ile.get_node("HUD").texte_annonce()
	_verifier(not marchand.est_present() and not panneau.est_ouvert() and annonce.contains("repart"),
		"fin de son passage : il repart, son panneau se ferme", annonce)
	await _cliquer(arret)
	_verifier(not panneau.est_ouvert(), "parti : un clic au même endroit n'ouvre plus rien")
	await _fermer_ile(ile)


func _test_marchand_plongee_et_sauvegarde() -> void:
	var ile := await _ouvrir_ile()
	var marchand: Marchand = _jeu.atelier.marchand
	marchand.attente = 100.0
	ile.preparer_depart()
	await _images(3)
	ile.arriver(150.0, {}, {}, false)
	_verifier(not marchand.est_present() and marchand.attente == 0.0, "passage pendant la plongée : il n'est pas encore là")
	await _images(2)
	_verifier(marchand.est_present() and marchand.restant > 59.0, "retour sur l'île : il arrive, pour 60 s entières")
	await _fermer_ile(ile)

	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu()
	_jeu.atelier.marchand.arriver(1)
	_jeu.atelier.marchand.restant = 30.0
	var offres: Array = _jeu.atelier.marchand.offres.duplicate()
	_jeu.atelier.marchand.faits.append(offres[1])
	jeu.sauvegarder()
	await _fermer_jeu(jeu)
	jeu = await _ouvrir_jeu(true)
	jeu.continuer()
	await _images(2)
	var relu: Marchand = _jeu.atelier.marchand
	_verifier(relu.est_present() and relu.offres == offres and relu.faits == [offres[1]] and relu.restant > 29.0
		and relu.restant <= 30.0, "Continuer : le marchand est toujours là, mêmes échanges, celui déjà fait reste fait")
	await _fermer_jeu(jeu)
	jeu = await _ouvrir_jeu(true)
	await _cliquer(_centre(jeu._titre.bouton_nouvelle))
	await _cliquer(_centre(jeu._titre.bouton_remplacer))
	_verifier(not _jeu.atelier.marchand.est_present() and _jeu.atelier.marchand.attente > 239.0,
		"Nouvelle partie : le marchand repassera dans 4 min")
	await _fermer_jeu(jeu)
	_effacer_sauvegarde()


# --- Équilibrage final et confort --------------------------------------------------------------

func _test_equilibrage_final() -> void:
	var inventaire := Inventaire.new()
	var atelier := Atelier.new(inventaire)
	_verifier(int(atelier.machine("entrepot")["palier"]) == 3 and is_equal_approx(atelier.recharge_machine("fourneau"), 15.0)
		and int(atelier.machine("filet")["recharge_s"]) == 6,
		"entrepôt au palier 3, fourneau : 1 raffiné toutes les 15 s, filet inchangé (6 s)")
	atelier.palier = 3
	_ingredients(inventaire, atelier.machine("fourneau")["ingredients"])
	atelier.construire_machine("fourneau")
	_ingredients(inventaire, atelier.machine("fourneau")["ingredients"])
	_verifier(atelier.construire_machine("fourneau") != "" and atelier.nombre_machines("fourneau") == 2
		and atelier.recettes_fourneau.size() == 2, "deux fourneaux possibles, chacun sa recette")


func _test_confort_carnet() -> void:
	var ile := await _ouvrir_ile()
	var carnet: Carnet = _jeu.atelier.carnet
	var hud: Node = ile.get_node("HUD")
	var panneau: Node = ile.get_node("Carnet")
	await _images(2)
	_verifier(hud.bouton_carnet.text == "Carnet (K)", "rien de nouveau : « Carnet (K) »")
	var police: Font = hud.bouton_carnet.get_theme_font("font")
	_verifier(police.has_char("•".unicode_at(0)), "la police a le point « • »")
	carnet.trouver("perle_aube")
	carnet.trouver("dent_abysse")
	await _images(2)
	_verifier(hud.bouton_carnet.text == "Carnet (K) •" and carnet.a_voir == "dent_abysse",
		"nouvelle trouvaille : « Carnet (K) • »", hud.bouton_carnet.text)
	_touche(KEY_K)
	await _images(2)
	_verifier(panneau.page == "coraux" and panneau.selection == "dent_abysse" and panneau._nom.text == "Dent de l'abysse",
		"le carnet s'ouvre sur la dernière trouvaille", "%s / %s" % [panneau.page, panneau.selection])
	await _images(2)
	_verifier(hud.bouton_carnet.text == "Carnet (K)" and carnet.a_voir == "", "vue : le point disparaît")
	await _cliquer(_centre(panneau._onglets["lagon"]))
	panneau.selectionner("perle_aube")
	_touche(KEY_K)
	await _images(2)
	_touche(KEY_K)
	await _images(2)
	_verifier(panneau.page == "lagon" and panneau.selection == "perle_aube", "rien de nouveau : il se rouvre là où on l'a laissé")
	panneau.fermer()
	carnet.trouver("cle_braise")
	var copie := Carnet.new()
	copie.charger(carnet.vers_dictionnaire())
	_verifier(copie.a_voir == "cle_braise", "trouvaille pas encore vue : gardée dans la sauvegarde")
	copie.charger({"trouvailles": ["ammonite"], "a_voir": "perle_noire"})
	_verifier(copie.a_voir == "", "a_voir inconnu du carnet : ignoré")
	await _fermer_ile(ile)


func _test_confort_interface() -> void:
	# Nuages : toujours sous les boutons du haut (ni cachés ni impossibles à cliquer).
	var ile := await _ouvrir_ile()
	var hud: Node = ile.get_node("HUD")
	var reglage: Dictionary = Donnees.charger_json("res://data/ile.json")["nuages"]
	var haut_nuage := float(reglage["y_min"]) - SourceRessource.TAILLE_NUAGE.y
	var bas_boutons: float = hud.bouton_inventaire.get_global_rect().end.y
	_verifier(haut_nuage >= bas_boutons + 2.0, "nuages : jamais sous les boutons Inventaire et Carnet",
		"haut %.0f, boutons %.0f" % [haut_nuage, bas_boutons])
	var nuages_ok := true
	for i in 30:
		ile._creer_nuage(320.0)
	for enfant in ile.get_node("Nuages").get_children():
		var y: float = (enfant as Node2D).position.y
		nuages_ok = nuages_ok and y >= float(reglage["y_min"]) and y <= float(reglage["y_max"])
	_verifier(nuages_ok, "nuages : tous dans la bande du ciel")
	# Machines de l'îlot du nord : le bas d'un nuage reste au-dessus de leur toit (aucun ne passe devant).
	var bas_nuage := float(reglage["y_max"]) + SourceRessource.TAILLE_NUAGE.y
	var toit_nord: float = ile.centre_emplacement("nord_ouest").y - 16.0 * 2.0
	_verifier(bas_nuage <= toit_nord, "nuages : au-dessus des machines de l'îlot du nord",
		"bas %.0f, toits %.0f" % [bas_nuage, toit_nord])
	# Moulin plus grand, réserve en jauge au-delà de 10.
	_ingredients(_jeu.inventaire, _jeu.atelier.machine("moulin")["ingredients"])
	_jeu.atelier.construire_machine("moulin", "ile_ouest")
	_jeu.atelier.niveaux_machines["moulin"] = {"capacite": 2}
	ile.actualiser_machines()
	_verifier(ile.machine("ile_ouest").plafond == 24 and SourceRessource.POINTS_MAX == 10,
		"réserve ×3 du moulin (24) : affichée en jauge au-delà de 10")
	# Atelier resserré : une marge en haut et en bas, même avec le texte le plus long (arche).
	var atelier: Node = ile.get_node("Atelier")
	_jeu.atelier.palier = 3
	atelier.ouvrir()
	atelier.choisir_onglet("construction")
	atelier.selectionner("arche")
	await _images(3)
	var rect: Rect2 = (atelier.get_child(1) as Control).get_global_rect()
	_verifier(rect.position.y >= 16.0 and rect.end.y <= 344.0, "atelier : au moins 16 px de marge en haut et en bas",
		"de %.0f à %.0f" % [rect.position.y, rect.end.y])
	# Deuxième fourneau : l'atelier et l'annonce le suggèrent.
	_ingredients(_jeu.inventaire, _jeu.atelier.machine("fourneau")["ingredients"])
	atelier.ouvrir_machines("ile_centre")
	atelier.selectionner("fourneau")
	atelier.fabriquer_selection()
	await _images(2)
	var annonce: String = hud.texte_annonce()
	atelier.selectionner("fourneau")
	var effet_fourneau: String = atelier._effet.text
	atelier.fermer()
	_verifier(annonce.contains("deuxième fourneau") and effet_fourneau.contains("deuxième fourneau"),
		"premier fourneau : l'annonce et l'atelier suggèrent un deuxième", annonce)
	await _cliquer(ile.machine("ile_centre").position)
	atelier.selectionner("verre_lagon")
	_verifier(atelier._effet.text.contains("15 s"), "panneau du fourneau : 1 toutes les 15 s", atelier._effet.text)
	atelier.fermer()
	# Annonce du palier 3 : la liste se lit bien (virgule, puis « et »).
	_jeu.atelier.palier = 2
	ile.arriver(0.0, {"pierre_braise": 1}, {}, false)
	await _secondes(4.2)
	annonce = hud.texte_annonce()
	_verifier(annonce.contains("entrepôt, fourneau et sonde de plongée"), "palier 3 : entrepôt, fourneau et sonde annoncés", annonce)
	await _fermer_ile(ile)

	# Plongée : une longue annonce passe sous le panneau d'air, sans le chevaucher.
	await _demarrer()
	var interface: Node = _plongee.get_node("HUD")
	interface.annoncer("Page complète : La Faille volcanique consomme 20 % d'air en moins.")
	await _images(3)
	_verifier(not interface.rect_etat().intersects(interface.rect_annonce()) and interface.rect_annonce().end.x <= 640.0,
		"plongée : l'annonce passe sous le panneau d'air", "%s / %s" % [interface.rect_etat(), interface.rect_annonce()])
	await _terminer()


# --- Étape 4 (partie 2) : Faille volcanique ----------------------------------------------

## Aller-retour à pleine vitesse jusqu'à « fond » px ; renvoie [oxygène à 300 m, au fond, en surface, remontée auto].
func _aller_retour(fond: float) -> Array:
	Input.action_press("move_down")
	var o2_300 := -1.0
	var t := 0.0
	while _bell.position.y < fond - 0.5 and t < 80.0:
		await _images(1)
		t += 1.0 / IMAGES_PAR_S
		if o2_300 < 0.0 and _bell.position.y >= 3000.0:
			o2_300 = _plongee.oxygene
	var o2_fond: float = _plongee.oxygene
	Input.action_release("move_down")
	Input.action_press("move_up")
	t = 0.0
	while _bell.position.y > _dive_script.SEUIL_SURFACE and t < 80.0:
		await _images(1)
		t += 1.0 / IMAGES_PAR_S
	Input.action_release("move_up")
	return [o2_300, o2_fond, _plongee.oxygene, _bell.remontee_auto]


func _test_budget_faille() -> void:
	var conso_faille := float(Donnees.charger_json("res://data/zones.json")[2]["conso_oxygene"])
	_jeu.atelier.niveaux = {"cable": 2, "lanterne": 1, "reservoir": 2}
	await _demarrer()
	_jeu.atelier.niveaux = {"cable": 2, "lanterne": 1, "reservoir": 2}
	_plongee.appliquer_ameliorations()
	var mesure := await _aller_retour(4500.0)
	print("   réservoir 200 : 300 m → %.1f, 450 m → %.1f, retour en surface → %.1f" % [mesure[0], mesure[1], mesure[2]])
	var secondes: float = float(mesure[2]) / (_dive_script.CONSOMMATION_PAR_S * conso_faille)
	_verifier(not mesure[3] and float(mesure[2]) > 40.0, "budget 450 m (réservoir 200) : aller-retour sans remontée d'urgence",
		"%.0f d'air au retour" % mesure[2])
	_verifier(secondes >= 20.0, "budget 450 m : au moins 20 s de recherche et de minage au fond de la Faille",
		"%.1f s" % secondes)
	await _terminer()

	# Avec le réservoir de niveau 1 seulement, le fond de la Faille n'est pas atteignable sans risque.
	_jeu.atelier.niveaux = {"cable": 2, "lanterne": 1, "reservoir": 1}
	await _demarrer()
	_jeu.atelier.niveaux = {"cable": 2, "lanterne": 1, "reservoir": 1}
	_plongee.appliquer_ameliorations()
	var juste := await _aller_retour(4500.0)
	print("   réservoir 150 : 300 m → %.1f, 450 m → %.1f, retour en surface → %.1f%s" % [juste[0], juste[1], juste[2],
		" (remontée automatique)" if juste[3] else ""])
	_verifier(juste[3] or float(juste[2]) < 15.0, "réservoir 150 : le fond de la Faille est hors de portée (il faut le niveau 2)",
		"%.0f d'air au retour" % juste[2])
	await _terminer()
	_jeu.atelier.niveaux = {"cable": 0, "lanterne": 0, "reservoir": 0}


## Pierres de braise : leur lueur n'est jamais assombrie (même règle que le cyan et le corail).
func _test_lueur_braise() -> void:
	var lueur := Palette.couleur("or.5")
	_verifier(ArtAbysse.assombrir(lueur, 400.0, 500.0, 40.0, 3) == lueur and ArtAbysse.lueur("pierre_braise") == "or.5",
		"obscurité : la lueur des pierres de braise (or.5) n'est jamais assombrie")


## Coupe le son quelques images avant de quitter (le serveur audio relâche alors ses lectures).
func _couper_son_et_quitter(code: int) -> void:
	root.get_node("Son").arreter()
	for i in 10:
		await process_frame
		OS.delay_msec(20)   # le mixage audio tourne en temps réel, à côté des images
	quit(code)


# --- Audio ---------------------------------------------------------------------------------

func _son() -> Node:
	return root.get_node("Son")


func _test_synthese() -> void:
	var effets: Dictionary = Synthe.effets()
	var ok := effets.size() == Synthe.EFFETS.size()
	var detail := ""
	for id: String in effets:
		var s := Synthe.echantillons(effets[id])
		var crete := 0.0
		for v in s:
			crete = maxf(crete, absf(v))
		if s.size() < 200 or crete > Synthe.CRETE + 0.001 or crete < 0.05:
			ok = false
			detail += "%s (%d échantillons, crête %.2f) " % [id, s.size(), crete]
	_verifier(ok, "synthèse : les %d effets sont générés, sans saturation (crête ≤ %.1f)" % [effets.size(), Synthe.CRETE], detail)

	var ambiances: Dictionary = Synthe.ambiances()
	var boucles_ok := ambiances.size() == 4
	var raccords := ""
	for id: String in ambiances:
		var flux: AudioStreamWAV = ambiances[id]
		var s := Synthe.echantillons(flux)
		# Raccord : le saut de la fin au début ne dépasse pas le plus grand saut entre deux échantillons voisins.
		var plus_grand_saut := 0.0
		for i in range(1, s.size()):
			plus_grand_saut = maxf(plus_grand_saut, absf(s[i] - s[i - 1]))
		var saut := absf(s[0] - s[s.size() - 1])
		raccords += "%s %.3f/%.3f " % [id, saut, plus_grand_saut]
		boucles_ok = boucles_ok and flux.loop_mode == AudioStreamWAV.LOOP_FORWARD and flux.loop_end == s.size() \
			and saut <= plus_grand_saut and s.size() == int(Synthe.DUREE_BOUCLE * Synthe.FREQ_AMBIANCE)
	_verifier(boucles_ok, "synthèse : 4 ambiances en boucle de 8 s, raccord sans saut audible", raccords)
	var a := Synthe.echantillons(Synthe.effet("cristal"))
	var b := Synthe.echantillons(Synthe.effet("cristal"))
	_verifier(a == b, "synthèse : sons identiques d'une génération à l'autre (graine fixe)")


func _test_bus_et_volumes() -> void:
	var son := _son()
	var musique := AudioServer.get_bus_index("Musique")
	var effets := AudioServer.get_bus_index("Effets")
	_verifier(musique > 0 and effets > 0 and AudioServer.get_bus_send(musique) == "Master"
		and AudioServer.get_bus_send(effets) == "Master", "bus « Musique » et « Effets » vers Master")
	son.regler_volumes(0.5, 0.3)
	_verifier(is_equal_approx(AudioServer.get_bus_volume_db(musique), linear_to_db(0.5))
		and is_equal_approx(AudioServer.get_bus_volume_db(effets), linear_to_db(0.3)),
		"volumes appliqués aux bus (50 %% → %.1f dB)" % linear_to_db(0.5))
	son.regler_volumes(0.0, 1.43)
	_verifier(AudioServer.is_bus_mute(musique) and son.volume_effets == 1.0 and not AudioServer.is_bus_mute(effets),
		"volume à 0 : bus coupé ; au-delà de 100 % : ramené à 100 %")
	son.regler_volumes(0.7, 0.8)
	son.vider_historique()
	var premier: bool = son.jouer("unite")
	var second: bool = son.jouer("unite")
	_verifier(premier and not second, "anti-répétition : le même effet n'est pas rejoué tout de suite")
	_verifier(not son.jouer("inconnu"), "effet inconnu : ignoré sans planter")
	_verifier(AudioServer.get_driver_name() != "", "sans pilote audio réel : tout fonctionne (pilote « %s »)"
		% AudioServer.get_driver_name())


func _test_ambiances() -> void:
	var son := _son()
	son.ambiance("faille", 0.2)
	await _secondes(0.4)
	var lecteur: AudioStreamPlayer = son.lecteur_ambiance()
	_verifier(son.ambiance_actuelle == "faille" and lecteur.playing and lecteur.bus == "Musique"
		and (lecteur.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"ambiance : la Faille joue en boucle sur le bus Musique")
	son.ambiance("ile", 0.2)
	await _secondes(0.4)
	_verifier(son.ambiance_actuelle == "ile" and son.lecteur_ambiance() != lecteur and not lecteur.playing,
		"ambiance : fondu enchaîné vers l'île, l'ancienne s'arrête")


func _test_sons_ile() -> void:
	var son := _son()
	son.vider_historique()
	var ile := await _ouvrir_ile()
	var nuage := _nuage_degage(ile)
	await _cliquer(nuage.position)
	_verifier(son.a_joue("nuage"), "son : récolte d'un nuage")
	await _cliquer(ile._eolienne.position)
	_verifier(son.a_joue("vent"), "son : vent de l'éolienne")
	var filon: SourceRessource = ile._filons[0]
	_souris(filon.position)
	await _images(2)
	_bouton(filon.position, true)
	await _secondes(1.1)
	_bouton(filon.position, false)
	await _images(2)
	_verifier(son.a_joue("cristal"), "son : cristal solaire")
	_jeu.inventaire.ajouter("nuage", 3)
	_jeu.inventaire.ajouter("vent", 1)
	var atelier: Node = ile.get_node("Atelier")
	atelier.ouvrir()
	atelier.choisir_onglet("composants")
	atelier.selectionner("fil_nuage")
	await _images(3)   # mise en page du panneau avant de viser le bouton
	await _cliquer(atelier._bouton.get_global_rect().get_center())
	_verifier(son.a_joue("fabrication") and son.a_joue("clic"), "son : fabrication à l'atelier et clic du bouton")
	atelier.fermer()
	await _fermer_ile(ile)


func _test_sons_plongee() -> void:
	var son := _son()
	son.vider_historique()
	await _demarrer()
	var gisement := _gisements()[0]
	_bell.position = gisement.position
	_bell.velocity = Vector2.ZERO
	Input.action_press("interact")
	await _secondes(1.2)
	Input.action_release("interact")
	_verifier(son.a_joue("minage") and son.a_joue("unite"), "son : coups de minage puis unité gagnée")
	for i in Sac.CAPACITE:
		_plongee._sac.ajouter("cristal_lagon")
	_plongee._sac._unites.pop_back()
	var autre := _gisements()[0]
	_bell.position = autre.position
	Input.action_press("interact")
	await _secondes(1.2)
	Input.action_release("interact")
	_verifier(son.a_joue("sac_plein"), "son : sac plein")
	_bell.position = Vector2(0.0, 1400.0)
	_bell.velocity = Vector2.ZERO
	Input.action_press("move_down")
	await _secondes(2.5)
	_verifier(son.a_joue("craquement") and _plongee.au_bout_du_cable(), "son : craquement de la coque au bout du câble (150 m)",
		"%.0f m, au bout : %s" % [_bell.position.y / 10.0, _plongee.au_bout_du_cable()])
	Input.action_release("move_down")
	_plongee.oxygene = _plongee.oxygene_max * 0.2
	await _secondes(0.3)
	_verifier(son.a_joue("oxygene_bas"), "son : bip quand l'air est bas")
	_plongee.oxygene = 0.0
	await _images(3)
	_verifier(son.a_joue("remontee_auto"), "son : remontée automatique")
	await _terminer()

	_jeu.atelier.niveaux = {"cable": 2, "lanterne": 0, "reservoir": 0}
	await _demarrer()
	_jeu.atelier.niveaux = {"cable": 2, "lanterne": 0, "reservoir": 0}
	_plongee.appliquer_ameliorations()
	_bell.position = Vector2(0.0, 1700.0)
	await _images(3)
	var coraux: String = son.ambiance_actuelle
	_bell.position = Vector2(0.0, 3300.0)
	await _images(3)
	_verifier(coraux == "coraux" and son.ambiance_actuelle == "faille", "ambiance : Coraux puis Faille selon la profondeur")
	await _terminer()
	_jeu.atelier.niveaux = {"cable": 0, "lanterne": 0, "reservoir": 0}


func _test_sons_transitions() -> void:
	var son := _son()
	son.vider_historique()
	var jeu := await _ouvrir_jeu()
	_touche(KEY_E)
	await _images(3)
	_verifier(son.a_joue("souffle") and son.ambiance_actuelle == "lagon", "transition : souffle et fondu vers l'ambiance du Lagon")
	await _attendre_etat(jeu, ETAT_PLONGEE)
	son.vider_historique()
	await _remonter(jeu)
	await _images(3)
	_verifier(son.a_joue("souffle") and son.ambiance_actuelle == "ile", "remontée : souffle et retour de la nappe de l'île")
	await _fermer_jeu(jeu)


func _test_volumes_sauvegarde() -> void:
	var son := _son()
	_effacer_sauvegarde()
	son.regler_volumes(0.7, 0.8)
	var jeu := await _ouvrir_jeu()
	var pause: Node = jeu._pause
	_touche(KEY_ESCAPE)
	await _images(2)
	await _cliquer(pause.boutons_volume["musique"][0].get_global_rect().get_center())
	await _cliquer(pause.boutons_volume["musique"][0].get_global_rect().get_center())
	await _cliquer(pause.boutons_volume["effets"][1].get_global_rect().get_center())
	_verifier(is_equal_approx(son.volume_musique, 0.5) and is_equal_approx(son.volume_effets, 0.9),
		"menu pause : − et + règlent musique et effets par pas de 10 %", "%.1f / %.1f" % [son.volume_musique, son.volume_effets])
	var sauve: Dictionary = Sauvegarde.lire()["partie"].get("reglages", {})
	_verifier(is_equal_approx(float(sauve.get("musique", -1.0)), 0.5) and is_equal_approx(float(sauve.get("effets", -1.0)), 0.9),
		"volumes enregistrés dans la sauvegarde", str(sauve))
	jeu.fermer_pause()
	await _fermer_jeu(jeu)

	son.regler_volumes(1.0, 1.0)
	jeu = await _ouvrir_jeu(true)
	_verifier(is_equal_approx(son.volume_musique, 0.5) and is_equal_approx(son.volume_effets, 0.9),
		"écran titre : les volumes de la sauvegarde sont repris")
	await _fermer_jeu(jeu)

	Sauvegarde.ecrire({"inventaire": {}, "ameliorations": {}, "ilots": [], "ile": {}, "reglages": {"musique": "fort"}})
	jeu = await _ouvrir_jeu(true)
	_verifier(is_equal_approx(son.volume_musique, 0.7) and is_equal_approx(son.volume_effets, 0.8),
		"réglages faux ou absents : volumes par défaut (70 % / 80 %)")
	await _fermer_jeu(jeu)
	son.regler_volumes(0.7, 0.8)
	_effacer_sauvegarde()
