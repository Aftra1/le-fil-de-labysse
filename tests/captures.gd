extends SceneTree
## Joue deux scénarios automatiques et enregistre les captures PNG dans docs/captures/ :
## 00 : la palette ; 01-05 : la plongée seule (dive.tscn) ; 06-13 : le jeu complet (île, transitions, plongée) ;
## 14-19 : l'atelier et les améliorations de la cloche (câble, lanterne, réservoir) ;
## 28-29 : la Faille volcanique (pierre de braise, fond de magma, lanterne de niveau 2) ;
## 20-27 : écran titre, îlot (22-24 : non relié, construction de la passerelle, relié), menu pause,
## sauvegarde abîmée ; 30-32 : machines du palier 1 (emplacement libre, onglet Machines, moulin et filet) ;
## 33-35 : palier 2 (îlot du nord isolé, amélioration d'une machine, foreuse, entrepôt et îlot du nord relié) ;
## 36-38 : palier 3 (arche de braise à l'atelier, panneau du fourneau, fourneau et sonde sur l'île).
## Chaque capture est vérifiée : tous ses pixels doivent être des couleurs de data/palette.json
## (un antialiasing ou une transparence créerait des couleurs intermédiaires).
## On vérifie aussi la grille du monde (320x180 affiché ×2) : interface masquée, chaque bloc de 2x2
## pixels d'écran doit être d'une seule couleur (aucun pixel du monde plus petit). Les blocs commencent
## au décalage de la caméra (0 ou 1 pixel d'écran) : la vérification en tient compte.
## Enfin, on vérifie les raccords : fin de la descente = début de la plongée, fin de la plongée =
## début de la remontée, au pixel près (horloge des particules figée pendant la comparaison).
## Nécessite un affichage (Xvfb + Mesa logiciel) : voir tests/captures.sh.

const DOSSIER := "res://docs/captures/"
const ECHELLE := 2  # 640x360 agrandi ×2 en « plus proche voisin » pour rester lisible
## Les captures n'utilisent jamais la vraie sauvegarde.
const SAUVEGARDE_CAPTURES := "user://captures_sauvegarde.json"

var _plongee: Node
var _bell: CharacterBody2D
var _palette: Dictionary = {}      # couleur RGBA8 -> nom
var _captures_hors_palette := 0


func _initialize() -> void:
	_scenarios()


func _scenarios() -> void:
	await process_frame
	Sauvegarde.chemin = SAUVEGARDE_CAPTURES
	_effacer_sauvegarde()
	for nom: String in Palette.noms():
		_palette[Palette.couleur(nom).to_rgba32()] = nom
	await _planche_palette()
	await _scenario_plongee()
	await _scenario_jeu()
	await _scenario_ameliorations()
	await _scenario_ilot()
	await _scenario_machines()
	await _scenario_palier2()
	await _scenario_palier3()
	await _scenario_menus()
	_effacer_sauvegarde()
	print("PALETTE : %s" % ("toutes les captures respectent la palette" if _captures_hors_palette == 0
		else "%d capture(s) avec des couleurs hors palette" % _captures_hors_palette))
	await _couper_son_et_quitter(0 if _captures_hors_palette == 0 else 1)


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
	# Câble tressé installé : la capture de la forêt de coraux descend à 220 m.
	_atelier().niveaux["cable"] = 1
	_plongee = load("res://scenes/dive.tscn").instantiate()
	root.add_child(_plongee)
	_bell = _plongee.get_node("Bell")
	await _images(30)

	await _capturer("01-surface")

	var cristal := _gisement_proche("cristal_lagon", 450.0)
	_placer_pres_de(cristal, Vector2(-48.0, -22.0))
	await _images(20)
	await _capturer("02-zone1-gisement")
	await _verifier_grille_plongee(_plongee)

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
	jeu.avec_titre = false
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
	# Un nuage né sous le bouton « Inventaire » ouvrirait l'inventaire au lieu d'être récolté.
	if (ile.get_node("HUD").bouton_inventaire as Control).get_global_rect().grow(4.0).has_point(nuage.position):
		nuage.position = Vector2(320.0, 90.0)
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
	await _verifier_grille(transition.decalage_ecran, "transition à 25 %, île et ciel")
	transition.afficher_image(0.75)
	await _images(2)
	await _capturer("10-descente-75")
	await _verifier_grille(transition.decalage_ecran, "transition à 75 %")
	transition.afficher_image(0.95)
	await _images(2)
	await _capturer("10b-descente-hud-entre")
	await _verifier_raccord_descente(jeu, transition)
	await _images(2)
	await _capturer("11-plongee-arrivee")

	var plongee: Node = jeu.plongee()
	await _verifier_raccord_remontee(jeu, transition, plongee)
	# Remontée d'urgence avec un sac plein : image figée à 50 %, puis retour sur l'île
	transition.reprendre()
	while jeu.etat != 0:  # ILE
		await _images(1)
	await _images(5)
	await _cliquer(Vector2(320, 318))
	transition.passer()
	while jeu.etat != 2:  # PLONGEE
		await _images(1)
	plongee = jeu.plongee()
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

	# Atelier : un composant faisable, puis une amélioration dont il manque des ingrédients
	_atelier().niveaux["cable"] = 0
	var inventaire: Inventaire = root.get_node("Game").inventaire
	inventaire.ajouter("nuage", 4)
	inventaire.ajouter("vent", 2)
	inventaire.ajouter("cristal_lagon", 1)
	_touche(KEY_C)
	await _images(3)
	var atelier: Node = ile.get_node("Atelier")
	atelier.choisir_onglet("composants")
	atelier.selectionner("fil_nuage")
	await _images(3)
	await _capturer("14-atelier-composant")
	atelier.choisir_onglet("ameliorations")
	atelier.selectionner("lanterne")
	await _images(3)
	await _capturer("15-atelier-amelioration")
	_touche(KEY_C)
	await _images(3)
	root.remove_child(jeu)
	jeu.queue_free()
	await _images(2)


# --- 16-19 : améliorations de la cloche en plongée ------------------------------------

func _scenario_ameliorations() -> void:
	# Câble de départ : la cloche s'arrête à 150 m
	_atelier().niveaux = { "cable": 0, "lanterne": 0, "reservoir": 0 }
	var plongee := await _nouvelle_plongee()
	var cloche: CharacterBody2D = plongee.get_node("Bell")
	cloche.position.y = 1440.0
	Input.action_press("move_down")
	await _images(150)
	Input.action_release("move_down")
	await _images(30)
	await _capturer("16-cable-maximum")
	await _fermer_plongee(plongee)

	# Obscurité à 120 m, sans puis avec la lanterne ; vérification du shader au pixel près
	for lanterne in [0, 1]:
		_atelier().niveaux["lanterne"] = lanterne
		plongee = await _nouvelle_plongee()
		cloche = plongee.get_node("Bell")
		cloche.position = Vector2(-40.0, 1200.0)
		cloche.controle_actif = false
		ArtAbysse.figer_temps = true
		await _images(120)
		await _capturer("17-obscurite-sans-lanterne" if lanterne == 0 else "18-obscurite-avec-lanterne")
		await _verifier_obscurite(plongee)
		ArtAbysse.figer_temps = false
		await _fermer_plongee(plongee)

	# Réservoir d'air : jauge plus longue
	_atelier().niveaux = { "cable": 1, "lanterne": 1, "reservoir": 1 }
	plongee = await _nouvelle_plongee()
	plongee.get_node("Bell").position.y = 400.0
	await _images(60)
	await _capturer("19-hud-reservoir")
	await _fermer_plongee(plongee)

	# Faille volcanique : une pierre de braise à portée (lanterne niveau 1), puis le fond et son magma
	# (lanterne niveau 2) ; la règle d'obscurité est vérifiée au pixel près, lueur des braises comprise.
	_atelier().niveaux = { "cable": 2, "lanterne": 1, "reservoir": 2 }
	plongee = await _nouvelle_plongee()
	cloche = plongee.get_node("Bell")
	var braise: Node2D = null
	for enfant in plongee.get_node("Gisements").get_children():
		if enfant.minerai == "pierre_braise" and (braise == null or enfant.position.y < braise.position.y):
			braise = enfant
	cloche.position = braise.position + Vector2(-16.0, -6.0)
	cloche.controle_actif = false
	ArtAbysse.figer_temps = true
	await _images(120)
	await _capturer("28-faille-braise")
	await _verifier_obscurite(plongee)
	ArtAbysse.figer_temps = false
	await _fermer_plongee(plongee)

	_atelier().niveaux = { "cable": 2, "lanterne": 2, "reservoir": 2 }
	plongee = await _nouvelle_plongee()
	cloche = plongee.get_node("Bell")
	cloche.position = Vector2(30.0, 4500.0)
	cloche.controle_actif = false
	ArtAbysse.figer_temps = true
	await _images(120)
	await _capturer("29-faille-fond")
	await _verifier_obscurite(plongee)
	ArtAbysse.figer_temps = false
	await _fermer_plongee(plongee)


# --- 22-24 : îlot, passerelle de nuage, bassin de lumière ---------------------------

func _scenario_ilot() -> void:
	root.get_node("Game").inventaire = Inventaire.new()
	var jeu: Node = load("res://scenes/jeu.tscn").instantiate()
	jeu.avec_titre = false
	root.add_child(jeu)
	var ile: Node = jeu.get_node("Ile")
	await _images(20)
	_souris(ile.centre_ilot())
	await _images(5)
	await _capturer("22-ilot-non-relie")
	await _verifier_grille_monde(ile)

	var inventaire: Inventaire = root.get_node("Game").inventaire
	inventaire.ajouter("fil_nuage", 4)
	inventaire.ajouter("cristal_solaire", 3)
	inventaire.ajouter("corail", 2)
	await _cliquer(ile.centre_ilot())
	var atelier: Node = ile.get_node("Atelier")
	atelier.selectionner("passerelle")
	await _images(3)
	await _capturer("23-atelier-construction")
	atelier.fabriquer_selection()
	atelier.fermer()
	_souris(ile.bassin().position)
	await _images(30)
	await _capturer("24-ilot-relie")
	await _verifier_grille_monde(ile)
	await _fermer_jeu(jeu)
	root.get_node("Game").inventaire = Inventaire.new()


# --- 30-32 : machines du palier 1 --------------------------------------------------------

func _scenario_machines() -> void:
	root.get_node("Game").inventaire = Inventaire.new()
	var jeu: Node = load("res://scenes/jeu.tscn").instantiate()
	jeu.avec_titre = false
	root.add_child(jeu)
	var ile: Node = jeu.get_node("Ile")
	await _images(20)
	_souris(ile.centre_emplacement("ile_centre"))
	await _images(5)
	await _capturer("30-emplacement-libre")
	await _verifier_grille_monde(ile)

	var inventaire: Inventaire = root.get_node("Game").inventaire
	inventaire.ajouter("fil_nuage", 5)
	inventaire.ajouter("cristal_lagon", 5)
	inventaire.ajouter("cristal_solaire", 2)
	await _cliquer(ile.centre_emplacement("ile_centre"))
	var atelier: Node = ile.get_node("Atelier")
	atelier.selectionner("moulin")
	await _images(3)
	await _capturer("31-atelier-machines")
	atelier.fabriquer_selection()
	# Îlot relié : le filet va sur son emplacement.
	_atelier().ilots_relies.append("ilot_est")
	ile.actualiser_ilot()
	atelier.emplacement_cible = "ilot_est"
	atelier.selectionner("filet")
	atelier.fabriquer_selection()
	atelier.fermer()
	ile.machine("ile_centre").stock = 5
	ile.machine("ilot_est").stock = 7
	_souris(ile.machine("ile_centre").position)
	await _images(40)
	await _capturer("32-machines")
	await _verifier_grille_monde(ile)
	await _fermer_jeu(jeu)
	root.get_node("Game").inventaire = Inventaire.new()


# --- 33-35 : palier 2 ------------------------------------------------------------------------

func _scenario_palier2() -> void:
	root.get_node("Game").inventaire = Inventaire.new()
	var jeu: Node = load("res://scenes/jeu.tscn").instantiate()
	jeu.avec_titre = false
	root.add_child(jeu)
	var ile: Node = jeu.get_node("Ile")
	await _images(20)
	_souris(ile.centre_ilot("ilot_nord"))
	await _images(5)
	await _capturer("33-ilot-nord-isole")

	var atelier_logique := _atelier()
	var inventaire: Inventaire = root.get_node("Game").inventaire
	atelier_logique.palier = 2
	for id: String in ["moulin", "foreuse", "entrepot"]:
		for ingredient: String in atelier_logique.machine(id)["ingredients"]:
			inventaire.ajouter(ingredient, int(atelier_logique.machine(id)["ingredients"][ingredient]))
	inventaire.ajouter("corail", 4)
	inventaire.ajouter("fil_nuage", 4)
	atelier_logique.construire("pont")
	atelier_logique.construire_machine("moulin", "ile_centre")
	atelier_logique.construire_machine("foreuse", "filon_2")
	atelier_logique.construire_machine("entrepot", "nord_est")
	ile.actualiser_ilot()
	ile.actualiser_machines()
	inventaire.ajouter("fil_nuage", 2)
	inventaire.ajouter("cristal_lagon", 3)
	var atelier: Node = ile.get_node("Atelier")
	atelier.ouvrir()
	atelier.choisir_onglet("machines")
	atelier.selectionner("moulin")
	atelier.choisir_mode("vitesse")
	await _images(3)
	await _capturer("34-atelier-amelioration")
	atelier.fermer()
	ile.machine("ile_centre").stock = 4
	ile.machine("filon_2").stock = 3
	_souris(ile.machine("filon_2").position)
	await _images(40)
	await _capturer("35-palier2")
	await _verifier_grille_monde(ile)
	await _fermer_jeu(jeu)
	root.get_node("Game").inventaire = Inventaire.new()


# --- 36-38 : palier 3 ------------------------------------------------------------------------

func _scenario_palier3() -> void:
	root.get_node("Game").inventaire = Inventaire.new()
	var jeu: Node = load("res://scenes/jeu.tscn").instantiate()
	jeu.avec_titre = false
	root.add_child(jeu)
	var ile: Node = jeu.get_node("Ile")
	await _images(20)
	var logique := _atelier()
	var inventaire: Inventaire = root.get_node("Game").inventaire
	logique.palier = 3
	for id: String in ["moulin", "filet", "foreuse", "entrepot", "fourneau", "sonde"]:
		for ingredient: String in logique.machine(id)["ingredients"]:
			inventaire.ajouter(ingredient, int(logique.machine(id)["ingredients"][ingredient]))
	inventaire.ajouter("corail", 4)
	inventaire.ajouter("fil_nuage", 4)
	logique.construire("pont")
	logique.ilots_relies.append("ilot_est")
	logique.construire_machine("moulin", "ile_ouest")
	logique.construire_machine("filet", "ile_centre")
	logique.construire_machine("foreuse", "filon_2")
	logique.construire_machine("entrepot", "nord_est")
	logique.construire_machine("fourneau", "nord_ouest")
	logique.construire_machine("sonde", "ilot_est")
	ile.actualiser_ilot()
	ile.actualiser_machines()
	inventaire.ajouter("pierre_braise", 2)
	inventaire.ajouter("lingot_solaire", 4)
	inventaire.ajouter("vent", 90)
	var atelier: Node = ile.get_node("Atelier")
	atelier.ouvrir()
	atelier.choisir_onglet("construction")
	atelier.selectionner("arche")
	await _images(3)
	await _capturer("36-atelier-arche")
	atelier.fermer()
	inventaire.ajouter("cristal_solaire", 30)
	inventaire.ajouter("vent", 30)
	await _cliquer(ile.machine("nord_ouest").position)
	atelier.selectionner("lingot_solaire")
	await _images(3)
	await _capturer("37-fourneau")
	atelier.fabriquer_selection()
	atelier.fermer()
	ile.rattraper(45.0)
	ile.machine("ilot_est").stock = 3
	logique.ilots_relies.append("ilot_couchant")
	ile.actualiser_ilot()
	_souris(ile.machine("nord_ouest").position + Vector2(1, 0))
	await _images(40)
	await _capturer("38-palier3")
	await _verifier_grille_monde(ile)
	await _fermer_jeu(jeu)
	root.get_node("Game").inventaire = Inventaire.new()


# --- 20-27 : écran titre, menu pause, sauvegarde abîmée ------------------------------

func _scenario_menus() -> void:
	_atelier().niveaux = { "cable": 0, "lanterne": 0, "reservoir": 0 }
	_effacer_sauvegarde()
	var jeu := await _ouvrir_jeu_titre()
	await _capturer("21-titre-sans-sauvegarde")
	jeu.nouvelle_partie()
	var inventaire: Inventaire = root.get_node("Game").inventaire
	inventaire.ajouter("vent", 3)
	inventaire.ajouter("nuage", 2)
	jeu.sauvegarder()
	await _fermer_jeu(jeu)

	jeu = await _ouvrir_jeu_titre()
	await _capturer("20-titre")
	var titre: Node = jeu.get_node("EcranTitre")
	titre.demander_nouvelle_partie()
	await _images(3)
	await _capturer("20b-titre-confirmation")
	titre.annuler_confirmation()
	jeu.continuer()
	await _images(10)
	_touche(KEY_ESCAPE)
	await _images(5)
	await _capturer("25-pause-ile")
	jeu.fermer_pause()

	_touche(KEY_E)
	while jeu.etat != 2:   # Etat.PLONGEE
		await _images(1)
	jeu.plongee().get_node("Bell").position.y = 300.0
	await _images(60)
	_touche(KEY_ESCAPE)
	await _images(5)
	await _capturer("26-pause-plongee")
	jeu.retour_au_titre()
	await _images(3)
	await _fermer_jeu(jeu)

	_effacer_sauvegarde()
	var fichier := FileAccess.open(SAUVEGARDE_CAPTURES, FileAccess.WRITE)
	fichier.store_string("{ abîmée")
	fichier.close()
	jeu = await _ouvrir_jeu_titre()
	await _capturer("27-sauvegarde-abimee")
	await _fermer_jeu(jeu)


func _ouvrir_jeu_titre() -> Node:
	var jeu: Node = load("res://scenes/jeu.tscn").instantiate()
	root.add_child(jeu)
	await _images(20)
	return jeu


func _fermer_jeu(jeu: Node) -> void:
	root.remove_child(jeu)
	jeu.queue_free()
	await _images(2)


func _effacer_sauvegarde() -> void:
	var base := SAUVEGARDE_CAPTURES.get_basename()
	for chemin: String in [SAUVEGARDE_CAPTURES, base + ".bak", base + ".tmp", base + ".corrompue.json"]:
		if FileAccess.file_exists(chemin):
			DirAccess.remove_absolute(chemin)


func _atelier() -> Atelier:
	return root.get_node("Game").atelier


func _nouvelle_plongee() -> Node:
	var plongee: Node = load("res://scenes/dive.tscn").instantiate()
	root.add_child(plongee)
	await _images(3)
	return plongee


func _fermer_plongee(plongee: Node) -> void:
	root.remove_child(plongee)
	plongee.queue_free()
	await _images(2)


## Compare l'image avec obscurité à l'image sans (shader retiré) : chaque pixel doit être exactement
## celui que prévoit la règle (ArtAbysse.assombrir), interface masquée.
func _verifier_obscurite(plongee: Node) -> void:
	var monde: Node = plongee.get_node("Monde")
	plongee.get_node("HUD").visible = false
	await _images(2)
	var avec := await _image_ecran()
	var reste: Vector2i = monde.decalage_ecran()
	var origine: Vector2 = monde.origine_monde()
	var cloche := VueMonde.vers_monde(plongee.get_node("Bell").position) - origine
	var materiau: Material = monde.material
	monde.material = null
	await _images(2)
	var sans := await _image_ecran()
	monde.material = materiau
	plongee.get_node("HUD").visible = true
	var atelier := _atelier()
	var ecarts := 0
	var assombris := 0
	for y in sans.get_height():
		for x in sans.get_width():
			var texel := Vector2(floori((x + reste.x) / 2.0), floori((y + reste.y) / 2.0))
			var profondeur_m := (origine.y + texel.y) / ArtAbysse.PX_PAR_METRE
			var attendu := ArtAbysse.assombrir(sans.get_pixel(x, y), profondeur_m, texel.distance_to(cloche),
				atelier.rayon_halo(), atelier.obscurite_max())
			if attendu != sans.get_pixel(x, y):
				assombris += 1
			if not attendu.is_equal_approx(avec.get_pixel(x, y)):
				ecarts += 1
	if ecarts == 0:
		print("      obscurité OK : %d pixels assombris, tous comme prévu (halo %.0f, noir max %d)" % [assombris, atelier.rayon_halo(), atelier.obscurite_max()])
	else:
		_captures_hors_palette += 1
		print("      OBSCURITÉ : %d pixels différents de la règle" % ecarts)


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
	await _verifier_grille(func() -> Vector2i: return Vector2i.ZERO, "île")
	ile.get_node("HUD").visible = true


## Plongée : on attend une image où la caméra est décalée d'un pixel d'écran (cas le plus délicat),
## puis on vérifie aussi une image sans décalage.
func _verifier_grille_plongee(plongee: Node) -> void:
	var monde: Node = plongee.get_node("Monde")
	plongee.get_node("HUD").visible = false
	var cloche: Node2D = plongee.get_node("Bell")
	cloche.position.y += 37.0
	for i in 60:
		await _images(1)
		if monde.decalage_ecran().y == 1:
			break
	await _verifier_grille(monde.decalage_ecran, "plongée")
	for i in 120:
		await _images(1)
		if monde.decalage_ecran().y == 0:
			break
	await _verifier_grille(monde.decalage_ecran, "plongée")
	plongee.get_node("HUD").visible = true


## decalage : Callable() -> Vector2i, lu juste après le rendu de l'image vérifiée (la caméra bouge
## pendant la vérification : un décalage lu une image trop tôt fausserait le résultat).
func _verifier_grille(decalage: Callable, nom: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var decalage_attendu: Vector2i = decalage.call()
	var ecarts := _blocs_non_uniformes(image, decalage_attendu)
	if ecarts == 0:
		print("      grille du monde OK (%s, décalage %s) : chaque pixel du monde fait 2x2 pixels d'écran" % [nom, decalage_attendu])
	else:
		_captures_hors_palette += 1
		print("      GRILLE DU MONDE (%s, décalage %s) : %d blocs 2x2 non uniformes" % [nom, decalage_attendu, ecarts])


## Les pixels du monde commencent au décalage d'écran (0 ou 1) : on compte les blocs 2x2 bigarrés.
func _blocs_non_uniformes(image: Image, decalage: Vector2i) -> int:
	var ecarts := 0
	var depart := Vector2i((2 - decalage.x) % 2, (2 - decalage.y) % 2)
	for y in range(depart.y, image.get_height() - 1, 2):
		for x in range(depart.x, image.get_width() - 1, 2):
			var couleur := image.get_pixel(x, y)
			if image.get_pixel(x + 1, y) != couleur or image.get_pixel(x, y + 1) != couleur \
					or image.get_pixel(x + 1, y + 1) != couleur:
				ecarts += 1
	return ecarts


## Fin de la descente (image figée à 100 %) contre première image de la plongée.
func _verifier_raccord_descente(jeu: Node, transition: Node) -> void:
	ArtAbysse.figer_temps = true
	transition.afficher_image(1.0)
	await _images(2)
	var fin_transition := await _image_ecran()
	transition.reprendre()
	while jeu.etat != 2:  # PLONGEE
		await _images(1)
	await _images(2)
	var debut_plongee := await _image_ecran()
	ArtAbysse.figer_temps = false
	_comparer(fin_transition, debut_plongee, "fin de la descente / début de la plongée, HUD compris")


## Dernière image de la plongée (cloche revenue en surface) contre première image de la remontée.
func _verifier_raccord_remontee(jeu: Node, transition: Node, plongee: Node) -> void:
	ArtAbysse.figer_temps = true
	var cloche: Node2D = plongee.get_node("Bell")
	cloche.position = Vector2(60.0, 2.0)
	await _images(90)
	var fin_plongee := await _image_ecran()
	plongee._armee = true
	plongee._sous_leau_avant = true
	while jeu.etat != 3:  # REMONTEE
		await _images(1)
	transition.afficher_image(0.0)
	await _images(2)
	var debut_remontee := await _image_ecran()
	ArtAbysse.figer_temps = false
	_comparer(fin_plongee, debut_remontee, "fin de la plongée / début de la remontée, HUD compris")
	transition.afficher_image(0.05)
	await _images(2)
	await _capturer("11b-remontee-hud-sort")


func _image_ecran() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_viewport().get_texture().get_image()


func _comparer(a: Image, b: Image, nom: String) -> void:
	var differences := 0
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				differences += 1
	if differences == 0:
		print("      raccord OK (%s) : images identiques au pixel près" % nom)
	else:
		_captures_hors_palette += 1
		print("      RACCORD (%s) : %d pixels différents" % [nom, differences])


## Coupe le son quelques images avant de quitter (le serveur audio relâche alors ses lectures).
func _couper_son_et_quitter(code: int) -> void:
	root.get_node("Son").arreter()
	for i in 10:
		await process_frame
		OS.delay_msec(20)   # le mixage audio tourne en temps réel, à côté des images
	quit(code)
