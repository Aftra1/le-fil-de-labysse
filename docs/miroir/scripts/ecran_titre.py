# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/ecran_titre.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Écran titre, en haut de l'écran pour laisser voir l'île figée : Continuer (grisé sans sauvegarde),
Nouvelle partie (confirmation si une partie existe déjà), Quitter. Un message discret signale une
sauvegarde abîmée, reprise ou d'une version plus récente.
"""

from __future__ import annotations

from ..godot import Signal
from ..scripts.menu_cadre import MenuCadre


class EcranTitre(MenuCadre):
    TAILLE_TITRE = 32
    continuer = Signal('')
    nouvelle_partie = Signal('')
    quitter = Signal('')
    bouton_continuer: 'Button'
    bouton_nouvelle: 'Button'
    bouton_quitter: 'Button'
    bouton_remplacer: 'Button'
    bouton_annuler: 'Button'
    _message: 'Label'
    _choix: 'HBoxContainer'
    _confirmation: 'VBoxContainer'
    _partie_existante: 'bool'

    def _construire(self) -> 'void':
        MenuCadre._etiquette(self, ...)
        MenuCadre._bouton(self, ...)

    def ouvrir(self, peut_continuer: 'bool', partie_existante: 'bool', message: 'String') -> 'void':
        """peut_continuer : une sauvegarde utilisable existe ; partie_existante : Nouvelle partie demande
    confirmation ; message : vide si tout va bien."""
        ...

    def demander_nouvelle_partie(self) -> 'void':
        ...

    def annuler_confirmation(self) -> 'void':
        ...

    def confirmation_ouverte(self) -> 'bool':
        ...

    def message(self) -> 'String':
        ...

    def _montrer_confirmation(self, montrer: 'bool') -> 'void':
        MenuCadre._recentrer(self, ...)

    def _unhandled_input(self, evenement: 'InputEvent') -> 'void':
        ...
