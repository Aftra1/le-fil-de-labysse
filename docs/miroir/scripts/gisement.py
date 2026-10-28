# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/gisement.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Un gisement de minerai : un petit sprite de cristaux, un stock limité et une jauge de minage.
Il ne se dessine pas lui-même : la plongée appelle dessiner_monde() dans le monde 320x180.
"""

from __future__ import annotations

from ..godot import Node2D
from ..scripts.art_abysse import ArtAbysse
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel
from ..scripts.vue_monde import VueMonde


class Gisement(Node2D):
    RAYON = 7.0
    RAYON_ANNEAU = 12
    CRISTAL = ...
    CORAIL = ...
    minerai: 'String'
    couleur: 'Color'
    duree_minage: 'float'
    stock: 'int'
    progres: 'float'
    en_evidence: 'bool'
    grise: 'bool'

    def configurer(self, id_minerai: 'String', teinte: 'Color', duree: 'float', stock_initial: 'int') -> 'void':
        ...

    def retirer_unite(self) -> 'void':
        """Retire une unité ; le gisement disparaît quand il est épuisé."""
        ...

    def dessiner_monde(self, toile: 'CanvasItem') -> 'void':
        """Dessin dans le monde 320x180 (appelé par la plongée) : sprite avec contour bleu nuit et ombre
    d'un ton plus sombre que l'eau, stock en points, anneau et jauge en lueur cyan."""
        VueMonde.vers_monde(...)
        Pixel.sprite_ombre(...)
        Palette.couleur(...)
        Pixel.sprite(...)
