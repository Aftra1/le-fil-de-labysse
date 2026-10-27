# Le Fil de l'Abysse

Jeu PC (Windows) en 2D pixel art, fait avec Godot 4.7.1 (GDScript, rendu GL Compatibility).
Tu gardes une île flottante au-dessus d'un océan sans fond, et tu plonges dans une cloche reliée par un câble.

## Lancer le projet

1. Télécharge **Godot 4.7.1** (version standard, pas .NET) sur <https://godotengine.org/download/>.
2. Lance Godot, clique sur **Importer**, puis choisis le fichier `project.godot` de ce dépôt.
3. Appuie sur **F5** (ou le bouton ▶) pour lancer le jeu.

En ligne de commande : `godot --path .` (ou `godot --headless --path . --quit-after 5` pour un test sans fenêtre).

## Contrôles

Sur l'île (à la souris) :

| Action | Commande |
|---|---|
| Récolter un nuage | Clic sur le nuage |
| Vider l'éolienne (vent) | Clic sur l'éolienne |
| Récolter un cristal solaire | Maintenir le clic sur un filon (1 s) |
| Plonger | Clic sur la cloche, ou E / Espace |
| Inventaire | I, Tab ou le bouton « Inventaire » (Échap pour fermer) |
| Passer la transition | N'importe quelle touche ou un clic |

En plongée :

| Action | Touches |
|---|---|
| Se déplacer | ZQSD (AZERTY) / WASD / flèches |
| Miner (maintenir près d'un gisement) | E ou Espace |
| Quitter | Échap |

Les touches sont physiques : ZQSD fonctionne sur un clavier AZERTY.
La plongée se termine quand la cloche revient en surface après être descendue sous 10 m.

## Tests

Tests de logique (sans fenêtre), avec PASS/FAIL pour chaque point et un total :

```
godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
```

ou `tests/lancer.sh` (variable `GODOT=/chemin/vers/godot` si `godot` n'est pas dans le PATH).
Code de sortie 0 si tout passe, 1 sinon. Durée : quelques secondes.

Captures d'écran automatiques (Xvfb + rendu logiciel Mesa), enregistrées dans `docs/captures/` (01-05 : plongée, 06-13 : île et transitions) :

```
tests/captures.sh
```

## Rendu pixel art

- Résolution interne 640x360, affichée en 1280x720 (zoom entier, sans filtrage). Un essai 320x180 est en cours d'évaluation (voir ci-dessous).
- Palette de 63 couleurs dans `data/palette.json` : une rampe de 4 à 6 tons par matière (ciel, nuage, roche, terre, herbe, or, lagon, corail, abysse, cyan, interface, métal), ombres vers le bleu-vert, lumières vers le jaune. Couleurs nommées « rampe.indice » (classe `Palette`) ; les anciens noms restent en alias le temps de convertir la plongée et la transition.
- Pas de transparence partielle ; contours brun foncé (monde du haut) ou bleu nuit (abysse), jamais noirs ; ombres portées pleines d'un ton plus sombre.
- Formes au pixel près : textures générées en code (`scripts/pixel.gd`, `scripts/art_ile.gd`), positions arrondies au pixel entier.
- `tests/captures.sh` et `tests/essai_echelle.sh` vérifient que chaque image n'utilise que des couleurs de la palette.

Essai de taille de pixel (même vue de l'île en 640x360, 320x180 et hybride) :

```
tests/essai_echelle.sh
```

## Polices et licences

- **DotGothic16** (Fontworks, https://github.com/fontworks-fonts/DotGothic16), SIL Open Font License 1.1 :
  `assets/fonts/OFL-DotGothic16.txt`. Utilisée à 16 px, sans antialiasing.
- **Silkscreen** (Jason Kottke, https://github.com/googlefonts/silkscreen), SIL Open Font License 1.1 :
  `assets/fonts/OFL-Silkscreen.txt`. Utilisée à 8 px dans l'essai 320x180.

## Structure

- `scenes/`, `scripts/` : scènes et code (`jeu.tscn` = scène principale, `scripts/autoload/game.gd` = contrôles et inventaire)
- `assets/` : sprites, audio, polices (`assets/fonts/` : DotGothic16 et sa licence)
- `data/` : données de jeu
- `tests/` : tests de logique et captures d'écran
- `docs/captures/` : captures générées par `tests/captures.sh` (dossier ignoré par Godot grâce à `docs/.gdignore`)
- `builds/` : exports (ignorés par git)
