# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/hud.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Interface de plongée (640x360) : oxygène, profondeur, zone, sac, annonces et messages.
Cadres en métal sombre avec une lueur cyan (ArtAbysse.cadre), texte cyan clair.
glisser() fait entrer ou sortir les panneaux par les bords de l'écran (transitions), au pixel près.
"""

from __future__ import annotations

from ..godot import CanvasLayer
from ..scripts.art_abysse import ArtAbysse
from ..scripts.art_ile import ArtIle
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel


class Interface(CanvasLayer):
    MARGE = 6.0
    TAILLE_BARRE = ...
    SEUIL_OXYGENE_BAS = 0.25
    DUREE_ANNONCE = 4.0
    COULEUR_TEXTE = "cyan.3"
    _taille_barre: 'Vector2'
    _barre_conteneur: 'Control'
    _barre_bord: 'ColorRect'
    _barre_fond: 'ColorRect'
    _remplissage: 'ColorRect'
    _reflet: 'ColorRect'
    _etat: 'PanelContainer'
    _profondeur: 'Label'
    _zone: 'Label'
    _sac: 'Label'
    _annonce_panneau: 'PanelContainer'
    _annonce: 'Label'
    _message_panneau: 'PanelContainer'
    _message: 'Label'
    _annonce_restante: 'float'
    _glissement: 'float'
    _bases: 'Dictionary'

    def _ready(self) -> 'void':
        self._panneau(...)
        self._etiquette(...)
        self._barre(...)
        ArtIle.ancrer(...)

    def _process(self, delta: 'float') -> 'void':
        ...

    def mettre_a_jour(self, ratio_oxygene: 'float', profondeur_m: 'float', nom_zone: 'String', message_bas: 'String') -> 'void':
        Palette.couleur(...)

    def glisser(self, progression: 'float') -> 'void':
        """progression : 0 = panneaux hors de l'écran, 1 = en place. Chacun sort par son bord le plus proche :
        l'état par la gauche, l'annonce par le haut, le message par le bas. Pas de transparence."""
        self._decaler(...)

    def progression_glissement(self) -> 'float':
        ...

    def decalage_panneau_etat(self) -> 'Vector2':
        """Décalage du panneau par rapport à sa place (pixels d'écran)."""
        ...

    def _decaler(self, panneau: 'PanelContainer', decalage: 'Vector2') -> 'void':
        ...

    def regler_reserve(self, facteur: 'float') -> 'void':
        """Longueur de la jauge d'oxygène proportionnelle à la réserve (1 = réserve de base)."""
        ...

    def largeur_jauge(self) -> 'float':
        ...

    def definir_sac(self, texte: 'String') -> 'void':
        ...

    def annoncer(self, texte: 'String', duree: 'float') -> 'void':
        ...

    def _barre(self) -> 'Control':
        """Jauge d'oxygène : fond noir, remplissage cyan (violet lumineux quand il reste peu d'air)."""
        Palette.couleur(...)

    def _panneau(self) -> 'PanelContainer':
        """Panneau d'information : il ne capte pas la souris."""
        ArtAbysse.cadre(...)

    def _etiquette(self, texte: 'String') -> 'Label':
        Pixel.texte(...)
