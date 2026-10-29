# Architecture du code

> Fichier généré automatiquement, ne pas modifier. Source : les scripts `.gd` ; régénérer avec `python3 tests/generer_miroir.py`.
> Miroir Python (pour les outils qui ne lisent pas le GDScript) : `docs/miroir/`.

## Vue d'ensemble

| Script | Classe | Hérite de | Rôle |
|---|---|---|---|
| `scripts/art_abysse.gd` | ArtAbysse | RefCounted | Pixel art de l'abysse (plongée), dessiné dans le monde 320x180 (voir VueMonde). |
| `scripts/art_ile.gd` | ArtIle | RefCounted | Pixel art du monde du haut (île, ciel, nuages, cloche, interface), généré en code. |
| `scripts/atelier.gd` | Atelier | RefCounted | Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json) et installe les améliorations de la cloche, niveau par niveau. |
| `scripts/atelier_ui.gd` | PanneauAtelier | CanvasLayer | Interface de l'atelier (640x360) : panneau opaque en cadres or et crème. |
| `scripts/autoload/game.gd` | Game | Node | Autoload « Game » : point central du jeu. |
| `scripts/autoload/son.gd` | Son | Node | Autoload « Son » : ambiances et effets sonores, tous synthétisés en code au démarrage (Synthe). |
| `scripts/bell.gd` | Cloche | CharacterBody2D | La cloche de plongée : déplacement avec inertie et flottabilité douce. |
| `scripts/dive.gd` | Dive | Node2D | Plongée : décor par zones, câble, oxygène, minage, sac et règles de remontée. |
| `scripts/donnees.gd` | Donnees | RefCounted | Lecture des fichiers de données du dossier data/. |
| `scripts/ecran_titre.gd` | EcranTitre | MenuCadre | Écran titre, en haut de l'écran pour laisser voir l'île figée : Continuer (grisé sans sauvegarde), Nouvelle partie (confirmation si une partie existe déjà), Quitter. |
| `scripts/gisement.gd` | Gisement | Node2D | Un gisement de minerai : un petit sprite de cristaux, un stock limité et une jauge de minage. |
| `scripts/hud.gd` | Interface | CanvasLayer | Interface de plongée (640x360) : oxygène, profondeur, zone, sac, annonces et messages. |
| `scripts/hud_ile.gd` | InterfaceIle | CanvasLayer | Interface de l'île (640x360) : bouton d'inventaire, barre des ressources, annonces et aide. |
| `scripts/ile.gd` | Ile | Node2D | L'île flottante : récolte à la souris (vent, nuages, cristaux solaires), inventaire, atelier (cabane : clic ou C) et départ en plongée en cliquant sur la cloche (ou E / Espace). |
| `scripts/inventaire.gd` | Inventaire | RefCounted | Inventaire unique : ressources du ciel et minerais de plongée. |
| `scripts/inventaire_ui.gd` | PanneauInventaire | CanvasLayer | Panneau d'inventaire opaque (cadre or et crème, pas de voile) : une case par ressource. |
| `scripts/jeu.gd` | Jeu | Node2D | Scène principale : enchaîne l'île, la transition et la plongée. |
| `scripts/menu_cadre.gd` | MenuCadre | CanvasLayer | Base des menus plein écran (écran titre, pause) : un panneau en cadre or et crème, centré ou en haut, avec une colonne de textes et de boutons. |
| `scripts/menu_pause.gd` | MenuPause | MenuCadre | Menu pause (Échap sur l'île ou en plongée) : le jeu est figé tant qu'il est ouvert. |
| `scripts/palette.gd` | Palette | RefCounted | Palette fixe du jeu (data/palette.json) : toutes les couleurs affichées en viennent. |
| `scripts/pixel.gd` | Pixel | RefCounted | Outils de dessin « pixel art » : tout est dessiné au pixel entier, sans antialiasing. |
| `scripts/sac.gd` | Sac | RefCounted | Le sac de la cloche : une unité de minerai = un emplacement. |
| `scripts/sauvegarde.gd` | Sauvegarde | RefCounted | Sauvegarde locale de la partie : un fichier JSON dans user:// (dossier « Le Fil de l'Abysse », voir project.godot : %APPDATA%\Le Fil de l'Abysse sous Windows). |
| `scripts/source_ressource.gd` | SourceRessource | Node2D | Une source de ressource sur l'île : éolienne, filon de cristal, nuage, bassin de lumière (îlot) ou machine construite sur un emplacement (moulin à vent, filet à nuages, entrepôt)… |
| `scripts/synthe.gd` | Synthe | RefCounted | Sons du jeu, synthétisés en code au démarrage (aucun fichier audio) : chaque son est calculé une fois en échantillons, puis rangé dans un AudioStreamWAV (mono, 16 bits). |
| `scripts/transition.gd` | Transition | Node2D | Transition entre l'île et la plongée : la cloche descend du ciel jusqu'à l'océan (ou remonte), la caméra la suit à travers 3 calques de nuages en parallaxe. |
| `scripts/vue_monde.gd` | VueMonde | Node2D | Rendu du monde en 320x180, affiché ×2 sous l'interface (qui reste en 640x360). |
| `tests/captures.gd` | Captures | SceneTree | Joue deux scénarios automatiques et enregistre les captures PNG dans docs/captures/ : 00 : la palette ; 01-05 : la plongée seule (dive.tscn) ; 06-13 : le jeu complet (île, transit… |
| `tests/playtest.gd` | Playtest | SceneTree | Playtest robot : joue une partie entière comme un joueur, avec de vrais évènements clavier et souris (Input.parse_input_event), sans téléporter la cloche ni toucher à l'inventaire. |
| `tests/run_tests.gd` | RunTests | SceneTree | Tests de logique (étapes 1 à 5). |

## Autoloads

- **Game** : `scripts/autoload/game.gd`
- **Son** : `scripts/autoload/son.gd`

## Scènes

- `scenes/dive.tscn` : racine `scripts/dive.gd` ; contient `scripts/bell.gd`, `scripts/hud.gd`
- `scenes/ile.tscn` : racine `scripts/ile.gd` ; contient `scripts/atelier_ui.gd`, `scripts/hud_ile.gd`, `scripts/inventaire_ui.gd`
- `scenes/jeu.tscn` : racine `scripts/jeu.gd` ; contient `scenes/ile.tscn`, `scenes/transition.tscn`, `scripts/ecran_titre.gd`, `scripts/menu_pause.gd`
- `scenes/transition.tscn` : racine `scripts/transition.gd`

## Autoloads

### `scripts/autoload/game.gd` : Game

Autoload « Game » : point central du jeu. Déclare toutes les actions d'entrée en code, avec des touches PHYSIQUES (physical_keycode) : la touche A du clavier QWERTY correspond au Q de l'AZERTY, donc ZQSD fonctionne tel quel en AZERTY. Garde aussi l'inventaire, la liste des ressources (data/ressources.json) et l'atelier (composants fabriqués, niveaux des améliorations de la cloche).

- **Hérite de** : Node
- **Fonctions principales** :
  - `ids(categorie)` : Identifiants d'une catégorie (« ressource » ou « composant »), dans l'ordre d'affichage.
  - `nom_ressource(id)`
  - `couleur_ressource(id)`
- **Dépend de** : ArtAbysse, ArtIle, Atelier, Donnees, Inventaire, Palette, Pixel
- **Utilisé par** : Dive, Ile, InterfaceIle, Jeu, PanneauAtelier, PanneauInventaire

### `scripts/autoload/son.gd` : Son

Autoload « Son » : ambiances et effets sonores, tous synthétisés en code au démarrage (Synthe).

- **Hérite de** : Node
- **Fonctions principales** :
  - `arreter()` : Coupe tous les sons (avant de quitter : le serveur audio relâche les lectures arrêtées au mixage suivant, il faut donc arrêter quelques images avant la fermeture pour ne rien laisser derrière).
  - `jouer(id, hauteur)` : Joue un effet (ignoré s'il vient d'être joué : voir REGLAGES_EFFETS) ; hauteur : 1 = normale. Renvoie vrai si l'effet a été lancé.
  - `a_joue(id)`
  - `vider_historique()`
  - `ambiance(id, duree)` : Passe à l'ambiance « id » par un fondu enchaîné de « duree » secondes (rien si elle joue déjà).
  - `lecteur_ambiance()` : Lecteur d'ambiance au premier plan (tests).
  - `regler_volumes(musique, effets)`
  - `appliquer_volumes()`
  - `reglages()` : Réglages enregistrés dans la sauvegarde.
  - `charger_reglages(donnees)` : Reprend des réglages sauvegardés ; une valeur absente ou fausse garde la valeur par défaut.
- **Dépend de** : Synthe
- **Utilisé par** : Dive, Ile, Jeu, MenuPause

## Scripts du jeu

### `scripts/art_abysse.gd` : ArtAbysse

Pixel art de l'abysse (plongée), dessiné dans le monde 320x180 (voir VueMonde). Repère : pixels du monde de la plongée, x = 0 au centre, y = 0 à la surface de la mer. L'eau, les reflets, les particules et la surface sont des fonctions du lieu et d'une horloge commune (images de physique) : la transition peut redessiner exactement la même image. Contour bleu nuit (« contour_bas »), ombres portées d'un ton plus sombre que l'eau derrière.

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `c(nom)`
  - `temps()`
  - `couleur_eau(profondeur)` : Couleur de l'eau à une profondeur (px du monde sous la surface), paliers des zones (data/zones.json).
  - `couleur_fond(point)` : Couleur de ce qu'il y a derrière un point de la plongée (ciel au-dessus de la surface, eau dessous).
  - `contour_cloche(y_plongee)` : Contour de la cloche : brun au-dessus de la surface (monde du haut), bleu nuit dessous.
  - `dessiner_eau(toile, zone, profondeur_max, avec_ciel)` : Dessine le décor de la plongée visible dans « zone » (pixels du monde de la plongée) : ciel au-dessus de la surface, surface animée, eau en paliers à bords en vagues, reflets, particules.
  - `dessiner_reperes(toile, zone, profondeur_max)` : Repères de profondeur tous les 10 m sur les bords.
  - `niveau_obscurite(profondeur_m, obscurite_max)` : Nombre de tons d'obscurité à une profondeur, sans halo (0 à 3, limité par la lanterne).
  - `crans_halo(distance, rayon)` : Tons retirés par le halo à une distance de la cloche (pixels du monde) : 0 au centre, puis 1, 2, 3.
  - `assombrir(teinte, profondeur_m, distance, rayon, obscurite_max)` : Couleur affichée d'un pixel du monde : son ton, assombri dans sa propre rampe.
  - `materiau_obscurite()` : Matériau d'obscurité de la vue du monde de la plongée (ombre « un ton plus sombre » par pixel). Table : ligne k = chaque couleur de la palette assombrie de k tons dans sa rampe.
  - `gisement(minerai, grise)`
  - `lueur(minerai)` : Couleur de lueur d'un minerai (stock, anneaux) : jamais assombrie par l'obscurité.
  - `cadre()` : Cadre des panneaux de l'abysse : liseré bleu nuit, métal sombre en relief, lueur cyan, fond nuit.
  - `vider_cache()`
- **Dépend de** : ArtIle, Donnees, Palette, Pixel
- **Utilisé par** : ArtIle, Captures, Dive, Game, Gisement, Ile, Interface, Playtest, RunTests, SourceRessource, Transition

### `scripts/art_ile.gd` : ArtIle

Pixel art du monde du haut (île, ciel, nuages, cloche, interface), généré en code. Tout est paramétré par une échelle k : 1 pour 640x360, 0.5 pour 320x180 (essai comparatif). Les grandes images (fond de l'île) sont peintes une fois dans une Image, puis mises en cache. Règles : couleurs de la palette uniquement, contour brun foncé (« contour_haut »), jamais noir, ombre portée pleine d'un ton plus sombre (Palette.plus_sombre), pas de transparence partielle.

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `vider_cache()`
  - `c(nom)`
  - `couleurs_rampe(nom_rampe, decalage)` : Associe les chiffres d'un motif aux tons d'une rampe (décalage pour éclaircir ou assombrir).
  - `couleur_ciel_monde(y)` : Couleur du ciel à une hauteur de la colonne (sans les créneaux) : sert aux ombres des objets qui volent.
  - `couleur_ciel_pixel(x, y)` : Couleur exacte d'un pixel du ciel (x, y en pixels du monde de la colonne), créneaux compris.
  - `dessiner_ciel(toile, zone, dx, dy)` : Dessine le ciel sur une toile ; un point de la toile (x, y) est le pixel (x + dx, y + dy) de la colonne.
  - `fond_ile(k)`
  - `peindre_ciel(image)`
  - `peindre_soleil(image, centre, rayon)`
  - `peindre_ile(image, k)` : L'île : herbe en touffes, couche de terre, roche en pavés avec cristaux incrustés, contour brun, ombre portée d'un ton plus sombre sur le ciel, treuil dessous.
  - `nuage(largeur, hauteur)` : Nuage en volume : lumière chaude en haut à gauche, ombre bleutée en bas, contour bleu-gris.
  - `pales(k, angle)` : Pales de l'éolienne (voiles crème bordées de brun), pour un angle donné (12 images par tiers de tour).
  - `cloche(k, contour)`
  - `filon(k, plein)`
  - `cabane(allumee)` : Cabane de l'atelier (monde 320x180) ; fenêtre allumée quand une fabrication est possible.
  - `ilot(relie)`
  - `icone_construction(id)` : Icône d'une construction (atelier).
  - `icone_machine(id)` : Icône d'une machine de l'île (atelier, onglet Machines).
  - `icone_amelioration(id)` : Icône d'une amélioration de la cloche (atelier).
  - `icone(id, k)` : Icône d'une ressource (inventaire, barre de ressources).
  - … et 4 autres
- **Dépend de** : ArtAbysse, Palette, Pixel
- **Utilisé par** : ArtAbysse, Dive, Game, Ile, Interface, InterfaceIle, MenuCadre, PanneauAtelier, PanneauInventaire, SourceRessource, Transition

### `scripts/atelier.gd` : Atelier

Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json) et installe les améliorations de la cloche, niveau par niveau. Les effets des niveaux (longueur du câble, halo, oxygène) sont dans data/ameliorations.json. Les niveaux installés sont gardés ici et enregistrés dans la sauvegarde (voir charger_niveaux). Construit aussi les passerelles qui relient les îlots à l'île (une construction = un îlot relié) et les machines de l'île (data/machines.json), chacune sur un emplacement libre (la foreuse sur un filon). Les machines sont rangées par paliers : le palier 2 s'ouvre au premier corail rapporté, le palier 3 à la première pierre de braise (voir decouvrir). À partir du palier 2, chaque sorte de machine s'améliore : vitesse (production plus rapide) et capacité (réserve plus grande).

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `composants()`
  - `ingredients_composant(id)`
  - `peut_fabriquer(id)`
  - `fabriquer(id)`
  - `nom_amelioration(id)`
  - `niveau(id)`
  - `niveau_max(id)`
  - `est_au_maximum(id)`
  - `prochain_niveau(id)` : Recette du prochain niveau (vide si l'amélioration est au maximum).
  - `recette_niveau(id, cible)` : Recette d'un niveau donné (1 = premier niveau), vide s'il n'existe pas.
  - `peut_ameliorer(id)`
  - `ameliorer(id)`
  - `charger_niveaux(donnees)` : Niveaux lus depuis une sauvegarde : améliorations inconnues ignorées, niveaux bornés à 0..max.
  - `nom_construction(id)`
  - `ingredients_construction(id)`
  - `effet_construction(id)`
  - `annonce_construction(id)` : Message affiché sur l'île une fois la construction faite.
  - `ilot_de(id)` : Îlot relié par cette construction.
  - `est_construite(id)`
  - `est_relie(ilot)`
  - … et 35 autres
- **Dépend de** : Donnees, Inventaire
- **Utilisé par** : Captures, Dive, Game, Ile, Jeu, PanneauAtelier, Playtest, RunTests

### `scripts/atelier_ui.gd` : PanneauAtelier

Interface de l'atelier (640x360) : panneau opaque en cadres or et crème. En haut, quatre onglets (composants, améliorations, construction, machines) ; à gauche, la liste des recettes ; à droite, le détail de la recette choisie : ingrédients « possédé / requis », effet, bouton Fabriquer, Installer ou Construire. Onglet Machines : la machine est construite sur l'emplacement cliqué sur l'île (emplacement_cible), ou à défaut sur le premier emplacement libre. À partir du palier 2, trois boutons en haut du détail choisissent entre Construire et les améliorations de cette sorte de machine (Vitesse, Réserve). S'ouvre et se ferme avec C ou un clic sur la cabane ; Échap ou un clic à côté le ferme.

- **Hérite de** : CanvasLayer
- **Signaux** : `fabrique(id: String, genre: String)`
- **Fonctions principales** :
  - `est_ouvert()`
  - `ouvrir()`
  - `ouvrir_machines(emplacement)` : Ouvre l'onglet Machines pour construire sur cet emplacement (clic sur un emplacement libre).
  - `fermer()`
  - `basculer()`
  - `choisir_onglet(nom)`
  - `selectionner(id)`
  - `choisir_mode(nom)` : Onglet Machines : construire, ou améliorer la vitesse ou la réserve de cette sorte de machine.
  - `fabriquer_selection()` : Fabrique, installe ou construit la recette sélectionnée, si c'est possible.
  - `peut_fabriquer_selection()`
  - `rafraichir()`
- **Dépend de** : ArtIle, Atelier, Game, Inventaire, Pixel
- **Utilisé par** : Ile

### `scripts/bell.gd` : Cloche

La cloche de plongée : déplacement avec inertie et flottabilité douce. Les ordres viennent de dive.gd (contrôle actif ou remontée automatique).

- **Hérite de** : CharacterBody2D
- **Fonctions principales** :
  - `dessiner(toile, centre)` : Dessin de la cloche, réutilisé par l'île et la transition.
- **Dépend de** : Pixel
- **Utilisé par** : Dive, RunTests

### `scripts/dive.gd` : Dive

Plongée : décor par zones, câble, oxygène, minage, sac et règles de remontée. Pas de game over : à 0 d'oxygène, la cloche remonte toute seule et une partie du butin est perdue. Quand la cloche revient en surface après être descendue sous PROFONDEUR_ARMEMENT_M, la plongée est terminée : on émet retour_ile et la scène Jeu lance la remontée vers l'île. Rendu : le monde est dessiné en 320x180 (VueMonde, ArtAbysse) ; la logique reste en 640x360.

- **Hérite de** : Node2D
- **Signaux** : `retour_ile(gardees: Dictionary, perdues: Dictionary, urgence: bool)`
- **Fonctions principales** :
  - `appliquer_ameliorations()` : Lit les niveaux installés à l'atelier : longueur du câble, réserve d'oxygène, lanterne.
  - `au_bout_du_cable()` : Vrai quand le câble est tendu au maximum (la cloche ne peut pas descendre plus bas).
  - `rafraichir_interface()` : Met à jour l'interface (aussi appelé pendant la descente, quand la plongée est encore figée).
  - `dessiner_monde(toile, vue, avec_ciel, avec_cloche)` : Décor, gisements, câble et cloche dans « vue » (pixels du monde de la plongée). La transition l'appelle aussi (sans ciel ni cloche) pour que la surface raccorde sans coupure.
  - `cloche_position()` : Position de la cloche et haut de la vue (640x360), pour une remontée qui part de cette image.
  - `haut_camera()`
- **Dépend de** : ArtAbysse, ArtIle, Atelier, Cloche, Donnees, Game, Gisement, Interface, Palette, Pixel, Sac, Son, VueMonde
- **Utilisé par** : Captures, Jeu, RunTests

### `scripts/donnees.gd` : Donnees

Lecture des fichiers de données du dossier data/.

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `charger_json(chemin)`
- **Dépend de** : aucun script
- **Utilisé par** : ArtAbysse, Atelier, Dive, Game, Ile, Palette, Playtest, RunTests

### `scripts/ecran_titre.gd` : EcranTitre

Écran titre, en haut de l'écran pour laisser voir l'île figée : Continuer (grisé sans sauvegarde), Nouvelle partie (confirmation si une partie existe déjà), Quitter. Un message discret signale une sauvegarde abîmée, reprise ou d'une version plus récente.

- **Hérite de** : MenuCadre
- **Signaux** : `continuer`, `nouvelle_partie`, `quitter`
- **Fonctions principales** :
  - `ouvrir(peut_continuer, partie_existante, message)` : peut_continuer : une sauvegarde utilisable existe ; partie_existante : Nouvelle partie demande confirmation ; message : vide si tout va bien.
  - `demander_nouvelle_partie()`
  - `annuler_confirmation()`
  - `confirmation_ouverte()`
  - `message()`
- **Dépend de** : MenuCadre
- **Utilisé par** : Jeu

### `scripts/gisement.gd` : Gisement

Un gisement de minerai : un petit sprite de cristaux, un stock limité et une jauge de minage. Il ne se dessine pas lui-même : la plongée appelle dessiner_monde() dans le monde 320x180.

- **Hérite de** : Node2D
- **Fonctions principales** :
  - `configurer(id_minerai, teinte, duree, stock_initial)`
  - `retirer_unite()` : Retire une unité ; le gisement disparaît quand il est épuisé.
  - `dessiner_monde(toile)` : Dessin dans le monde 320x180 (appelé par la plongée) : sprite avec contour bleu nuit et ombre d'un ton plus sombre que l'eau, stock en points, anneau et jauge en lueur cyan.
- **Dépend de** : ArtAbysse, Palette, Pixel, VueMonde
- **Utilisé par** : Dive, RunTests

### `scripts/hud.gd` : Interface

Interface de plongée (640x360) : oxygène, profondeur, zone, sac, annonces et messages. Cadres en métal sombre avec une lueur cyan (ArtAbysse.cadre), texte cyan clair. glisser() fait entrer ou sortir les panneaux par les bords de l'écran (transitions), au pixel près.

- **Hérite de** : CanvasLayer
- **Fonctions principales** :
  - `mettre_a_jour(ratio_oxygene, profondeur_m, nom_zone, message_bas)`
  - `glisser(progression)` : progression : 0 = panneaux hors de l'écran, 1 = en place. Chacun sort par son bord le plus proche : l'état par la gauche, l'annonce par le haut, le message par le bas. Pas de transparence.
  - `progression_glissement()`
  - `decalage_panneau_etat()` : Décalage du panneau par rapport à sa place (pixels d'écran).
  - `regler_reserve(facteur)` : Longueur de la jauge d'oxygène proportionnelle à la réserve (1 = réserve de base).
  - `largeur_jauge()`
  - `definir_sac(texte)`
  - `annoncer(texte, duree)`
- **Dépend de** : ArtAbysse, ArtIle, Palette, Pixel
- **Utilisé par** : Dive, Jeu

### `scripts/hud_ile.gd` : InterfaceIle

Interface de l'île (640x360) : bouton d'inventaire, barre des ressources, annonces et aide. Cadres épais or et crème (ArtIle.cadre), texte brun foncé en DotGothic16.

- **Hérite de** : CanvasLayer
- **Fonctions principales** :
  - `rafraichir_inventaire()`
  - `annoncer(texte, duree)`
  - `texte_annonce()`
  - `definir_aide(texte)`
- **Dépend de** : ArtIle, Game, Inventaire, Pixel
- **Utilisé par** : Ile

### `scripts/ile.gd` : Ile

L'île flottante : récolte à la souris (vent, nuages, cristaux solaires), inventaire, atelier (cabane : clic ou C) et départ en plongée en cliquant sur la cloche (ou E / Espace). Deux îlots isolés (data/ile.json) : à droite, l'îlot de l'est, relié par la passerelle de nuage (son bassin de lumière donne alors du cristal de lagon, maintien du clic comme les filons) ; en haut à gauche, l'îlot du nord, relié par le pont suspendu (deux emplacements de machine). Un clic sur un îlot isolé ouvre l'atelier, onglet Construction. Machines (data/machines.json) : un clic sur un emplacement libre ouvre l'atelier, onglet Machines ; une machine construite produit seule jusqu'à sa réserve et un clic vide la réserve (comme l'éolienne). La foreuse solaire se pose sur un filon, qui ne se récolte plus à la main ; l'entrepôt ne produit rien (il relève le plafond de l'inventaire). Le premier corail rapporté ouvre le palier 2. Les sources se rechargent avec le temps, y compris pendant la plongée (voir rattraper()). Échap ferme un panneau ouvert ; sinon il remonte à la scène principale (menu pause). Rendu : le monde est dessiné en 320x180 (VueMonde, affiché ×2) ; la logique reste en 640x360.

- **Hérite de** : Node2D
- **Signaux** : `plongee_demandee`, `partie_modifiee`
- **Fonctions principales** :
  - `panneau_ouvert()` : Un seul panneau ouvert à la fois (inventaire ou atelier).
  - `actualiser_machines()` : Crée les machines construites à l'atelier (et retire celles qui n'y sont plus : nouvelle partie), applique leurs améliorations, et retire de l'île les filons couverts par une foreuse.
  - `machine(lieu)` : Machine posée sur un emplacement (null s'il est libre).
  - `centre_emplacement(lieu)` : Centre de la zone cliquable d'un emplacement (640x360), au-dessus du sol.
  - `ilot_relie(id)`
  - `actualiser_ilot()` : Le bassin n'existe sur l'île (récolte, recharge, dessin) que si l'îlot de l'est est relié.
  - `bassin()`
  - `centre_ilot(id)` : Centre de la zone de survol d'un îlot (640x360).
  - `preparer_depart()` : Appelé au lancement de la descente : l'île se fige et la cloche part avec la transition.
  - `reprendre()` : L'île redevient active (fin de remontée, ou retour à l'écran titre depuis une plongée).
  - `afficher_interface(afficher)` : Interface de l'île cachée sous l'écran titre (le décor reste visible).
  - `arriver(temps_plongee, gardees, perdues, urgence)` : Appelé à la fin de la remontée : rattrape la recharge, range le butin, annonce le résultat.
  - `rattraper(secondes)` : Fait avancer la recharge des sources comme si « secondes » s'étaient écoulées sur l'île.
  - `etat_sources()` : État des sources fixes (les nuages ne sont pas sauvegardés : ils réapparaissent seuls).
  - `restaurer_sources(donnees)` : Reprend l'état sauvegardé des sources ; ce qui manque ou est faux garde la valeur de départ.
  - `reinitialiser_sources()` : Sources remises à leur stock de départ (nouvelle partie).
- **Dépend de** : ArtAbysse, ArtIle, Atelier, Donnees, Game, InterfaceIle, Inventaire, Palette, PanneauAtelier, PanneauInventaire, Pixel, Son, SourceRessource, VueMonde
- **Utilisé par** : Jeu, Playtest, RunTests, Transition

### `scripts/inventaire.gd` : Inventaire

Inventaire unique : ressources du ciel et minerais de plongée. Le plafond par ressource est de 99 ; un entrepôt (machine du palier 2) le porte à 199.

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `quantite(id)`
  - `place(id)` : Place restante avant le plafond pour cette ressource.
  - `ajouter(id, nombre)` : Ajoute dans la limite du plafond ; renvoie la quantité réellement ajoutée.
  - `ajouter_tout(butin)` : Ajoute un butin { id: nombre } ; renvoie ce qui n'a pas pu entrer.
  - `borner()` : Ramène chaque quantité sous le plafond (chargement d'une partie sans entrepôt).
  - `retirer(id, nombre)`
  - `total()`
  - `vers_dictionnaire()` : Quantités non nulles { id: nombre }.
  - `depuis_dictionnaire(donnees, ids_connus)` : Inventaire lu depuis une sauvegarde : identifiants inconnus ignorés, quantités bornées à 0..PLAFOND_MAX (l'entrepôt, chargé ensuite avec les machines, fixe le vrai plafond).
- **Dépend de** : aucun script
- **Utilisé par** : Atelier, Captures, Game, Ile, InterfaceIle, Jeu, PanneauAtelier, PanneauInventaire, Playtest, RunTests

### `scripts/inventaire_ui.gd` : PanneauInventaire

Panneau d'inventaire opaque (cadre or et crème, pas de voile) : une case par ressource. S'ouvre et se ferme avec I / Tab ou le bouton ; Échap ou un clic à côté le ferme.

- **Hérite de** : CanvasLayer
- **Fonctions principales** :
  - `est_ouvert()`
  - `ouvrir()`
  - `fermer()`
  - `basculer()`
  - `rafraichir()`
- **Dépend de** : ArtIle, Game, Inventaire, Pixel
- **Utilisé par** : Ile

### `scripts/jeu.gd` : Jeu

Scène principale : enchaîne l'île, la transition et la plongée. L'île reste en mémoire pendant la plongée (figée et cachée) ; à son retour, elle rattrape la recharge correspondant au temps passé sous l'eau. La plongée est créée dès le début de la descente (figée et cachée) et gardée jusqu'à la fin de la remontée : la transition dessine son décor sous la surface, ce qui évite toute coupure.

- **Hérite de** : Node2D
- **Fonctions principales** :
  - `plongee()`
  - `montrer_titre()` : Affiche l'écran titre au-dessus de l'île figée, d'après la sauvegarde trouvée.
  - `continuer()` : Reprend la partie sauvegardée ; l'île rattrape le temps passé jeu fermé (plafonné par les sources).
  - `nouvelle_partie()`
  - `donnees_partie()` : Données de la partie à sauvegarder.
  - `sauvegarder()` : Sauvegarde sur l'île seulement : en plongée, la sauvegarde du départ fait foi.
  - `peut_mettre_en_pause()`
  - `ouvrir_pause()`
  - `fermer_pause()`
  - `retour_au_titre()`
  - `quitter()`
- **Dépend de** : Atelier, Dive, EcranTitre, Game, Ile, Interface, Inventaire, MenuCadre, MenuPause, Sauvegarde, Son, Transition
- **Utilisé par** : Captures, Playtest, RunTests

### `scripts/menu_cadre.gd` : MenuCadre

Base des menus plein écran (écran titre, pause) : un panneau en cadre or et crème, centré ou en haut, avec une colonne de textes et de boutons. Les menus restent actifs quand le jeu est en pause.

- **Hérite de** : CanvasLayer
- **Fonctions principales** :
  - `est_ouvert()`
  - `fermer()`
- **Dépend de** : ArtIle, Pixel
- **Utilisé par** : EcranTitre, Jeu, MenuPause

### `scripts/menu_pause.gd` : MenuPause

Menu pause (Échap sur l'île ou en plongée) : le jeu est figé tant qu'il est ouvert. Reprendre (ou Échap), Retour au titre et Quitter sauvegardent sur l'île ; en plongée, le butin en cours est abandonné (la sauvegarde du départ fait foi), ce que le menu rappelle. Deux réglages de volume (musique, effets), par pas de 10 %, appliqués tout de suite ; ils sont enregistrés avec la partie (signal volumes_modifies).

- **Hérite de** : MenuCadre
- **Signaux** : `reprendre`, `retour_titre`, `quitter`, `volumes_modifies`
- **Fonctions principales** :
  - `ouvrir(en_plongee)` : en_plongee : rappelle que quitter la plongée abandonne son butin.
  - `note()`
  - `changer_volume(canal, sens)` : Monte ou baisse un volume d'un pas (« musique » ou « effets »).
- **Dépend de** : MenuCadre, Palette, Son
- **Utilisé par** : Jeu

### `scripts/palette.gd` : Palette

Palette fixe du jeu (data/palette.json) : toutes les couleurs affichées en viennent. Elle est organisée en rampes, une par matière (ciel, nuage, roche, herbe, or…), du plus sombre au plus clair : les ombres tirent vers le bleu-vert, les lumières vers le jaune. Une couleur se nomme « rampe.indice » (ex. « herbe.4 ») ou par un alias (ex. « contour_haut »).

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `couleur(nom)`
  - `rampe(nom)` : Tons d'une rampe, du plus sombre au plus clair.
  - `noms()` : Noms de toutes les couleurs (une par entrée de rampe, sans les alias).
  - `contient(nom)`
  - `plus_sombre(teinte, crans)` : Le ton juste en dessous dans la même rampe (ombre portée « un ton plus sombre »).
  - `plus_clair(teinte, crans)` : Le ton juste au-dessus dans la même rampe (reflets, repères).
- **Dépend de** : Donnees
- **Utilisé par** : ArtAbysse, ArtIle, Captures, Dive, Game, Gisement, Ile, Interface, MenuPause, Pixel, RunTests, SourceRessource, Transition

### `scripts/pixel.gd` : Pixel

Outils de dessin « pixel art » : tout est dessiné au pixel entier, sans antialiasing. Les petites formes (cloche, cristaux, nuages, cercles, jauges, trames) sont des textures générées en code (Image) à la taille native, mises en cache, affichées sans filtrage. Les nœuds qui dessinent des trames doivent avoir texture_repeat activé (voir activer_motifs).

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `vider_cache()`
  - `activer_motifs(noeud)` : À appeler dans _ready des nœuds qui dessinent des trames ou des motifs répétés.
  - `rect(toile, zone, couleur)`
  - `cadre(toile, zone, couleur)` : Cadre de 1 px à l'intérieur de la zone.
  - `ligne(toile, debut, fin, couleur)` : Ligne de 1 px (algorithme de Bresenham).
  - `sprite(toile, texture, centre)` : Dessine une texture centrée, coin haut-gauche arrondi au pixel.
  - `bandes(toile, x, largeur, y_haut, y_bas, decalage, palier)` : Dégradé vertical en paliers nets. Chaque changement de palier passe par trois bandes tramées (Bayer 25 %, 50 %, 75 %) au lieu d'un fondu lisse. palier : Callable(y_monde: float) -> Color ; decalage : y_monde = y_ecran + decalage (entier).
  - `texte(etiquette, couleur, ombre)` : Style commun des textes : police pixel (thème du projet), couleur et ombre portée de 1 px.
  - `motif(lignes, couleurs, contour)` : Texture à partir d'un dessin en caractères : chaque caractère renvoie à un nom de la palette, « . » est transparent. contour : nom d'une couleur pour un contour de 1 px tout autour (l'image grandit alors de 2 px), vide pour aucun.
  - `contourner(image, couleur)` : Ajoute un contour de 1 px (voisins haut, bas, gauche, droite) autour des pixels opaques.
  - `silhouette(texture, couleur)` : Silhouette pleine d'une texture (pour les ombres portées d'un ton plus sombre).
  - `sprite_ombre(toile, texture, centre, ombre, decalage)` : Sprite avec ombre portée : la silhouette d'abord, décalée, puis le sprite.
  - `disque(rayon, couleur)`
  - `anneau(rayon, couleur, pointille)` : Anneau de 1 px ; pointille : un pixel sur deux (effet de halo tramé).
  - `jauge(rayon, progression, couleur)` : Jauge circulaire de 2 px d'épaisseur, remplie dans le sens horaire depuis le haut (24 crans).
  - `damier(a, b)` : Damier 2x2 de deux couleurs (trame à 50 %).
  - `trame(niveau, couleur)` : Trame ordonnée (Bayer 4x4) : niveau 0 = transparent, 16 = plein.
  - `nuage(largeur, hauteur, couleur, ombre)` : Nuage arrondi (trois bosses), ombré en bas.
- **Dépend de** : Palette
- **Utilisé par** : ArtAbysse, ArtIle, Captures, Cloche, Dive, Game, Gisement, Ile, Interface, InterfaceIle, MenuCadre, PanneauAtelier, PanneauInventaire, RunTests, SourceRessource, Transition, VueMonde

### `scripts/sac.gd` : Sac

Le sac de la cloche : une unité de minerai = un emplacement. 8 places au départ ; l'amélioration « Sac de plongée » en donne 12.

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `nombre()`
  - `est_plein()`
  - `ajouter(minerai)`
  - `compter()` : Nombre d'unités par minerai : { "cristal": 3, "corail": 1 }
  - `vider()` : Vide le sac et renvoie son contenu.
  - `perdre(fraction, hasard)` : Perd une fraction des unités, tirées au hasard (arrondi à l'inférieur). Renvoie ce qui a été perdu.
- **Dépend de** : aucun script
- **Utilisé par** : Captures, Dive, RunTests

### `scripts/sauvegarde.gd` : Sauvegarde

Sauvegarde locale de la partie : un fichier JSON dans user:// (dossier « Le Fil de l'Abysse », voir project.godot : %APPDATA%\Le Fil de l'Abysse sous Windows).

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `chemin_secours()`
  - `chemin_temporaire()`
  - `chemin_corrompue()`
  - `existe()`
  - `ecrire(partie, horodatage)` : Écrit la partie { inventaire, ameliorations, ilots, ile } ; renvoie faux en cas d'échec.
  - `lire()` : Lit la sauvegarde : { "statut": Statut, "partie": Dictionary (vide si rien d'utilisable), "message": texte à afficher à l'écran titre (vide si tout va bien) }.
  - `mettre_de_cote_version_recente()` : Met de côté une sauvegarde d'une version plus récente avant une nouvelle partie (jamais écrasée).
  - `migrer(donnees)` : Met à jour les données d'une version plus ancienne vers VERSION, étape par étape. Version 0 : premier format, sans numéro de version, sans îlots ni état de l'île.
  - `secondes_depuis(partie, maintenant)` : Secondes écoulées depuis la sauvegarde (jamais négatif, même si l'horloge a reculé).
- **Dépend de** : aucun script
- **Utilisé par** : Captures, Jeu, Playtest, RunTests

### `scripts/source_ressource.gd` : SourceRessource

Une source de ressource sur l'île : éolienne, filon de cristal, nuage, bassin de lumière (îlot) ou machine construite sur un emplacement (moulin à vent, filet à nuages, entrepôt) ou sur un filon (foreuse solaire). Trois façons de récolter : - CLIC : un clic = une prise (nuages : « rendement » ouates par prise) ; - MAINTIEN : maintenir le clic remplit une jauge, une unité par cycle (filons, bassin) ; - RESERVE : la source accumule seule, un clic vide toute la réserve (éolienne, machines). Le stock se recharge avec le temps jusqu'au plafond (recharge_s secondes par unité).

- **Hérite de** : Node2D
- **Fonctions principales** :
  - `recharger(secondes)` : Fait avancer la recharge de « secondes » (aussi utilisé pour rattraper le temps de plongée).
  - `etat()` : État enregistré dans la sauvegarde : stock et recharge en cours.
  - `restaurer(donnees)` : Reprend un état sauvegardé, borné : stock 0..plafond, recharge 0..recharge_s.
  - `est_disponible()`
  - `contient(point)`
  - `prendre(nombre)` : Retire jusqu'à « nombre » unités ; renvoie la quantité réellement prise.
  - `dessiner_monde(toile)`
- **Dépend de** : ArtAbysse, ArtIle, Palette, Pixel, VueMonde
- **Utilisé par** : Ile, Playtest, RunTests

### `scripts/synthe.gd` : Synthe

Sons du jeu, synthétisés en code au démarrage (aucun fichier audio) : chaque son est calculé une fois en échantillons, puis rangé dans un AudioStreamWAV (mono, 16 bits). Les ambiances sont des boucles : toutes leurs fréquences et modulations font un nombre entier de cycles sur la durée de la boucle, et le bruit est rendu circulaire, si bien que la fin raccorde exactement au début. Hasard à graine fixe : les sons sont identiques d'une partie à l'autre.

- **Hérite de** : RefCounted
- **Fonctions principales** :
  - `liberer()` : Libère le générateur de hasard partagé (fermeture du jeu : aucune fuite signalée).
  - `effets()` : Tous les effets : { id: AudioStreamWAV }.
  - `effet(id)`
  - `ambiances()` : Ambiances en boucle : { id: AudioStreamWAV }.
  - `ambiance(id)` : Île : nappe lumineuse (do majeur avec neuvième), vibrato lent et souffle d'air léger. Plongée : drone grave étouffé, de plus en plus sombre (Lagon, Coraux, Faille).
  - `echantillons(flux)` : Échantillons d'un flux (pour les tests) : valeurs entre -1 et 1.
- **Dépend de** : aucun script
- **Utilisé par** : RunTests, Son

### `scripts/transition.gd` : Transition

Transition entre l'île et la plongée : la cloche descend du ciel jusqu'à l'océan (ou remonte), la caméra la suit à travers 3 calques de nuages en parallaxe.

- **Hérite de** : Node2D
- **Signaux** : `terminee`
- **Fonctions principales** :
  - `est_active()`
  - `lancer(descente, ile, plongee, cloche_bas, haut_camera_bas)` : descente : île → océan ; sinon océan → île. plongee : la scène de plongée (dessinée sous la surface) ; cloche_bas : position de sa cloche (640x360) ; haut_camera_bas : haut de sa vue (pour une remontée qui part de la vue exacte).
  - `afficher_image(avancement)` : Fige la transition à un instant donné (0 → 1), pour les captures d'écran.
  - `reprendre()`
  - `temps_restant()` : Temps restant avant la fin (en secondes), y compris quand la transition est passée.
  - `temps_ecoule()` : Temps écoulé depuis le début, à la vitesse normale (un saut l'accélère).
  - `decalage_ecran()` : Décalage d'écran (0 ou 1 px) de la grille du monde dans l'image actuelle.
  - `passer()` : Passe la transition : la fin est jouée en DUREE_SAUT avec un fondu.
- **Dépend de** : ArtAbysse, ArtIle, Ile, Palette, Pixel, VueMonde
- **Utilisé par** : Jeu

### `scripts/vue_monde.gd` : VueMonde

Rendu du monde en 320x180, affiché ×2 sous l'interface (qui reste en 640x360). La logique du jeu garde ses positions en 640x360 : au dessin, on les divise par 2 et on les arrondit au pixel du monde (vers_monde), donc tous les pixels du monde ont la même taille.

- **Hérite de** : Node2D
- **Fonctions principales** :
  - `origine_monde()` : Pixel du monde affiché en haut à gauche.
  - `decalage_ecran()` : Décalage de l'image en pixels d'écran (0 ou 1 sur chaque axe) : les pixels du monde commencent à ce décalage modulo 2 (sert à la vérification des blocs 2x2).
  - `vue_monde()` : Rectangle visible, en pixels du monde (avec la marge).
  - `taille_monde()`
  - `vers_monde(point)` : Position 640x360 -> pixel entier du monde 320x180.
- **Dépend de** : Pixel
- **Utilisé par** : Captures, Dive, Gisement, Ile, RunTests, SourceRessource, Transition

## Tests

### `tests/captures.gd` : Captures

Joue deux scénarios automatiques et enregistre les captures PNG dans docs/captures/ : 00 : la palette ; 01-05 : la plongée seule (dive.tscn) ; 06-13 : le jeu complet (île, transitions, plongée) ; 14-19 : l'atelier et les améliorations de la cloche (câble, lanterne, réservoir) ; 28-29 : la Faille volcanique (pierre de braise, fond de magma, lanterne de niveau 2) ; 20-27 : écran titre, îlot (22-24 : non relié, construction de la passerelle, relié), menu pause, sauvegarde abîmée ; 30-32 : machines du palier 1 (emplacement libre, onglet Machines, moulin et filet). Chaque capture est vérifiée : tous ses pixels doivent être des couleurs de data/palette.json (un antialiasing ou une transparence créerait des couleurs intermédiaires). On vérifie aussi la grille du monde (320x180 affiché ×2) : interface masquée, chaque bloc de 2x2 pixels d'écran doit être d'une seule couleur (aucun pixel du monde plus petit). Les blocs commencent au décalage de la caméra (0 ou 1 pixel d'écran) : la vérification en tient compte. Enfin, on vérifie les raccords : fin de la descente = début de la plongée, fin de la plongée = début de la remontée, au pixel près (horloge des particules figée pendant la comparaison). Nécessite un affichage (Xvfb + Mesa logiciel) : voir tests/captures.sh.

- **Hérite de** : SceneTree
- **Fonctions** : `_initialize`, `_scenarios`, `_planche_palette`, `_scenario_plongee`, `_scenario_jeu`, `_scenario_ameliorations`, `_scenario_ilot`, `_scenario_machines`, `_scenario_menus`, `_ouvrir_jeu_titre`, `_fermer_jeu`, `_effacer_sauvegarde`, `_atelier`, `_nouvelle_plongee`, `_fermer_plongee`, `_verifier_obscurite`, `_images`, `_gisement_proche`, `_placer_pres_de`, `_vers_fenetre`
- **Dépend de** : ArtAbysse, Atelier, Dive, Inventaire, Jeu, Palette, Pixel, Sac, Sauvegarde, VueMonde

### `tests/playtest.gd` : Playtest

Playtest robot : joue une partie entière comme un joueur, avec de vrais évènements clavier et souris (Input.parse_input_event), sans téléporter la cloche ni toucher à l'inventaire.

- **Hérite de** : SceneTree
- **Fonctions** : `_initialize`, `_lancer`, `_partie_complete`, `_besoins`, `_objectifs_restants`, `_ingredients_objectif`, `_plongee_utile`, `_zone_de`, `_atteignable`, `_recolter_utile`, `_nuage_visible`, `_cliquer_nuage`, `_maintenir_sur`, `_recolter_bassin`, `_fabriquer_tout`, `_prochaine_fabrication`, `_prend_a_l_objectif`, `_plonger`, `_conduire`, `_regarder`
- **Dépend de** : ArtAbysse, Atelier, Donnees, Ile, Inventaire, Jeu, Sauvegarde, SourceRessource

### `tests/run_tests.gd` : RunTests

Tests de logique (étapes 1 à 5). Lancement : voir tests/lancer.sh ou le README. Chaque vérification affiche PASS ou FAIL, puis un total ; code de sortie 1 s'il y a un échec.

- **Hérite de** : SceneTree
- **Fonctions** : `_initialize`, `_lancer`, `_titre`, `_verifier`, `_images`, `_secondes`, `_demarrer`, `_terminer`, `_somme`, `_vers_fenetre`, `_souris`, `_bouton`, `_cliquer`, `_touche`, `_gisements`, `_test_inertie`, `_test_flottabilite`, `_test_bornes`, `_test_oxygene_baisse_et_recharge`, `_test_remontee_automatique`
- **Dépend de** : ArtAbysse, Atelier, Cloche, Dive, Donnees, Gisement, Ile, Inventaire, Jeu, Palette, Pixel, Sac, Sauvegarde, SourceRessource, Synthe, VueMonde
