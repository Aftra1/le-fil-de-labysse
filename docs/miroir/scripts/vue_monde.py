# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/vue_monde.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Rendu du monde en 320x180, affiché ×2 sous l'interface (qui reste en 640x360).
La logique du jeu garde ses positions en 640x360 : au dessin, on les divise par 2 et on les
arrondit au pixel du monde (vers_monde), donc tous les pixels du monde ont la même taille.

Fluidité :
- un objet du monde avance toujours par pas d'un pixel entier du monde (pas de demi-pixel) ;
les objets lents avancent à cadence fixe, calée sur la physique à 60 Hz (voir SourceRessource) ;
- le défilement (caméra, transition) est lissé : l'image entière du monde peut être décalée
d'un pixel d'écran (un demi-pixel du monde) sans déformer aucun pixel. La vue est rendue avec
un pixel de marge pour couvrir ce décalage.
"""

from __future__ import annotations

from ..godot import Node2D
from ..scripts.pixel import Pixel


class VueMonde(Node2D):
    ECHELLE = 2
    TAILLE = ...
    dessiner: 'Callable'
    camera: 'Vector2'
    transparent: 'bool'
    _vue: 'SubViewport'
    _toile: 'Node2D'

    def _ready(self) -> 'void':
        Pixel.activer_motifs(...)

    def _process(self, _delta: 'float') -> 'void':
        ...

    def _draw(self) -> 'void':
        ...

    def origine_monde(self) -> 'Vector2':
        """Pixel du monde affiché en haut à gauche."""
        ...

    def decalage_ecran(self) -> 'Vector2i':
        """Décalage de l'image en pixels d'écran (0 ou 1 sur chaque axe) : les pixels du monde commencent
    à ce décalage modulo 2 (sert à la vérification des blocs 2x2)."""
        ...

    def vue_monde(self) -> 'Rect2':
        """Rectangle visible, en pixels du monde (avec la marge)."""
        ...

    def taille_monde(self) -> 'Vector2i':
        ...

    @staticmethod
    def vers_monde(point: 'Vector2') -> 'Vector2':
        """Position 640x360 -> pixel entier du monde 320x180."""
        ...
