extends SceneTree
## Tests de logique (étapes 1 à 3). Lancement : voir tests/lancer.sh ou le README.
## Chaque vérification affiche PASS ou FAIL, puis un total ; code de sortie 1 s'il y a un échec.

const SCENE_PLONGEE := "res://scenes/dive.tscn"
const SCENE_ILE := "res://scenes/ile.tscn"
const SCENE_JEU := "res://scenes/jeu.tscn"
const ETAT_ILE := 0
const ETAT_DESCENTE := 1
const ETAT_PLONGEE := 2
const ETAT_REMONTEE := 3
const IMAGES_PAR_S := 60.0

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


func _initialize() -> void:
	_lancer()


func _lancer() -> void:
	await process_frame
	_jeu = root.get_node("Game")
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

	_titre("Rendu pixel art")
	_test_rendu_pixel()
	await _test_monde_320()
	await _test_camera_plongee()

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
			if gisement.minerai == "cristal_lagon":
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


func _test_recolte() -> void:
	var ile := await _ouvrir_ile()

	var nuage: SourceRessource = ile.get_node("Nuages").get_child(0)
	nuage.derive = 0.0
	var prises: int = nuage.stock
	await _cliquer(nuage.position)
	_verifier(_jeu.inventaire.quantite("nuage") == 1 and nuage.stock == prises - 1,
		"nuage : un clic = une ouate de nuage", "stock %d → %d" % [prises, nuage.stock])

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
	nuage.position = Vector2(60.0, 60.0)  # hors du panneau (sinon le clic tombe sur le panneau)
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


func _ouvrir_jeu() -> Node:
	_jeu.inventaire = Inventaire.new()
	var jeu: Node = load(SCENE_JEU).instantiate()
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

