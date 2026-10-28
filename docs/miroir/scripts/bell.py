# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/bell.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""La cloche de plongée : déplacement avec inertie et flottabilité douce.
Les ordres viennent de dive.gd (contrôle actif ou remontée automatique).
"""

from __future__ import annotations

from ..godot import CharacterBody2D
from ..scripts.pixel import Pixel


class Cloche(CharacterBody2D):
    VITESSE_MAX = 110.0
    VITESSE_REMONTEE_AUTO = 90.0
    VITESSE_FLOTTAISON = 14.0
    ACCELERATION = 260.0
    FREINAGE = 120.0
    DEMI_LARGEUR_ZONE = 280.0
    PROFONDEUR_MAX_PX = 4500.0
    LARGEUR = 20.0
    HAUTEUR = 22.0
    MOTIF = ...
    COULEURS_MOTIF = ...
    profondeur_limite: 'float'
    controle_actif: 'bool'
    remontee_auto: 'bool'
    stabilisee: 'bool'

    def _physics_process(self, delta: 'float') -> 'void':
        ...

    def _draw(self) -> 'void':
        Cloche.dessiner(...)

    @staticmethod
    def dessiner(toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        """Dessin de la cloche, réutilisé par l'île et la transition."""
        Pixel.sprite(...)
