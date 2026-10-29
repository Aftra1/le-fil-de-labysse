# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/carnet_ui.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Carnet de collection (640x360) : panneau opaque en cadres or et crème, comme l'atelier.
En haut, le pourcentage du carnet et quatre pages (perles, fossiles, reliques, machines) ; à gauche,
les six cases de la page (trouvailles agrandies ×3 au pixel près, silhouettes tant qu'elles ne sont pas
trouvées) ; à droite, la fiche de la case choisie et le bonus de la page.
S'ouvre et se ferme avec K ou le bouton « Carnet » ; Échap ou un clic à côté le ferme.
"""

from __future__ import annotations

from ..godot import CanvasLayer
from ..scripts.art_ile import ArtIle
from ..scripts.art_trouvailles import ArtTrouvailles
from ..scripts.atelier import Atelier
from ..scripts.autoload.game import Game
from ..scripts.carnet import Carnet
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel


class PanneauCarnet(CanvasLayer):
    ECHELLE_ICONE = 3
    TAILLE_CASE = ...
    LARGEUR_DETAIL = 280.0
    HAUTEUR_DETAIL = 160.0
    ECART = 4
    COULEUR_TEXTE = "contour_haut"
    COULEUR_BONUS = "or.1"
    ONGLETS = ...
    NOMS_ZONES = ...
    page: 'String'
    selection: 'String'
    _titre: 'Label'
    _onglets: 'Dictionary'
    _grille: 'GridContainer'
    _nom: 'Label'
    _description: 'Label'
    _bonus: 'Label'
    _groupe: 'ButtonGroup'

    def _ready(self) -> 'void':
        self._sur_clic_a_cote  # passée comme Callable
        ArtIle.cadre(...)
        self._etiquette(...)
        ArtIle.styler_bouton(...)
        self.choisir_page  # passée comme Callable
        ArtIle.ancrer(...)
        self.choisir_page(...)

    def est_ouvert(self) -> 'bool':
        ...

    def ouvrir(self) -> 'void':
        self.choisir_page(...)

    def fermer(self) -> 'void':
        ...

    def basculer(self) -> 'void':
        self.fermer(...)
        self.ouvrir(...)

    def choisir_page(self, nom: 'String') -> 'void':
        Carnet.cases(...)
        self._case(...)
        self.rafraichir(...)

    def selectionner(self, id: 'String') -> 'void':
        self.rafraichir(...)

    def rafraichir(self) -> 'void':
        Carnet.pourcentage(...)
        Carnet.est_dans_carnet(...)
        Atelier.nom_machine(...)
        Atelier.machine(...)
        Carnet.trouvaille(...)
        Carnet.page(...)
        Carnet.page_complete(...)
        Carnet.remplies(...)
        Carnet.cases(...)

    def _case(self, id: 'String') -> 'Button':
        ArtIle.styler_bouton(...)
        self.selectionner  # passée comme Callable
        Carnet.est_dans_carnet(...)
        ArtIle.icone_machine(...)
        Pixel.silhouette(...)
        Palette.couleur(...)
        ArtTrouvailles.icone(...)

    def _sur_clic_a_cote(self, evenement: 'InputEvent') -> 'void':
        self.fermer(...)

    def _etiquette(self, texte: 'String', couleur: 'String') -> 'Label':
        Pixel.texte(...)
