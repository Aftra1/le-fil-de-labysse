# Playtest automatique : boucle complète avec les machines des paliers 1 à 3

Date : 29 octobre 2026, branche `etape-7-machines-c` (étape 7, PR C).

## Palier 3 (étape 7, PR C)

Après la lanterne de niveau 2, le robot poursuit : **fourneau → sonde → arche de braise → sac à 16 places →
niveaux 2 du moulin (vitesse, réserve), de la foreuse (réserve) et du filet (vitesse) → entrepôt à 499**.

- **Fourneau** : un clic dessus récupère sa réserve et ouvre son panneau ; le robot y choisit le premier
  raffiné qui manque, et l'arrête quand plus rien ne manque. Le fourneau prend ses ingrédients dans
  l'inventaire, 1 raffiné toutes les 20 s, même en plongée et jeu fermé.
- **Recettes**, toutes au vent : verre de lagon (2 cristaux de lagon, 6 vents), nacre (1 corail, 8 ouates,
  2 vents), lingot solaire (5 cristaux solaires, 5 vents).
- **Arche de braise** : 3 pierres de braise, 4 lingots, **100 vents**. Sans entrepôt, l'inventaire s'arrête à
  99 : l'atelier le signale.
- Deux changements de méthode : le robot ne réunit plus que les ressources des **3 prochains objectifs**
  (comme un joueur qui avance pas à pas ; avant, il amassait d'un coup le vent de toute la partie), et il vide
  une machine **pleine** même si sa ressource ne manque pas encore (ses ailes arrêtées le signalent).

### Résultats (quatre parties par profil)

| | Robot parfait | **Joueur humain** |
|---|---|---|
| Durée totale | 1216 à 1297 s (PR B : 417 à 463 s) | **1457 à 1549 s** (PR B : 694 à 756 s) |
| Durée moyenne | 20 min 51 (PR B : 7 min 20) | **24 min 54** (PR B : 12 min 04) |
| Plongées par partie | 12 à 13 | 12 à 13 |
| Palier 2 ouvert à | 105 à 121 s | 153 à 237 s |
| Palier 3 ouvert à | 491 à 524 s | 680 à 759 s |
| Remontées automatiques | 0 | **0** |
| Attentes de plus de 10 s | 3 (12 à 18 s, le fourneau) | **1** (12 s) |

### D'où viennent les ressources, et où elles partent (moyenne par partie)

| Ressource | Machines | Île à la main | Plongées | **Part des machines** | Atelier | **Fourneau** | Reste |
|---|---|---|---|---|---|---|---|
| Vent (parfait) | 145 (moulin) | 113 (éolienne) | — | **56 %** | 158 (dont 100 pour l'arche) | **108** | 0 |
| Vent (humain) | 166 | 97 | — | **63 %** | 158 | **108** | 0 |
| Ouates (parfait) | 190 (filet) | 72 (nuages) | — | **73 %** | 94 (fils de nuage) | **56** | 119 |
| Ouates (humain) | 203 | 51 | — | **80 %** | 94 | **56** | 105 |
| Cristal solaire (parfait) | 48 (foreuse) | 30 (filons) | — | **61 %** | 31 | **40** | 12 |
| Cristal solaire (humain) | 46 | 28 | — | **62 %** | 31 | **40** | 5 |
| Cristal de lagon (parfait) | 10 (sonde) | 11 (bassin) | 30 | 20 % | 32 | 18 | 1 |
| Cristal de lagon (humain) | 16 | 6 | 30 | 30 % | 32 | 18 | 4 |

- **Le fourneau consomme la production des machines** :
  - cristal solaire : 40 au fourneau contre 31 à l'atelier ;
  - vent, depuis le palier 3 : 108 au fourneau contre 100 pour l'arche ;
  - ouates : 56 au fourneau, le reste des dépenses vient surtout des fils de nuage du début de partie.
- **Les machines fournissent la majorité** du vent (56 à 63 %), des ouates (73 à 80 %) et du cristal solaire
  (61 à 62 %).
- **L'entrepôt sert** : l'arche demande 100 vents d'un coup (plus haut niveau atteint : 101), et les ouates
  montent jusqu'à 125 à 161.
- **Le filet produit plus qu'il ne faut** : il reste 105 à 119 ouates en fin de partie (filet en vitesse 2).
  À reprendre dans la PR E (équilibrage) : une recette de plus pour les ouates, ou un filet moins rapide.
- **Raffinés fabriqués par partie** : 9 verres de lagon, 7 nacres, 8 lingots solaires.

### Vidéo

Séquence de 68 s avec le son (Movie Maker, Xvfb), à partir d'une partie préparée au palier 3 :
1. un clic sur le fourneau ouvre son panneau : **lingot solaire en boucle** ; il rougeoie et fume ;
2. à l'atelier, l'**arche de braise** relie l'îlot du couchant (le vent passe de 150 à 45), puis le
   **sac de plongée à 16 places** ;
3. plongée dans le Lagon (descente et remontée accélérées ×2) jusqu'à 16 cristaux ;
4. au retour, un clic vide la sonde (cristal de lagon pêché pendant la plongée) et le fourneau (lingots).

- MP4 (4,1 Mo, 1280x720, son AAC, moyenne −17 dB, crête −1 dB) : `docs/playtest/sequence.mp4`
- GIF (sans son) : `docs/playtest/sequence.gif`

---

# Rapport précédent : palier 2 (étape 7, PR B)


Objectifs du robot, dans l'ordre : câble 1 → moulin à vent → lanterne 1 → filet à nuages → réservoir 1 →
**sac à 12 places → pont suspendu (îlot du nord) → foreuse solaire** → passerelle → **entrepôt** → réservoir 2 →
câble 2 → **vitesse du moulin → réserve de la foreuse** → lanterne 2. Le palier 2 s'ouvre au premier corail
rapporté. Les améliorations se font à l'atelier, onglet Machines, avec les boutons Vitesse et Réserve.
Nouveauté de prudence (comme un joueur) : le robot n'entre pas dans la Faille sans le réservoir de 200.

| | Foreuse solaire | Entrepôt |
|---|---|---|
| Effet | sur un filon : 1 cristal solaire / 15 s, réserve 6 | inventaire jusqu'à 199 par ressource |
| Coût | 1 lentille, 4 coraux, 4 cristaux solaires | 5 coraux, 4 fils de nuage, 4 cristaux de lagon |

Autres coûts : pont suspendu 4 coraux et 4 fils de nuage ; sac à 12 places 4 coraux et 2 poches d'air.
Améliorations de niveau 1 (×1,5 en vitesse, ×2 en réserve) : moulin 2 fils de nuage et 3 cristaux de lagon
(vitesse) ; foreuse 3 coraux et 3 cristaux solaires (réserve).

### Résultats (quatre parties par profil)

| | Robot parfait | **Joueur humain** |
|---|---|---|
| Durée totale | 417 à 463 s (PR A : 293 à 310 s) | **694 à 756 s** (PR A : 398 à 611 s) |
| Durée moyenne | 7 min 20 (PR A : 5 min 03) | **12 min 04** (PR A : 8 min 16) |
| Plongées par partie | 7 | 8 à 9 |
| Palier 2 ouvert à | 147 à 160 s | 198 à 341 s |
| Foreuse construite à | 221 à 307 s | 480 à 539 s |
| Entrepôt construit à | 387 à 454 s | 498 à 637 s |
| Vent récolté sur le moulin | 19 à 25 | 23 à 28 |
| Remontées automatiques | 0 | **0** |
| Attentes de plus de 10 s | 0 | **0** |

- **+4 minutes pour le joueur humain** : 12 min 04 en moyenne au lieu de 8 min 16, avec 2 à 3 plongées de plus
  dans la Forêt de coraux (le palier 2 coûte 21 coraux de plus). C'est la moitié basse des +15 minutes prévues
  pour ce palier : le palier 3 et les trouvailles (PR C et D) feront le reste.
- **Le moulin compte** : 19 à 28 vents par partie, le quart à la moitié du vent nécessaire.
- **La foreuse et le filet servent peu** dans cette boucle : quand ils sont construits, il ne reste presque plus de
  cristal solaire ni d'ouates à réunir (le robot n'en vide la réserve que si la ressource manque). Ils prendront
  leur rôle avec les recettes du palier 3 (fourneau : lingots solaires, nacre).
- **L'entrepôt** est construit mais jamais nécessaire : aucune ressource ne dépasse 99 dans cette boucle.
- **Air au retour** (joueur humain) : 22 à 78 / 100 à 150 dans le Lagon et les Coraux, 32 à 67 / 200 dans la Faille.

### Vidéo (à l'époque)

Séquence de 65 s avec le son (Movie Maker, Xvfb), à partir d'une partie préparée au palier 2 (îlot du nord
relié avec son entrepôt, foreuse sur le filon du milieu, moulin et filet) : animations des machines → un clic vide
la foreuse (son « foreuse ») → survol de l'entrepôt (« jusqu'à 199 ») → un clic vide le moulin → atelier, onglet
Machines, **Vitesse du moulin** → onglet Améliorations, **sac de plongée** → plongée dans la Forêt de coraux
jusqu'à remplir le sac (**12 coraux**, descente et remontée accélérées ×2) → au retour, un clic vide la foreuse
et le moulin.

Elle est remplacée par la séquence du palier 3 (voir plus haut).

---

# Rapport précédent : machines du palier 1 (étape 7, PR A)


Le robot poursuit maintenant deux objectifs de plus, dans l'ordre où un joueur les rencontre :
**câble 1 → moulin à vent → lanterne 1 → filet à nuages → réservoir 1 → passerelle → réservoir 2 → câble 2 →
lanterne 2**. Il construit une machine comme un joueur : clic sur un emplacement libre (l'atelier s'ouvre
sur l'onglet Machines), choix de la machine, **Construire**. Quand du vent ou des ouates manquent, il vide
d'abord les machines d'un clic, avant l'éolienne et les nuages.

| | Moulin à vent | Filet à nuages |
|---|---|---|
| Production | 1 vent / 10 s, réserve 8 | 1 ouate / 6 s, réserve 10 |
| Coût | 2 fils de nuage, 3 cristaux de lagon, 2 cristaux solaires | 3 fils de nuage, 2 cristaux de lagon |

### Résultats (quatre parties par profil)

| | Robot parfait | **Joueur humain** |
|---|---|---|
| Durée totale | 293 à 310 s (avant : 308 à 323 s) | **398 à 611 s** (avant : 399 à 502 s) |
| Durée moyenne | 5 min 03 (avant : 5 min 14) | **8 min 16** (avant : 7 min 41) |
| Plongées par partie | 5 | 5 à 6 |
| Moulin construit à | 41 à 50 s | 62 à 252 s |
| Filet construit à | 145 à 161 s | 129 à 336 s |
| Vent récolté sur le moulin | 14 à 15 | 13 à 16 |
| Remontées automatiques | 0 | **0** |
| Attentes de plus de 10 s | 0 | **0** |

- **Le moulin sert** : 13 à 16 vents par partie, soit la moitié du vent nécessaire après sa construction.
  L'éolienne et lui suffisent : le robot n'attend jamais le vent.
- **Le filet ne sert pas encore** : quand il est construit, il ne reste presque plus d'ouates à réunir (les
  nuages et leurs 2 ouates par clic suffisent). Il prendra son rôle avec les recettes du palier 2.
- **Durée** : le palier 1 coûte des matières (5 fils de nuage, 5 cristaux de lagon, 2 cristaux solaires)
  et en rend une partie en vent. Le robot parfait gagne 11 s, le joueur humain perd 35 s en moyenne
  (la partie 4 construit son moulin tard, à 252 s, après une plongée de plus). Les +45 à 60 minutes visées
  viendront des paliers 2 et 3, des îlots et des trouvailles (PR B à D).
- **Air au retour** (joueur humain) : 22 à 80 / 100 à 150 dans le Lagon et les Coraux, 45 à 68 / 200 dans la
  Faille ; aucune remontée automatique en 23 plongées.

### Vidéo (à l'époque)

Séquence de 40 s avec le son (Movie Maker, Xvfb, 640x360 à 30 images/s), à partir d'une partie préparée
(îlot relié, moulin au centre de l'île, filet sur l'îlot) : le moulin tourne et le filet ondule → un clic vide
chacun (son « machine ») → survol de l'emplacement libre de l'ouest (pointillés or) → clic : atelier, onglet
Machines → **un second filet à nuages** → plongée dans le Lagon de lumière (descente et remontée accélérées ×2)
→ au retour, le moulin et les filets ont produit pendant la plongée → un clic les vide.

Elle est remplacée par la séquence du palier 2 (voir plus haut).

---

# Rapport précédent : boucle complète avec la Faille volcanique (étape 4, partie 2)

Les mesures brutes de ce rapport ont été remplacées par celles des machines ; la méthode reste valable.

## Méthode

`tests/playtest.gd` joue une partie entière avec de vrais évènements clavier et souris
(`Input.parse_input_event`), sans téléportation ni modification de l'inventaire :

1. écran titre → clic sur **Nouvelle partie** ;
2. île : clic sur l'éolienne, clics sur les nuages (2 ouates par clic), clic maintenu sur les filons et,
   une fois l'îlot relié, sur le bassin de lumière quand il manque du cristal de lagon ;
3. atelier : touche **C**, clics sur les onglets, la recette et le bouton Fabriquer / Installer / Construire ;
4. plongée : clic sur la cloche, transition non passée, conduite aux touches **ZQSD** avec l'inertie du jeu,
   minage en maintenant **E**, remontée quand l'air restant couvre la remontée (consommation de chaque zone)
   plus une marge ;
5. objectifs dans l'ordre : câble 1 → lanterne 1 → réservoir 1 → passerelle de nuage → **réservoir 2 →
   câble 2 → lanterne 2** (avec les pierres de braise de la Faille).

### Deux profils

| | Robot parfait | Joueur humain |
|---|---|---|
| Gisements | connaît la position de tous | ne voit que ceux **à l'écran et éclairés** (hors de l'obscurité, ou dans le halo), qu'il garde en mémoire pendant la plongée |
| Recherche | va droit au plus proche | **explore en zigzag** la bande de profondeur du minerai voulu |
| Réaction en plongée | à chaque image | une décision toutes les **0,3 à 0,6 s** |
| Pilotage | freine au pixel près | erreur de **±40 %** sur la distance de freinage, vise à ±6 px, ralentit près de la cible |
| Marge d'air | 8 | **25** |
| Souris (déplacement / clic / lecture d'un menu) | 0,25 / 0,12 / 0,4 s | 0,5 / 0,2 / 1,0 s |

Temps de jeu (60 images par seconde), quatre parties par profil, gisements placés au hasard à chaque plongée.
Relancer : `GODOT=/chemin/vers/godot tests/playtest.sh 4 --video` (mesures brutes dans
`docs/playtest/mesures-<profil>-N.json`).

## Contenu ajouté (étape 4, partie 2)

| | Réglage |
|---|---|
| Faille volcanique | 300 à 450 m, 6 gisements de **pierre de braise** à partir de 305 m (2 à 4 pierres, 1,5 s par pierre), air **×1,8** |
| Câble niveau 2 | **450 m** : 4 fils de nuage, 2 coraux, 3 cristaux solaires |
| Réservoir niveau 2 | **200** d'air : 3 poches d'air, 2 coraux, 3 cristaux de lagon |
| Lanterne niveau 2 | halo **80**, obscurité au plus 1 ton : 2 lentilles, 4 pierres de braise |
| Nuages | **2 ouates par clic** (3 clics par nuage) |

### Chiffres revus avec les réglages de l'étape 6

- **Budget d'air à 450 m** (test `budget 450 m`, aller-retour à pleine vitesse sans s'arrêter) :
  - réservoir 200 : 159 à 300 m, 130 à 450 m, **59 au retour** en surface, soit 27 s de travail possibles au fond ;
  - réservoir 150 : **9 au retour** : le niveau 2 du réservoir est nécessaire pour la Faille, ce que l'ordre des
    objectifs (réservoir 2 avant câble 2) respecte.
- **Coûts des niveaux 2** : une première série avait 4 coraux pour le câble et 3 pour le réservoir (14 coraux au
  total dans la partie). Le joueur humain faisait alors **4 à 5 plongées dans les coraux, dont une revenue
  vide**. Ramenés à 2 + 2 (11 coraux au total), il lui en faut 2 à 3. Ce sont les chiffres ci-dessous.

## Résultats

### Vue d'ensemble

| | Robot parfait | **Joueur humain** |
|---|---|---|
| Durée totale (4 parties) | 308 à 323 s | **399 à 502 s** |
| Durée moyenne | 5 min 14 | **7 min 41** |
| Plongées par partie | 5 | **5 à 6** |
| Sur l'île | 92 s (29 %) | 114 s (25 %) |
| Sous l'eau | 195 s (62 %) | 317 s (69 %) |
| En transition | 25 s (8 %) | 29 s (6 %) |
| **Remontées automatiques** | 0 | **0** |
| **Attentes de plus de 10 s** | 0 | **0** |

Avant cette partie de l'étape 4, la même boucle (sans la Faille ni les niveaux 2) durait 1 min 54 à 2 min 43
pour le robot et 3 min 30 à 3 min 42 pour le joueur humain.

### Joueur humain : plongées et air restant

| Partie | Lagon (2 plongées) | Forêt de coraux | **Faille volcanique** |
|---|---|---|---|
| 1 | 69 et 67 / 100 | 25 / 100 (6 coraux), 46 / 150 (5) | **61 / 200** (4 pierres, 84,5 s sous l'eau) |
| 2 | 51 et 61 / 100 | 26 / 100 (3), 26 / 100 (7), 92 / 150 (1) | **43 / 200** (4 pierres, 92,4 s) |
| 3 | 26 et 61 / 100 | 24 / 100 (3), 26 / 100 (4), 86 / 150 (4) | **51 / 200** (4 pierres, 89,1 s) |
| 4 | 59 et 52 / 100 | 23 / 100 (6), 79 / 150 (5) | **21 / 200** (2 pierres, 103,2 s), puis **84 / 200** (2 pierres) |

- **Aucune remontée automatique** en 23 plongées.
- Dans la Faille, l'exploration prend **36 à 58 s** par plongée (contre 20 à 30 s dans les coraux) : c'est
  sombre, les gisements sont rares (6) et le halo est de 60 tant que la lanterne n'est pas au niveau 2.
- Une partie sur quatre demande 2 plongées dans la Faille. La plus longue revient à 21 / 200, sous la marge
  de 25 du joueur : il a mal estimé sa remontée depuis 396 m, mais l'air n'est pas tombé à zéro.

### Robot parfait : plongées et air restant

| Partie | Lagon | Coraux | Faille |
|---|---|---|---|
| 1 | 78, 77 / 100 | 26 / 100 (8), 103 / 150 (3) | 70 / 200 (4 pierres, 383 m) |
| 2 | 80, 79 / 100 | 42 / 100 (8), 108 / 150 (3) | 76 / 200 (4 pierres, 373 m) |
| 3 | 69, 73 / 100 | 37 / 100 (8), 109 / 150 (3) | 70 / 200 (4 pierres, 383 m) |
| 4 | 75, 80 / 100 | 37 / 100 (8), 105 / 150 (3) | 86 / 200 (4 pierres, 343 m) |

### Attentes de plus de 10 s sans rien à faire

**Aucune**, pour les deux profils. Le robot parfait attend un peu de vent avant le dernier fil de nuage du câble
de niveau 2 (15 à 28 s au total, en attentes courtes) ; le joueur humain, plus lent, ne l'attend jamais.

### Ressources en trop ou qui ont manqué

- **En trop** : 1 cristal de lagon, celui du bassin, récolté en dernier. Rien d'autre.
- **Ont manqué** : rien sur l'île (vent compris). En plongée, l'air limite le corail et la pierre de braise du
  joueur humain, sans jamais de remontée automatique.

## Vidéo (à l'époque)

Séquence de 42 s (Movie Maker, Xvfb, 640x360 à 30 images/s), jouée par le robot à partir d'une partie
préparée (câble 450 m, réservoir 200, lanterne 1, îlot relié, 2 lentilles et 2 pierres de braise en poche) :
écran titre → **Continuer** → un clic sur un nuage (+2) → descente → traversée du Lagon, de la Forêt de coraux
et de la Faille (**accélérée ×4**) → minage de 2 pierres de braise dans la Faille → remontée (**accélérée ×4**)
→ atelier : **lanterne de cristal niveau 2**. Les passages accélérés sont repérés automatiquement par le robot
(lignes `VIDEO` du journal) et montés par `tests/playtest.sh`.

Elle est remplacée par la séquence des machines (voir plus haut).

## Conclusions

### Ce qui fonctionne

1. **La boucle complète double** : 7 min 41 en moyenne pour le joueur humain simulé (3 min 35 avant), soit
   sans doute 10 à 15 minutes pour un vrai joueur qui découvre le jeu.
2. **Le réservoir et la lanterne servent enfin** : la Faille ne se fait qu'avec 200 d'air (9 au retour avec
   150), et la lanterne de niveau 1 éclaire les recherches dans la Faille (60 de halo dans le noir).
3. **La Faille est tendue sans punir** : 21 à 84 / 200 au retour, aucune remontée automatique, 1 ou 2 plongées.
4. **Aucune attente** de plus de 10 s : le vent suit, même avec 26 vents nécessaires au total.
5. **Les nuages** : 2 ouates par clic divisent par deux les clics (38 ouates nécessaires dans la partie).

### Ce qui reste à surveiller

6. **La lanterne de niveau 2 et le bassin ne servent toujours pas** : la lanterne 2 est le dernier objectif, et le
   bassin n'est jamais utile (les 13 cristaux de lagon sont tous ramenés par les 2 premières plongées, avant que
   l'îlot soit relié). Ce sera à traiter avec « Le Fond » (après le MVP) ou en demandant du cristal de lagon
   pour la lanterne 2 ou la passerelle.
7. **L'exploration dans la Faille** (36 à 58 s par plongée) est le passage le plus long. Si le test sur PC la
   trouve pénible : 8 gisements au lieu de 6, ou une pierre de braise plus lumineuse dans le noir.
8. Le joueur humain est revenu une fois avec 21 / 200 depuis 396 m : sans risque de game over, mais la remontée
   depuis le fond de la Faille est longue (environ 36 s à pleine vitesse). C'est le seul moment où la jauge descend vraiment.

### Propositions (non appliquées)

| # | Proposition |
|---|---|
| J | Lanterne de niveau 2 : ajouter 3 cristaux de lagon à la recette, pour donner un rôle au bassin en fin de partie. |
| K | Faille : 8 gisements au lieu de 6 si l'exploration paraît longue au test sur PC. |
| L | Bassin de lumière : 1 cristal toutes les 30 s au lieu de 45, s'il doit compter dans la boucle. |

### Limites du robot

- Le joueur humain simulé ne se trompe pas de minerai et ne récolte pas « pour voir ». Il ne passe jamais les transitions.
- Il ne repère les gisements que dans la zone éclairée, alors que les éclats cyan, violets et or restent
  visibles dans le noir : un vrai joueur les trouvera un peu plus vite, surtout dans la Faille.
- Le menu pause et la sauvegarde en cours de partie ne sont pas joués (couverts par `tests/run_tests.gd`).
