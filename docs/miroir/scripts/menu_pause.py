# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/menu_pause.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Menu pause (Échap sur l'île ou en plongée) : le jeu est figé tant qu'il est ouvert.
Reprendre (ou Échap), Retour au titre et Quitter sauvegardent sur l'île ; en plongée,
le butin en cours est abandonné (la sauvegarde du départ fait foi), ce que le menu rappelle.
"""

from __future__ import annotations

from ..godot import Signal
from ..scripts.menu_cadre import MenuCadre
from ..scripts.palette import Palette


class MenuPause(MenuCadre):
    reprendre = Signal('')
    retour_titre = Signal('')
    quitter = Signal('')
    bouton_reprendre: 'Button'
    bouton_titre: 'Button'
    bouton_quitter: 'Button'
    _note: 'Label'

    def _construire(self) -> 'void':
        MenuCadre._bouton(self, ...)
        MenuCadre._etiquette(self, ...)

    def ouvrir(self, en_plongee: 'bool') -> 'void':
        """en_plongee : rappelle que quitter la plongée abandonne son butin."""
        MenuCadre._recentrer(self, ...)

    def note(self) -> 'String':
        ...

    def _unhandled_input(self, evenement: 'InputEvent') -> 'void':
        ...
