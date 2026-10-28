# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/palette.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Palette fixe du jeu (data/palette.json) : toutes les couleurs affichées en viennent.
Elle est organisée en rampes, une par matière (ciel, nuage, roche, herbe, or…), du plus sombre
au plus clair : les ombres tirent vers le bleu-vert, les lumières vers le jaune.
Une couleur se nomme « rampe.indice » (ex. « herbe.4 ») ou par un alias (ex. « contour_haut »).
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.donnees import Donnees


class Palette(RefCounted):
    CHEMIN = "res://data/palette.json"
    _couleurs: 'Dictionary'
    _rampes: 'Dictionary'
    _position: 'Dictionary'
    _entrees: 'Array'

    @staticmethod
    def couleur(nom: 'String') -> 'Color':
        ...

    @staticmethod
    def rampe(nom: 'String') -> 'Array':
        """Tons d'une rampe, du plus sombre au plus clair."""
        ...

    @staticmethod
    def noms() -> 'Array':
        """Noms de toutes les couleurs (une par entrée de rampe, sans les alias)."""
        ...

    @staticmethod
    def contient(nom: 'String') -> 'bool':
        ...

    @staticmethod
    def plus_sombre(teinte: 'Color', crans: 'int') -> 'Color':
        """Le ton juste en dessous dans la même rampe (ombre portée « un ton plus sombre »)."""
        ...

    @staticmethod
    def plus_clair(teinte: 'Color', crans: 'int') -> 'Color':
        """Le ton juste au-dessus dans la même rampe (reflets, repères)."""
        ...

    @staticmethod
    def _charger() -> 'void':
        Donnees.charger_json(...)
