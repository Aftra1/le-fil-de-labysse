# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/autoload/game.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Autoload « Game » : point central du jeu.
Déclare toutes les actions d'entrée en code, avec des touches PHYSIQUES
(physical_keycode) : la touche A du clavier QWERTY correspond au Q de l'AZERTY,
donc ZQSD fonctionne tel quel en AZERTY.
Garde aussi l'inventaire, la liste des ressources (data/ressources.json) et l'atelier
(composants fabriqués, niveaux des améliorations de la cloche).
"""

from __future__ import annotations

from ...godot import Node
from ...scripts.art_abysse import ArtAbysse
from ...scripts.art_ile import ArtIle
from ...scripts.atelier import Atelier
from ...scripts.donnees import Donnees
from ...scripts.inventaire import Inventaire
from ...scripts.palette import Palette
from ...scripts.pixel import Pixel


class Game(Node):
    ressources: 'Dictionary'
    inventaire: Inventaire
    atelier: Atelier

    def _ready(self) -> 'void':
        self._declarer_actions(...)
        Donnees.charger_json(...)

    def ids(self, categorie: 'String') -> 'Array':
        """Identifiants d'une catégorie (« ressource » ou « composant »), dans l'ordre d'affichage."""
        ...

    def _exit_tree(self) -> 'void':
        """Vide les caches de textures générées avant la fermeture (évite les avertissements de fuite)."""
        ArtIle.vider_cache(...)
        ArtAbysse.vider_cache(...)
        Pixel.vider_cache(...)

    def nom_ressource(self, id: 'String') -> 'String':
        ...

    def couleur_ressource(self, id: 'String') -> 'Color':
        Palette.couleur(...)

    def _declarer_actions(self) -> 'void':
        self._ajouter_action(...)

    def _ajouter_action(self, nom: 'StringName', touches: 'Array[Key]') -> 'void':
        ...
