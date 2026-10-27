# CLAUDE.md — Le Fil de l'Abysse

## Méthode
- Petites itérations, une tâche à la fois.
- Annoncer le plan avant de coder.
- Après chaque tâche : résumer et dire comment tester.
- Ne jamais passer à l'étape suivante sans l'accord de l'utilisateur.
- Prototype avec des formes simples ; le pixel art viendra plus tard.
- Git : pour chaque étape, créer une branche depuis `main`, travailler dessus, ouvrir une Pull Request vers `main`, et ne jamais la fusionner sans l'accord de l'utilisateur.
- À chaque fin d'étape : lancer tous les tests (anciens et nouveaux), mettre à jour les captures, mettre les résultats et les images dans la PR. Les tests sont dans `tests/`, jamais hors du dépôt.

## Technique
- Godot 4.7, GDScript typé, cible Windows.
- Contrôles centralisés dans `scripts/autoload/game.gd` (touches physiques, ZQSD OK en AZERTY).
- Sauvegarde locale en JSON dans `user://`.
- Audio généré en code.
- Jeu et commentaires en français.
- Données de jeu dans `data/`.

## À éviter
- Grind punitif.
- Timers frustrants.
- Game over brutal.
- Interface surchargée.

## Concept
Gardien d'une île flottante au-dessus d'un océan sans fond.
- **En haut** (cosy, lumineux) : on récolte vent, nuages et cristaux, et on fabrique.
- **En bas** (mystérieux) : on plonge dans une cloche reliée par un câble, on mine, on gère oxygène et lumière.
- Une plongée ratée fait perdre une partie du butin, sans game over.

**Zones** : Lagon de lumière, Forêt de coraux, Faille volcanique, Le Fond.

**Personnages** : le gardien, un marchand de vent en dirigeable, une créature bioluminescente ambiguë.

**Palette haut** : bleu ciel, blanc nacré, or.
**Palette bas** : bleu nuit, noir, cyan, violet.

## Feuille de route du MVP
- [x] 0. Mise en place
- [x] 1. Prototype de plongée
- [x] 2. Minage, sac et 2 zones (Lagon de lumière, Forêt de coraux)
- [x] 3. Île avec 3 ressources et inventaire (transitions île ↔ plongée)
- [x] 3.5. Pixel art (variante C : monde en 320x180 affiché ×2, interface en 640x360, palette en rampes, police DotGothic16)
- [x] 4. Craft et 3 améliorations de cloche, planifiée en deux parties :
  - [x] Partie 1 (PR #5) : atelier, recettes, composants, améliorations de niveau 1 (câble 150 → 300 m, lanterne, réservoir)
  - [ ] Partie 2 : Faille volcanique, pierre de braise, niveaux 2 des améliorations (câble 450 m). Planifiée, pas commencée.
- [x] 5. Îlot à relier et sauvegarde, en deux parties :
  - [x] Partie 1 (PR #6) : sauvegarde JSON dans user:// (%APPDATA%\Le Fil de l'Abysse), écran titre, menu pause
  - [x] Partie 2 (PR #7) : îlot, passerelle de nuage, bassin de lumière
- [ ] 6. Test de la boucle complète sur PC (en cours), puis ajustements, pixel art et audio
