# Le Fil de l'Abysse

Jeu PC (Windows) en 2D pixel art, fait avec Godot 4.7.1 (GDScript, rendu GL Compatibility).
Tu gardes une île flottante au-dessus d'un océan sans fond, et tu plonges dans une cloche reliée par un câble.

## Lancer le projet

1. Télécharge **Godot 4.7.1** (version standard, pas .NET) sur <https://godotengine.org/download/>.
2. Lance Godot, clique sur **Importer**, puis choisis le fichier `project.godot` de ce dépôt.
3. Appuie sur **F5** (ou le bouton ▶) pour lancer le jeu.

En ligne de commande : `godot --path .` (ou `godot --headless --path . --quit-after 5` pour un test sans fenêtre).

## Contrôles

| Action | Touches |
|---|---|
| Se déplacer | ZQSD (AZERTY) / WASD / flèches |
| Miner (maintenir près d'un gisement) | E ou Espace |
| Quitter | Échap |

Les touches sont physiques : ZQSD fonctionne sur un clavier AZERTY.

## Tests

Tests de logique (sans fenêtre), avec PASS/FAIL pour chaque point et un total :

```
godot --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
```

ou `tests/lancer.sh` (variable `GODOT=/chemin/vers/godot` si `godot` n'est pas dans le PATH).
Code de sortie 0 si tout passe, 1 sinon. Durée : quelques secondes.

Captures d'écran automatiques (Xvfb + rendu logiciel Mesa), enregistrées dans `docs/captures/` :

```
tests/captures.sh
```

## Structure

- `scenes/`, `scripts/` : scènes et code (`scripts/autoload/game.gd` = contrôles centralisés)
- `assets/` : sprites, audio, polices
- `data/` : données de jeu
- `tests/` : tests de logique et captures d'écran
- `docs/captures/` : captures générées par `tests/captures.sh`
- `builds/` : exports (ignorés par git)
