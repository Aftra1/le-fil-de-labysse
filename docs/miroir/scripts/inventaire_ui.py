# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/inventaire_ui.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Panneau d'inventaire opaque (cadre or et crème, pas de voile) : une case par ressource.
S'ouvre et se ferme avec I / Tab ou le bouton ; Échap ou un clic à côté le ferme.
"""

from __future__ import annotations

from ..godot import CanvasLayer
from ..scripts.art_ile import ArtIle
from ..scripts.autoload.game import Game
from ..scripts.inventaire import Inventaire
from ..scripts.pixel import Pixel


class PanneauInventaire(CanvasLayer):
    TAILLE_CASE = ...
    LARGEUR_NOM = 72.0
    ECART = 4
    _quantites: 'Dictionary'

    def _ready(self) -> 'void':
        Game.ids(...)
        ArtIle.ancrer(...)

    def _case(self, id: 'String') -> 'PanelContainer':
        ArtIle.icone(...)

    def est_ouvert(self) -> 'bool':
        ...

    def ouvrir(self) -> 'void':
        ...

    def fermer(self) -> 'void':
        ...

    def basculer(self) -> 'void':
        ...

    def rafraichir(self) -> 'void':
        Inventaire.quantite(...)

    def _sur_clic_a_cote(self, evenement: 'InputEvent') -> 'void':
        ...

    def _etiquette(self, texte: 'String') -> 'Label':
        Pixel.texte(...)
