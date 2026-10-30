# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/marchand_ui.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Panneau du marchand de vent (640x360) : cadres or et crème, comme l'atelier. En haut, sa réplique du
jour ; en dessous, ses trois échanges (ce qu'on donne → ce qu'on reçoit, bouton Échanger, ou « Fait ») ;
en bas, le temps qu'il reste avant son départ. S'ouvre d'un clic sur son dirigeable ; Échap ou un clic
à côté le ferme. Il se ferme seul quand le marchand repart.
"""

from __future__ import annotations

from ..godot import CanvasLayer, Signal
from ..scripts.art_ile import ArtIle
from ..scripts.autoload.game import Game
from ..scripts.inventaire import Inventaire
from ..scripts.marchand import Marchand
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel


class PanneauMarchand(CanvasLayer):
    LARGEUR = 500.0
    ECART = 4
    COULEUR_TEXTE = "contour_haut"
    COULEUR_MANQUE = "corail.2"
    COULEUR_REPLIQUE = "or.1"
    echange_fait = Signal('id: String')
    _replique: 'Label'
    _lignes: 'VBoxContainer'
    _depart: 'Label'
    _boutons: 'Dictionary'

    def _ready(self) -> 'void':
        self._sur_clic_a_cote  # passée comme Callable
        ArtIle.cadre(...)
        self._etiquette(...)
        ArtIle.ancrer(...)

    def _process(self, _delta: 'float') -> 'void':
        Marchand.est_present(...)
        self.fermer(...)
        self.rafraichir(...)

    def est_ouvert(self) -> 'bool':
        ...

    def ouvrir(self) -> 'void':
        Marchand.est_present(...)
        Marchand.replique(...)
        self._ligne(...)
        self.rafraichir(...)

    def fermer(self) -> 'void':
        ...

    def rafraichir(self) -> 'void':
        Marchand.peut_echanger(...)
        Marchand.echange(...)
        Inventaire.quantite(...)
        Palette.couleur(...)

    def echanger(self, id: 'String') -> 'bool':
        """Fait l'échange s'il est possible ; renvoie vrai s'il a eu lieu."""
        Marchand.echanger(...)
        self.echange_fait.emit(...)
        self.rafraichir(...)

    def bouton(self, id: 'String') -> 'Button':
        ...

    def _ligne(self, id: 'String') -> 'HBoxContainer':
        """Une ligne : icônes et quantités données, flèche, icônes et quantités reçues, bouton Échanger."""
        Marchand.echange(...)
        self._etiquette(...)
        self._texte(...)
        self._icones(...)
        ArtIle.styler_bouton(...)
        self.echanger  # passée comme Callable

    def _icones(self, ressources: 'Dictionary') -> 'HBoxContainer':
        ArtIle.icone(...)

    def _texte(self, ressources: 'Dictionary') -> 'String':
        """« Ouate de nuage ×12 », ou plusieurs ressources séparées par « + »."""
        Game.nom_ressource(...)

    def _sur_clic_a_cote(self, evenement: 'InputEvent') -> 'void':
        self.fermer(...)

    def _etiquette(self, texte: 'String', couleur: 'String') -> 'Label':
        Pixel.texte(...)
