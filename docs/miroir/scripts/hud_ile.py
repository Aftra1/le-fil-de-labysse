# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/hud_ile.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Interface de l'île (640x360) : bouton d'inventaire, barre des ressources, annonces et aide.
Cadres épais or et crème (ArtIle.cadre), texte brun foncé en DotGothic16.
"""

from __future__ import annotations

from ..godot import CanvasLayer
from ..scripts.art_ile import ArtIle
from ..scripts.autoload.game import Game
from ..scripts.inventaire import Inventaire
from ..scripts.pixel import Pixel


class InterfaceIle(CanvasLayer):
    DUREE_ANNONCE = 4.0
    MARGE = 6.0
    HAUT_ANNONCE = 96.0
    HAUT_AIDE = 46.0
    bouton_inventaire: 'Button'
    _quantites: 'Dictionary'
    _annonce_panneau: 'PanelContainer'
    _annonce: 'Label'
    _aide_panneau: 'PanelContainer'
    _aide: 'Label'
    _annonce_restante: 'float'

    def _ready(self) -> 'void':
        ArtIle.styler_bouton(...)
        self._panneau(...)
        Game.ids(...)
        ArtIle.icone(...)
        self._etiquette(...)
        ArtIle.ancrer(...)
        self.rafraichir_inventaire(...)

    def _process(self, delta: 'float') -> 'void':
        ...

    def rafraichir_inventaire(self) -> 'void':
        Inventaire.quantite(...)

    def annoncer(self, texte: 'String', duree: 'float') -> 'void':
        ...

    def texte_annonce(self) -> 'String':
        ...

    def definir_aide(self, texte: 'String') -> 'void':
        ...

    def _panneau(self) -> 'PanelContainer':
        """Panneau d'information : il ne capte pas la souris (on peut cliquer le monde dessous)."""
        ArtIle.cadre(...)

    def _etiquette(self) -> 'Label':
        Pixel.texte(...)
