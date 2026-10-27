# Playtest automatique : boucle complète du MVP

Date : 27 octobre 2026, branche `etape-6-playtest` (code du jeu identique à `main` après la PR #7).

## Méthode

`tests/playtest.gd` joue une partie entière comme un joueur, avec de vrais évènements clavier et souris
(`Input.parse_input_event`), sans téléportation ni modification de l'inventaire :

1. écran titre → clic sur **Nouvelle partie** ;
2. île : clic sur l'éolienne, clics sur les nuages (en suivant leur dérive), clic maintenu sur les filons ;
3. atelier : touche **C**, clics sur les onglets, la recette et le bouton Fabriquer / Installer / Construire ;
4. plongée : clic sur la cloche, transition non passée, conduite aux touches **ZQSD** avec l'inertie du jeu
   (le robot relâche les touches à la distance de freinage), minage en maintenant **E**, remontée quand
   l'air restant couvre tout juste la remontée et une marge de 8 ;
5. objectifs dans l'ordre : câble tressé → lanterne → réservoir → passerelle de nuage → récolte du bassin.

Le robot ne récolte que ce qui sert à ses objectifs (pas de surplus volontaire). Il a un rythme humain pour
la souris (0,25 s par déplacement, 0,4 s de lecture dans l'atelier), mais il **connaît la position de tous
les gisements** et ne se trompe jamais de chemin : c'est une borne basse du temps de jeu. Un joueur humain
qui découvre le jeu ira sans doute 2 à 4 fois moins vite.

Les temps sont des **temps de jeu** (60 images de physique par seconde). Quatre parties ont été jouées,
car les gisements sont placés au hasard à chaque plongée.

Relancer : `GODOT=/chemin/vers/godot tests/playtest.sh 4 --video` (mesures brutes dans
`docs/playtest/mesures-partieN.json`, vidéo dans `docs/playtest/`).

## Résultats

### Vue d'ensemble

| | Partie 1 | Partie 2 | Partie 3 | Partie 4 | **Moyenne** |
|---|---|---|---|---|---|
| Durée totale | 155,0 s | 153,4 s | 153,3 s | 153,6 s | **153,8 s (2 min 34)** |
| Plongées | 3 | 3 | 3 | 3 | **3** |
| Sur l'île | 68,3 s | 77,1 s | 53,7 s | 79,1 s | **69,6 s (45 %)** |
| En plongée (sous l'eau) | 70,4 s | 60,0 s | 83,3 s | 58,2 s | **68,0 s (44 %)** |
| En transition | 14,9 s | 14,9 s | 14,9 s | 14,9 s | **14,9 s (10 %)** |
| Écran titre | 1,3 s | 1,3 s | 1,3 s | 1,3 s | 1,3 s |
| Remontées automatiques | 0 | 0 | 0 | 0 | **0** |
| Objectifs atteints | oui | oui | oui | oui | |

### Plongées (oxygène restant à l'arrivée en surface)

| Partie | Plongée | Câble | Prof. max | Sous l'eau | Butin | Air restant |
|---|---|---|---|---|---|---|
| 1 | 1 | 150 m | 32 m | 15,5 s | 8 cristaux de lagon | 82 / 100 |
| 1 | 2 | 150 m | 32 m | 9,1 s | 2 cristaux de lagon | 90 / 100 |
| 1 | 3 | 300 m | 208 m | 45,9 s | 7 coraux | 37 / 100 |
| 2 | 1 | 150 m | 33 m | 15,5 s | 8 cristaux de lagon | 82 / 100 |
| 2 | 2 | 150 m | 16 m | 5,4 s | 2 cristaux de lagon | 94 / 100 |
| 2 | 3 | 300 m | 170 m | 39,1 s | 7 coraux | 49 / 100 |
| 3 | 1 | 150 m | **150 m** | 36,5 s | **5 coraux** + 3 cristaux | 55 / 100 |
| 3 | 2 | 150 m | 28 m | 13,2 s | 7 cristaux de lagon | 85 / 100 |
| 3 | 3 | 300 m | 170 m | 33,6 s | 2 coraux | 58 / 100 |
| 4 | 1 | 150 m | 21 m | 13,1 s | 8 cristaux de lagon | 85 / 100 |
| 4 | 2 | 150 m | 33 m | 8,7 s | 2 cristaux de lagon | 90 / 100 |
| 4 | 3 | 300 m | 158 m | 36,4 s | 7 coraux | 53 / 100 |

Aucune perte de butin, aucune remontée automatique. Air restant : 82 à 94 dans le Lagon, 37 à 58 dans la
Forêt de coraux.

### Attentes de plus de 10 s sans rien à faire

| Partie | Moment | Durée | Raison |
|---|---|---|---|
| 1 | 140,2 s | 10,4 s | en attente de vent (dernier fil de nuage de la passerelle) |
| 2 | 138,6 s | 10,4 s | en attente de vent |
| 3 | 138,4 s | 10,4 s | en attente de vent |
| 4 | 138,8 s | 10,4 s | en attente de vent |

Temps total passé à attendre du vent sur l'île (attentes courtes comprises) : 27,0 s, 34,5 s, 15,0 s et 36,5 s.
Aucune autre ressource n'a jamais manqué : nuages et cristaux solaires étaient toujours disponibles.

### Ressources en trop ou qui ont manqué

- **En trop** : rien. L'inventaire final ne contient que le cristal de lagon récolté dans le bassin.
  L'économie est « au plus juste » : 13 vents, 23 nuages, 5 cristaux solaires, 10 cristaux de lagon et
  7 coraux suffisent exactement.
- **Ont manqué** : uniquement le **vent**. L'éolienne (1 vent toutes les 12 s, 5 au plus) fixe la durée de la
  partie : les quatre parties se terminent à 1 seconde près au même moment (151 à 152 s), quel que soit le
  placement des gisements.
- Seconde plongée : il faut 10 cristaux de lagon mais le sac n'en porte que 8, d'où une plongée de 5 à 13 s
  pour 2 cristaux.

### Ordre de fabrication observé (partie 1)

| Temps | Atelier |
|---|---|
| 35 s | 2 fils de nuage |
| 54-58 s | fil de nuage, **câble tressé**, lentille, fil de nuage |
| 113-118 s | **lanterne**, 2 poches d'air, **réservoir** |
| 128-152 s | 3 fils de nuage (un toutes les 12 s, au rythme du vent) |
| 153 s | **passerelle de nuage** |

## Vidéo

Séquence de 41 s enregistrée avec Movie Maker (Xvfb, 640x360 à 30 images/s) : écran titre, récolte,
descente, plongée et minage de 6 cristaux, remontée, atelier (fabrication d'un fil de nuage).

- MP4 (1,7 Mo, 1280x720) : `docs/playtest/sequence.mp4`
- GIF (3,2 Mo, 640x360, 12 images/s) : `docs/playtest/sequence.gif`

## Conclusions

### Trop rapide

1. **La boucle complète du MVP dure 2 min 34** pour le robot, soit sans doute 5 à 10 minutes pour un joueur.
   C'est court pour 4 améliorations et un îlot. La PR 2 de l'étape 4 (Faille volcanique, niveaux 2) allongera
   la boucle, mais le rythme de base mérite d'être revu avant.
2. **Les plongées sont trop sûres** : jamais de remontée automatique, jamais moins de 37 d'air, et 82 à 94
   dans le Lagon. Les 8 cristaux de la première plongée se trouvent à moins de 35 m : l'obscurité (qui
   commence à 40 m) n'est jamais vue en cherchant du cristal, et la jauge d'air ne crée aucune tension.
3. **Le corail est parfois atteignable sans le câble tressé** (partie 3 : 5 coraux dès la première plongée).
   Les gisements de corail peuvent apparaître juste au début de la Forêt de coraux (150 à 152 m), à portée de
   la cloche arrêtée par le câble de 150 m. Le câble perd alors son rôle de « porte ».

### Trop lent ou frustrant

4. **Le vent est le seul goulot d'étranglement** : il dicte la fin de partie à la seconde près. Les
   10 dernières secondes sont une attente pure, avec rien à faire sur l'île, et le joueur n'a aucun moyen
   d'aller plus vite. Avec un joueur réel, cela se verra moins (il est plus lent ailleurs), mais la fin de
   partie reste « attendre l'éolienne ».
5. **La plongée de 2 cristaux** (10 cristaux nécessaires, sac de 8) ressemble à une corvée : 10 à 18 s avec
   les transitions pour presque rien.
6. **Lanterne, réservoir et bassin n'ont aucun usage une fois obtenus** : après eux, plus rien n'oblige à
   plonger. Le joueur ne profite jamais du halo plus grand, de l'air en plus ou du cristal du bassin.
7. Les transitions (5 s par plongée, 10 % du temps) restent acceptables, et une touche les passe.

### Propositions de réglages (non appliquées)

| # | Réglage | Actuel | Proposé | Effet attendu |
|---|---|---|---|---|
| A | Éolienne : recharge / plafond (`data/ile.json`) | 12 s / 5 | 8 s / 6 | le vent cesse de dicter la fin de partie |
| B | Vent dans la poche d'air (`data/recettes.json`) | 3 | 2 | moins de dépendance au vent (−2 vents au total) |
| C | Gisements de cristal de lagon (`data/zones.json`, `scripts/dive.gd`) | 12, dès 10 m | 8, dès 30 m (`DISTANCE_MIN_SURFACE` 100 → 300 px) | plongées plus longues, l'obscurité est vue |
| D | Consommation d'air dans la Forêt de coraux | ×1,4 | ×1,7 | la jauge d'air devient un vrai choix en zone 2 |
| E | Gisements de corail : profondeur minimale | 150 m (début de zone) | 155 m | le câble tressé redevient indispensable |
| F | Cristal de lagon : lentille / réservoir (`data/recettes.json`) | 2 / 4 | 1 / 3 (ou sac 8 → 10) | 8 cristaux au total : plus de plongée « 2 cristaux » |
| G | Passerelle de nuage : coût | 4 fils, 3 cristaux solaires, 2 coraux | 3 fils, 3 cristaux solaires, sans corail | l'îlot arrive plus tôt, le bassin remplace une partie des plongées de cristal |
| H | Utilité de la lanterne et du réservoir | aucune après installation | à prévoir dans la PR 2 de l'étape 4 (Faille volcanique sombre et gourmande en air) | les améliorations servent à quelque chose |

Ordre conseillé : **E** (correctif de règle, sans débat), puis **A + C + D** ensemble (rythme), puis **F** et
**G** après un test humain. **H** relève de la PR 2 de l'étape 4.

### Limites du robot

- Il voit tous les gisements dès la surface. Un joueur doit les chercher, et l'obscurité les cache hors du halo.
- Il ne se perd pas, ne relit pas les recettes et ne récolte pas « pour voir ». Il ne passe jamais les transitions.
- Il ne teste ni le menu pause, ni la sauvegarde en cours de partie (déjà couverts par `tests/run_tests.gd`).
