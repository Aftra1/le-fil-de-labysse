# Le Fil de l'Abysse

Jeu PC (Windows) en 2D pixel art, fait avec Godot 4.7.1 (GDScript, rendu GL Compatibility).
Tu gardes une île flottante au-dessus d'un océan sans fond, et tu plonges dans une cloche reliée par un câble.

## Lancer le projet

1. Télécharge **Godot 4.7.1** (version standard, pas .NET) sur <https://godotengine.org/download/>.
2. Lance Godot, clique sur **Importer**, puis choisis le fichier `project.godot` de ce dépôt.
3. Appuie sur **F5** (ou le bouton ▶) pour lancer le jeu.

En ligne de commande : `godot --path .` (ou `godot --headless --path . --quit-after 5` pour un test sans fenêtre).

## Contrôles

Le jeu s'ouvre sur l'écran titre : **Continuer** (reprend la partie sauvegardée), **Nouvelle partie** (demande confirmation si une partie existe), **Quitter**.

Sur l'île (à la souris) :

| Action | Commande |
|---|---|
| Récolter un nuage | Clic sur le nuage (2 ouates par clic, 3 clics par nuage) |
| Vider l'éolienne (vent) | Clic sur l'éolienne |
| Récolter un cristal solaire | Maintenir le clic sur un filon (1 s) |
| Relier l'îlot | Construire la passerelle de nuage à l'atelier (onglet Construction ; un clic sur l'îlot l'ouvre) |
| Récolter un cristal de lagon (îlot relié) | Maintenir le clic sur le bassin de lumière (1 s) |
| Relier l'îlot du nord | Construire le pont suspendu (onglet Construction ; un clic sur l'îlot l'ouvre) |
| Construire une machine | Clic sur un emplacement libre (pointillés or) : l'atelier s'ouvre sur l'onglet Machines |
| Améliorer une sorte de machine | Atelier, onglet Machines, boutons Vitesse ou Réserve (dès le palier 2) |
| Régler un fourneau | Clic sur le fourneau : récupère sa réserve et ouvre le choix du raffiné fabriqué en boucle |
| Relier l'îlot du couchant | Construire l'arche de braise (onglet Construction ; un clic sur l'îlot l'ouvre) |
| Vider une machine | Clic sur la machine (toute sa réserve passe dans l'inventaire) |
| Échanger avec le marchand de vent | Clic sur son dirigeable quand il passe, puis Échanger (Échap pour fermer) |
| Plonger | Clic sur la cloche, ou E / Espace |
| Inventaire | I, Tab ou le bouton « Inventaire » (Échap pour fermer) |
| Carnet de collection | K ou le bouton « Carnet » (Échap pour fermer) |
| Atelier | C ou un clic sur la cabane (Échap pour fermer) |
| Passer la transition | N'importe quelle touche ou un clic (sauf Échap, ignoré) |
| Menu pause | Échap (si aucun panneau n'est ouvert) |

En plongée :

| Action | Touches |
|---|---|
| Se déplacer | ZQSD (AZERTY) / WASD / flèches |
| Miner (maintenir près d'un gisement) | E ou Espace |
| Ramasser une trouvaille (éclat scintillant) | Maintenir E près de l'éclat (2 s) |
| Menu pause | Échap (le jeu est figé ; quitter la plongée abandonne son butin) |

Les touches sont physiques : ZQSD fonctionne sur un clavier AZERTY.
La plongée se termine quand la cloche revient en surface après être descendue sous 10 m.

Zones de plongée : Lagon de lumière (0 à 150 m, cristal de lagon), Forêt de coraux (150 à 300 m, corail
luisant), Faille volcanique (300 à 450 m, pierre de braise). Le câble tressé ouvre les zones une à une
(150 m → 300 m → 450 m) ; le réservoir d'air de niveau 2 (200) est nécessaire pour revenir du fond de la Faille.

## Trouvailles et carnet

À chaque plongée, chaque zone peut cacher **une trouvaille rare** (3 chances sur 4, tant que sa page n'est pas
complète), dans sa moitié basse : un éclat scintillant de la couleur lumineuse de la zone, visible même dans le
noir. Elle se ramasse en 2 s, ne prend pas de place dans le sac et n'est jamais perdue. Le **carnet** (K) les
range en pages, chacune avec son nom et un bout de l'histoire d'Ilume, la cité engloutie :

| Page | Contenu | Bonus de la page complète |
|---|---|---|
| Perles du Lagon | 6 perles | le sac de plongée gagne une place |
| Fossiles des Coraux | 6 fossiles | la Forêt de coraux se mine 25 % plus vite |
| Reliques de la Faille | 6 reliques | la Faille consomme 20 % d'air en moins |
| Machines | les 6 machines, dès leur première construction | toutes les machines produisent 10 % plus vite |

Le carnet affiche son pourcentage (24 cases) ; les trouvailles sont dans `data/trouvailles.json`, leur pixel
art dans `scripts/art_trouvailles.gd`. Tant qu'une nouvelle trouvaille n'a pas été regardée, le bouton affiche
« Carnet (K) • », et le carnet s'ouvre directement sur elle.

## Marchand de vent

Le vieux marchand de vent (`data/marchand.json`) passe en dirigeable environ toutes les 4 min de jeu (temps sur
l'île et en plongée, pas jeu fermé) et reste 60 s. S'il arrive pendant une plongée, il attend le retour sur
l'île ; s'il est là au départ, son temps s'arrête jusqu'au retour. À chaque passage, il dit une réplique (une
par visite, avec parfois un souvenir d'Ilume et du Fil) et propose 3 échanges tirés parmi ceux du palier
atteint, chacun une fois : il rachète des ouates (le surplus du filet) et parfois des vents contre du cristal
solaire, du vent, des poches d'air ou des lingots solaires. Il ne donne jamais de minerai de l'abysse ni ce qui
en est fait : aucun échange ne remplace une plongée. Aucun n'est obligatoire et rien n'est perdu si on le manque.

## Machines

Les machines (`data/machines.json`) produisent seules, jusqu'à leur réserve, y compris pendant les plongées
et jeu fermé ; un clic vide la réserve. Chacune se pose sur un emplacement : 2 sur l'île, 1 sur l'îlot de
l'est (passerelle de nuage), 2 sur l'îlot du nord (pont suspendu), 2 sur l'îlot du couchant (arche de braise :
3 pierres de braise, 4 lingots solaires, 100 vents, donc un entrepôt) ; la foreuse se pose sur un des 3 filons,
qui ne se récolte alors plus à la main. Une même machine peut être construite plusieurs fois.

Les machines sont rangées par paliers : le palier 2 s'ouvre au premier corail rapporté d'une plongée, le
palier 3 à la première pierre de braise.

| Machine | Palier | Production | Coût |
|---|---|---|---|
| Moulin à vent | 1 | 1 vent toutes les 10 s, réserve de 8 | 2 fils de nuage, 3 cristaux de lagon, 2 cristaux solaires |
| Filet à nuages | 1 | 1 ouate toutes les 6 s, réserve de 10 | 3 fils de nuage, 2 cristaux de lagon |
| Foreuse solaire | 2 | sur un filon : 1 cristal solaire toutes les 15 s, réserve de 6 | 1 lentille, 4 coraux, 4 cristaux solaires |
| Entrepôt | 3 | l'inventaire garde jusqu'à 199 de chaque ressource (au lieu de 99) ; 499 une fois amélioré (3 lingots, 3 verres) | 5 coraux, 4 fils de nuage, 4 cristaux de lagon |
| Fourneau | 3 | fabrique en boucle le raffiné choisi, 1 toutes les 15 s, avec les ingrédients de l'inventaire (réserve de 5) ; un deuxième fourneau fait un autre raffiné en même temps | 3 pierres de braise, 3 coraux, 6 cristaux solaires |
| Sonde de plongée | 3 | pendant les plongées seulement : 1 cristal de lagon toutes les 12 s, réserve de 8 | 2 pierres de braise, 2 poches d'air, 1 lentille |

Raffinés du fourneau (tous attisés au vent) : **verre de lagon** (2 cristaux de lagon, 6 vents), **nacre**
(1 corail, 8 ouates, 2 vents), **lingot solaire** (5 cristaux solaires, 5 vents). Ils servent à l'arche de braise,
au sac à 16 places (3 nacres, 3 verres), à l'entrepôt à 499 et aux améliorations de niveau 2.

Améliorations (dès le palier 2, pour toutes les machines d'une même sorte) : **Vitesse** (production ×1,5,
puis ×2) et **Réserve** (×2, puis ×3) ; le niveau 1 se paie en ressources du palier de la machine, le niveau 2
en raffinés. Le sac de plongée passe de 8 à 12 places
(atelier, onglet Améliorations : 4 coraux, 2 poches d'air).

## Sauvegarde

La partie est sauvegardée automatiquement dans un fichier JSON :

- Windows : `%APPDATA%\Le Fil de l'Abysse\sauvegarde.json`
- Linux : `~/.local/share/Le Fil de l'Abysse/sauvegarde.json`

Moments de sauvegarde : départ en plongée, retour sur l'île, fabrication ou installation à l'atelier,
fermeture de la fenêtre, Retour au titre et Quitter depuis le menu pause. Fermer le jeu en pleine plongée
garde l'état du départ (le butin en cours est perdu, rien d'autre). Au chargement, les sources de l'île
rattrapent le temps passé jeu fermé, sans dépasser leurs plafonds.

Le fichier contient : version du format, date, inventaire, niveaux des améliorations, îlots reliés,
machines construites (emplacement et type), améliorations des machines, palier atteint, recette de chaque
fourneau, carnet (trouvailles, machines vues, trouvaille pas encore regardée), marchand de vent (prochain
passage, échanges proposés et faits), état des sources de
l'île et des machines (réserve). À côté : `sauvegarde.bak` (sauvegarde précédente, reprise si le fichier est
abîmé) et, au besoin, `sauvegarde.corrompue.json` (fichier illisible mis de côté, jamais supprimé).
Une sauvegarde d'une version plus récente du jeu n'est jamais écrasée.

## Son

Tout le son est synthétisé en code au démarrage (`scripts/synthe.gd`, environ une demi-seconde), sans aucun
fichier audio, et joué par l'autoload `Son` (`scripts/autoload/son.gd`) :

- **Ambiances** en boucles de 8 s sans couture : nappe lumineuse sur l'île ; drones graves et étouffés en
  plongée, de plus en plus sombres (Lagon, Forêt de coraux, Faille volcanique avec un lent battement) ;
  fondu enchaîné de 2,5 s pendant les transitions et de 3 s au changement de zone.
- **Effets** : récolte (nuage, vent, cristal, bassin, machine, foreuse, fourneau, sonde), trouvaille, corne du
  marchand de vent et échange, coups de minage et unité gagnée, sac plein, bips
  d'oxygène bas, craquements de la coque au bout du câble, remontée automatique, fabrication, installation,
  construction, clics d'interface, souffle des transitions.
- **Mixage** : bus « Musique » et « Effets » (limiteur sur le bus principal), niveau propre à chaque effet,
  délai minimal avant de rejouer le même son et légère variation de hauteur, pour ne pas lasser.
- **Volumes** : menu pause (Échap), « Musique » et « Effets » de 0 à 100 % par pas de 10 % (70 % et 80 %
  par défaut), enregistrés dans la sauvegarde.

## Tests

Tests de logique (sans fenêtre), avec PASS/FAIL pour chaque point et un total :

```
godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
```

ou `tests/lancer.sh` (variable `GODOT=/chemin/vers/godot` si `godot` n'est pas dans le PATH), qui vérifie aussi
que le miroir Python est à jour (voir plus bas).
Code de sortie 0 si tout passe, 1 sinon. Durée : quelques secondes.

Captures d'écran automatiques (Xvfb + rendu logiciel Mesa), enregistrées dans `docs/captures/` (01-05 : plongée, 06-13 : île et transitions) :

```
tests/captures.sh
```

Playtest robot (une partie complète jouée au clavier et à la souris, mesures et vidéo, voir `docs/playtest.md`) :

```
tests/playtest.sh 4 --video
```

## Rendu pixel art

- Interface en 640x360, affichée en 1280x720 (zoom entier, sans filtrage).
- Monde (île, transition, plongée) dessiné en 320x180 dans un rendu séparé (`scripts/vue_monde.gd`), affiché ×2 sous l'interface : tous les pixels du monde ont la même taille. La logique du jeu garde ses positions en 640x360. Dessin : `scripts/art_ile.gd` (monde du haut), `scripts/art_abysse.gd` (plongée).
- Fluidité : les objets du monde avancent par pas d'un pixel entier à cadence fixe (physique à 60 Hz). La caméra de la plongée est lissée et décale toute l'image du monde d'un pixel d'écran à la fois, sans déformer les pixels.
- Raccords : l'île, la transition et la plongée partagent la même colonne de ciel, et la transition dessine le décor de la plongée elle-même sous la surface.
- Palette de 63 couleurs dans `data/palette.json` : une rampe de 4 à 6 tons par matière (ciel, nuage, roche, terre, herbe, or, lagon, corail, abysse, cyan, interface, métal), ombres vers le bleu-vert, lumières vers le jaune. Couleurs nommées « rampe.indice » (classe `Palette`) ; les anciens noms restent en alias le temps de convertir la plongée et la transition.
- Pas de transparence partielle ; contours brun foncé (monde du haut) ou bleu nuit (abysse), jamais noirs ; ombres portées pleines d'un ton plus sombre.
- Formes au pixel près : textures générées en code (`scripts/pixel.gd`, `scripts/art_ile.gd`), positions arrondies au pixel entier.
- `tests/captures.sh` vérifie que chaque capture n'utilise que des couleurs de la palette, que les pixels du monde font tous 2x2 pixels d'écran (en tenant compte du décalage de la caméra), et que les raccords île → transition → plongée sont identiques au pixel près.

## Police et licence

Police **DotGothic16** (Fontworks, https://github.com/fontworks-fonts/DotGothic16), sous licence
**SIL Open Font License 1.1** : texte complet dans `assets/fonts/OFL-DotGothic16.txt`.
Elle est utilisée à sa taille native (16 px), sans antialiasing, pour l'interface en 640x360.

## Structure

- `scenes/`, `scripts/` : scènes et code (`jeu.tscn` = scène principale, `scripts/autoload/game.gd` = contrôles et inventaire)
- `assets/` : sprites, audio, polices (`assets/fonts/` : DotGothic16 et sa licence)
- `data/` : données de jeu
- `tests/` : tests de logique et captures d'écran
- `docs/captures/` : captures générées par `tests/captures.sh` (dossier ignoré par Godot grâce à `docs/.gdignore`)
- `docs/miroir/` et `docs/architecture.md` : générés par `python3 tests/generer_miroir.py`. Le miroir est un fichier `.py` par
  script (classes, fonctions, signaux, constantes et appels, internes comme entre scripts, sans la logique) pour les outils d'analyse
  qui ne lisent pas le GDScript, comme Graphify ; l'architecture liste les scripts, leur rôle et leurs dépendances.
- `builds/` : exports (ignorés par git)
