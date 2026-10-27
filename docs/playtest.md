# Playtest automatique : boucle complète du MVP

Date : 27 octobre 2026, branche `etape-6-playtest`.

## Méthode

`tests/playtest.gd` joue une partie entière avec de vrais évènements clavier et souris
(`Input.parse_input_event`), sans téléportation ni modification de l'inventaire :

1. écran titre → clic sur **Nouvelle partie** ;
2. île : clic sur l'éolienne, clics sur les nuages (en suivant leur dérive), clic maintenu sur les filons ;
3. atelier : touche **C**, clics sur les onglets, la recette et le bouton Fabriquer / Installer / Construire ;
4. plongée : clic sur la cloche, transition non passée, conduite aux touches **ZQSD** avec l'inertie du jeu,
   minage en maintenant **E**, remontée quand l'air restant couvre la remontée plus une marge ;
5. objectifs dans l'ordre : câble tressé → lanterne → réservoir → passerelle de nuage → récolte du bassin.

Le robot ne récolte que ce qui sert à ses objectifs. Avant de plonger, il ramasse tout ce qui est
disponible sur l'île : selon l'arrivée des nuages, il passe de 36 à 88 s sur l'île au début de la partie.

### Deux profils

| | Robot parfait | Joueur humain |
|---|---|---|
| Gisements | connaît la position de tous | ne voit que ceux **à l'écran et éclairés** (hors de l'obscurité, ou dans le halo de la lanterne), qu'il garde en mémoire pendant la plongée |
| Recherche | va droit au plus proche | **explore en zigzag** la bande de profondeur du minerai voulu (rangées plus serrées dans le noir) |
| Réaction en plongée | à chaque image | une décision toutes les **0,3 à 0,6 s** ; entre deux, les touches restent dans leur état |
| Pilotage | freine au pixel près | erreur de **±40 %** sur la distance de freinage, vise à ±6 px, ralentit près de la cible (comme on tapote les touches) |
| Minage | maintient E à 18 px | maintient E dès que le jeu l'affiche (24 px) |
| Marge d'air | 8 | **25** |
| Souris (déplacement / clic / lecture d'un menu) | 0,25 / 0,12 / 0,4 s | 0,5 / 0,2 / 1,0 s |
| Lecture de l'annonce du butin | 1 s | 2 s |

Les temps sont des **temps de jeu** (60 images de physique par seconde). Quatre parties par profil :
les gisements sont placés au hasard à chaque plongée.

Relancer : `GODOT=/chemin/vers/godot tests/playtest.sh 4 --video` (mesures brutes dans
`docs/playtest/mesures-<profil>-N.json`, vidéo dans `docs/playtest/`).

## Réglages appliqués depuis la première série

| | Réglage | Avant | Après |
|---|---|---|---|
| E | Profondeur des premiers coraux (`data/zones.json`, `gisements_des_m`) | 150 m | **155 m** |
| A | Éolienne : recharge / plafond (`data/ile.json`) | 12 s / 5 | **8 s / 6** |
| D | Gisements de cristal de lagon : nombre / profondeur des premiers | 12 / 10 m | **8 / 30 m** |
| C | Consommation d'air dans la Forêt de coraux | ×1,4 | **×1,5** |
| F | Cristal de lagon : lentille / réservoir (`data/recettes.json`) | 2 / 4 (10 au total) | **1 / 3 (8 au total)** |
| G | Passerelle sans corail | | refusé |

## Résultats

### Vue d'ensemble

| | Robot parfait **avant** réglages | Robot parfait | **Joueur humain** |
|---|---|---|---|
| Durée totale (4 parties) | 153 à 155 s | 113 à 163 s | **210 à 222 s** |
| Durée moyenne | 2 min 34 | 2 min 16 | **3 min 35** |
| Plongées par partie | 3 | 2 | **3** |
| Sur l'île | 70 s (45 %) | 61 s (45 %) | 68 s (31 %) |
| Sous l'eau | 68 s (44 %) | 64 s (47 %) | 131 s (61 %) |
| En transition | 15 s (10 %) | 10 s (7 %) | 14 s (7 %) |
| **Remontées automatiques** | 0 | 0 | **0** |
| **Attentes de plus de 10 s** | 4 (une par partie, vent) | **0** | **0** |

### Joueur humain : plongées et air restant

| Partie | Plongée | Prof. max | Sous l'eau | dont exploration | Butin | **Air restant** |
|---|---|---|---|---|---|---|
| 1 | 1 (Lagon) | 91 m | 40,9 s | 15,3 s | 8 cristaux | **52** / 100 |
| 1 | 2 (Coraux) | 192 m | 51,6 s | 26,2 s | 5 coraux | **27** / 100 |
| 1 | 3 (Coraux) | 189 m | 45,5 s | 21,0 s | 2 coraux | **38** / 100 |
| 2 | 1 (Lagon) | 86 m | 36,1 s | 13,0 s | 8 cristaux | **57** / 100 |
| 2 | 2 (Coraux) | 178 m | 53,0 s | 21,8 s | 5 coraux | **25** / 100 |
| 2 | 3 (Coraux) | 163 m | 38,7 s | 18,2 s | 2 coraux | **51** / 100 |
| 3 | 1 (Lagon) | 67 m | 31,9 s | 8,7 s | 8 cristaux | **62** / 100 |
| 3 | 2 (Coraux) | 198 m | 51,8 s | 26,5 s | 4 coraux | **26** / 100 |
| 3 | 3 (Coraux) | 189 m | 48,0 s | 22,5 s | 3 coraux | **34** / 100 |
| 4 | 1 (Lagon) | 53 m | 27,6 s | 8,8 s | 8 cristaux | **68** / 100 |
| 4 | 2 (Coraux) | 192 m | 52,4 s | 27,7 s | 3 coraux | **26** / 100 |
| 4 | 3 (Coraux) | 189 m | 47,3 s | 20,3 s | 4 coraux | **35** / 100 |

- **Aucune remontée automatique** et aucune perte de butin.
- Air restant : 52 à 68 au retour du Lagon, **25 à 27** à la fin de la première plongée en Forêt de coraux
  (le joueur remonte sur sa marge de 25), 34 à 51 à la seconde.
- Les 7 coraux ne tiennent jamais en une plongée : l'air manque avant (3 à 5 coraux la première fois).
- L'exploration prend 9 à 15 s dans le Lagon et 18 à 28 s dans les coraux, soit 30 à 50 % du temps sous l'eau.

### Robot parfait : plongées et air restant

| Partie | Plongée 1 (Lagon, 8 cristaux) | Plongée 2 (Coraux, 7 coraux) |
|---|---|---|
| 1 | 89 m, 26,0 s, air **70** | 175 m, 39,8 s, air **46** |
| 2 | 47 m, 18,5 s, air **79** | 197 m, 44,5 s, air **38** |
| 3 | 67 m, 21,8 s, air **75** | 177 m, 40,6 s, air **45** |
| 4 | 55 m, 21,2 s, air **75** | 185 m, 44,0 s, air **39** |

### Attentes de plus de 10 s sans rien à faire

**Aucune**, pour les deux profils (contre une attente de vent par partie avant les réglages). Le vent n'a plus
jamais manqué : il en reste même 0 à 1 (robot) ou 3 (humain) en fin de partie.

### Ressources en trop ou qui ont manqué

- **En trop** : 1 cristal de lagon (celui du bassin, récolté en dernier) et 0 à 3 vents. Rien d'autre.
- **Ont manqué** : rien sur l'île. En plongée, l'air limite le corail du joueur humain (2 plongées au lieu d'une).

## Vidéo

Séquence de 46 s enregistrée avec Movie Maker (Xvfb, 640x360 à 30 images/s), jouée par le robot parfait avec
les nouveaux réglages : écran titre, récolte, descente, plongée jusqu'à 75 m (obscurité et halo visibles),
minage de 6 cristaux, remontée, atelier (fabrication d'un fil de nuage).

- MP4 (2,1 Mo, 1280x720) : `docs/playtest/sequence.mp4`
- GIF (4,1 Mo, 640x360, 12 images/s) : `docs/playtest/sequence.gif`

## Conclusions

### Ce que les réglages ont corrigé

1. **Le vent ne dicte plus la fin de partie** : aucune attente de plus de 10 s pour les deux profils.
2. **Le câble tressé redevient indispensable** : premiers coraux à 155 m, hors de portée du câble de 150 m
   (vérifié par `tests/run_tests.gd`).
3. **Plus de plongée « 2 cristaux »** : 8 cristaux au total, une seule plongée de cristal pour les deux profils.
4. **Le Lagon se cherche** : les cristaux sont répartis entre 30 et 150 m (le joueur humain descend jusqu'à
   53 à 91 m). On voit l'obscurité et le halo, et l'exploration prend 9 à 15 s.
5. **La Forêt de coraux crée de la tension sans punir** : le joueur humain remonte avec 25 à 27 d'air (sa
   marge), sans jamais de remontée automatique. À ×1,5, il a le temps d'explorer 20 à 28 s et de miner
   3 à 5 coraux par plongée ; ×1,7 n'a pas été mesuré.

### Ce qui reste à surveiller

6. **La boucle reste courte** : 3 min 35 pour le joueur humain simulé, sans doute 5 à 8 minutes pour un vrai
   joueur qui découvre le jeu. La PR 2 de l'étape 4 (Faille volcanique et niveaux 2) l'allongera.
7. **Lanterne, réservoir et bassin n'ont toujours aucun usage une fois obtenus.** Le réservoir et la lanterne
   s'installent avec les coraux de la dernière plongée : aucune plongée ne s'est faite avec eux. À traiter dans
   la PR 2 de l'étape 4.
8. **Le corail demande deux plongées au joueur humain**, dont la seconde pour 2 à 4 coraux. Ce n'est pas une
   corvée (38 à 48 s), mais si le test sur PC la trouve longue, la piste est le stock des gisements de corail
   (3 à 5), pas l'air.
9. Le robot parfait passe 36 ou 88 s sur l'île selon qu'il ramasse tous les nuages avant sa première plongée
   ou non : les nuages arrivent lentement (environ 1 nuage récoltable par seconde au mieux). Ce n'est pas une
   attente, mais 23 nuages représentent beaucoup de clics. Le test sur PC dira si c'est agréable ou répétitif.

### Propositions restantes (non appliquées)

| # | Proposition |
|---|---|
| B | Poche d'air : 3 → 2 vents. **Plus nécessaire** : le vent ne manque plus. |
| H | Donner un usage à la lanterne et au réservoir dans la PR 2 de l'étape 4 (Faille volcanique sombre et gourmande en air). |
| I | Si les clics sur les nuages lassent au test sur PC : nuages à 4 prises au lieu de 3, ou fil de nuage à 2 nuages au lieu de 3. |

### Limites du robot

- Le joueur humain simulé ne se trompe pas de minerai, ne relit pas les recettes et ne récolte pas « pour voir ».
  Il ne passe jamais les transitions.
- Il repère les gisements seulement dans la zone éclairée, alors que les éclats cyan et violets des
  gisements restent visibles dans le noir (règle de la palette) : un vrai joueur les trouvera un peu plus vite.
- Le menu pause et la sauvegarde en cours de partie ne sont pas joués (couverts par `tests/run_tests.gd`).
