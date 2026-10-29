# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/art_trouvailles.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Pixel art des trouvailles rares (carnet, annonces) et de leur éclat en plongée.
Chaque trouvaille est un motif de 10 pixels de large (lettres = couleurs de la palette, voir COULEURS),
avec un contour sombre. En plongée, on ne voit qu'un éclat scintillant de la couleur lumineuse de la
zone (cyan, corail, or : jamais assombrie par l'obscurité) ; la trouvaille se révèle quand on la ramasse.
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel


class ArtTrouvailles(RefCounted):
    COULEURS = ...
    CONTOUR = "abysse.1"
    LUEURS = ...
    MOTIFS = ...

    @staticmethod
    def icone(id: 'String', decouverte: 'bool') -> 'Texture2D':
        """Image de la trouvaille (carnet, annonce). Inconnue : la silhouette sombre du même motif."""
        Pixel.disque(...)
        Palette.couleur(...)
        Pixel.motif(...)

    @staticmethod
    def dessiner_eclat(toile: 'CanvasItem', centre: 'Vector2', zone: 'String', phase: 'int') -> 'void':
        """Éclat d'une trouvaille en plongée : une étoile à quatre branches qui scintille (phase 0 à 3)."""
        Palette.couleur(...)
