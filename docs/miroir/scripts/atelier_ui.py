# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/atelier_ui.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Interface de l'atelier (640x360) : panneau opaque en cadres or et crème.
En haut, trois onglets (composants, améliorations, construction) ; à gauche, la liste des recettes ;
à droite, le détail de la recette choisie : ingrédients « possédé / requis », effet, bouton
Fabriquer, Installer ou Construire.
S'ouvre et se ferme avec C ou un clic sur la cabane ; Échap ou un clic à côté le ferme.
"""

from __future__ import annotations

from ..godot import CanvasLayer, Signal
from ..scripts.art_ile import ArtIle
from ..scripts.atelier import Atelier
from ..scripts.autoload.game import Game
from ..scripts.inventaire import Inventaire
from ..scripts.pixel import Pixel


class PanneauAtelier(CanvasLayer):
    LARGEUR_LISTE = 196.0
    LARGEUR_DETAIL = 300.0
    HAUTEUR_DETAIL = 196.0
    ECART = 4
    COULEUR_TEXTE = "contour_haut"
    COULEUR_MANQUE = "corail.2"
    ONGLETS = ...
    fabrique = Signal('id: String, genre: String')
    onglet: 'String'
    selection: 'String'
    _liste: 'VBoxContainer'
    _onglets: 'Dictionary'
    _titre: 'Label'
    _effet: 'Label'
    _ingredients: 'VBoxContainer'
    _bouton: 'Button'
    _groupe: 'ButtonGroup'

    def _ready(self) -> 'void':
        ArtIle.styler_bouton(...)
        ArtIle.ancrer(...)

    def est_ouvert(self) -> 'bool':
        ...

    def ouvrir(self) -> 'void':
        ...

    def fermer(self) -> 'void':
        ...

    def basculer(self) -> 'void':
        ...

    def choisir_onglet(self, nom: 'String') -> 'void':
        Atelier.composants(...)

    def selectionner(self, id: 'String') -> 'void':
        ...

    def fabriquer_selection(self) -> 'bool':
        """Fabrique, installe ou construit la recette sélectionnée, si c'est possible."""
        Atelier.ameliorer(...)
        Atelier.construire(...)
        Atelier.fabriquer(...)

    def peut_fabriquer_selection(self) -> 'bool':
        Atelier.peut_ameliorer(...)
        Atelier.peut_construire(...)
        Atelier.peut_fabriquer(...)

    def rafraichir(self) -> 'void':
        Atelier.prochain_niveau(...)
        Atelier.est_construite(...)
        Atelier.effet_construction(...)
        Atelier.ingredients_composant(...)

    def _remplir_liste(self, ids: 'Array') -> 'void':
        ArtIle.styler_bouton(...)
        ArtIle.icone_amelioration(...)
        ArtIle.icone_construction(...)
        ArtIle.icone(...)

    def _libelle(self, id: 'String') -> 'String':
        Atelier.nom_amelioration(...)
        Atelier.niveau(...)
        Atelier.niveau_max(...)
        Atelier.nom_construction(...)
        Game.nom_ressource(...)

    def _ligne_ingredient(self, id: 'String', requis: 'int') -> 'HBoxContainer':
        ArtIle.icone(...)
        Inventaire.quantite(...)

    def _sur_clic_a_cote(self, evenement: 'InputEvent') -> 'void':
        ...

    def _etiquette(self, texte: 'String', couleur: 'String') -> 'Label':
        Pixel.texte(...)
