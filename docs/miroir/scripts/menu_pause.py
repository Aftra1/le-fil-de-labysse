# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/menu_pause.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Menu pause (Échap sur l'île ou en plongée) : le jeu est figé tant qu'il est ouvert.
Reprendre (ou Échap), Retour au titre et Quitter sauvegardent sur l'île ; en plongée,
le butin en cours est abandonné (la sauvegarde du départ fait foi), ce que le menu rappelle.
Deux réglages de volume (musique, effets), par pas de 10 %, appliqués tout de suite ; ils sont
enregistrés avec la partie (signal volumes_modifies).
"""

from __future__ import annotations

from ..godot import Signal
from ..scripts.autoload.son import Son
from ..scripts.menu_cadre import MenuCadre
from ..scripts.palette import Palette


class MenuPause(MenuCadre):
    LARGEUR_NOM = 72.0
    LARGEUR_VALEUR = 52.0
    PAS_VOLUME = 0.1
    reprendre = Signal('')
    retour_titre = Signal('')
    quitter = Signal('')
    volumes_modifies = Signal('')
    bouton_reprendre: 'Button'
    bouton_titre: 'Button'
    bouton_quitter: 'Button'
    boutons_volume: 'Dictionary'
    _valeurs: 'Dictionary'
    _note: 'Label'

    def _construire(self) -> 'void':
        MenuCadre._etiquette(self, ...)
        MenuCadre._bouton(self, ...)
        self.reprendre.emit(...)
        self.retour_titre.emit(...)
        self.quitter.emit(...)
        self._ligne_volume(...)

    def ouvrir(self, en_plongee: 'bool') -> 'void':
        """en_plongee : rappelle que quitter la plongée abandonne son butin."""
        Palette.couleur(...)
        self._afficher_volumes(...)
        MenuCadre._recentrer(self, ...)

    def note(self) -> 'String':
        ...

    def changer_volume(self, canal: 'String', sens: 'int') -> 'void':
        """Monte ou baisse un volume d'un pas (« musique » ou « effets »)."""
        Son.regler_volumes(...)
        self._afficher_volumes(...)
        self.volumes_modifies.emit(...)

    def _ligne_volume(self, canal: 'String') -> 'HBoxContainer':
        MenuCadre._etiquette(self, ...)
        self._petit_bouton(...)
        self.changer_volume  # passée comme Callable

    def _petit_bouton(self, texte: 'String', action: 'Callable') -> 'Button':
        MenuCadre._bouton(self, ...)

    def _afficher_volumes(self) -> 'void':
        ...

    def _unhandled_input(self, evenement: 'InputEvent') -> 'void':
        self.reprendre.emit(...)
