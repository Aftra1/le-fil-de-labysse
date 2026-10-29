# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/menu_cadre.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Base des menus plein écran (écran titre, pause) : un panneau en cadre or et crème, centré ou
en haut, avec une colonne de textes et de boutons. Les menus restent actifs quand le jeu est en pause.
"""

from __future__ import annotations

from ..godot import CanvasLayer
from ..scripts.art_ile import ArtIle
from ..scripts.pixel import Pixel


class MenuCadre(CanvasLayer):
    LARGEUR_BOUTON = 168.0
    ECART = 4
    COULEUR_TEXTE = "contour_haut"
    COULEUR_MESSAGE = "corail.2"
    ancre_y: 'float'
    marge_y: 'float'
    _colonne: 'VBoxContainer'
    _panneau: 'PanelContainer'

    def _ready(self) -> 'void':
        ArtIle.cadre(...)
        self._construire(...)
        self._recentrer(...)

    def _construire(self) -> 'void':
        """À compléter par chaque menu : remplit _colonne."""
        ...

    def est_ouvert(self) -> 'bool':
        ...

    def fermer(self) -> 'void':
        ...

    def _bouton(self, texte: 'String', action: 'Callable') -> 'Button':
        ArtIle.styler_bouton(...)

    def _etiquette(self, texte: 'String', couleur: 'String') -> 'Label':
        Pixel.texte(...)

    def _recentrer(self) -> 'void':
        """Le panneau garde sa taille minimale quand son contenu change (textes, boutons cachés)."""
        ArtIle.ancrer(...)
