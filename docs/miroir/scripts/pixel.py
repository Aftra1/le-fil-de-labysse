# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/pixel.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Outils de dessin « pixel art » : tout est dessiné au pixel entier, sans antialiasing.
Les petites formes (cloche, cristaux, nuages, cercles, jauges, trames) sont des textures
générées en code (Image) à la taille native, mises en cache, affichées sans filtrage.
Les nœuds qui dessinent des trames doivent avoir texture_repeat activé (voir activer_motifs).
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.palette import Palette


class Pixel(RefCounted):
    PAS_BANDE = 4
    TAILLE_TEXTE = 16
    BAYER = ...
    _textures: 'Dictionary'

    @staticmethod
    def vider_cache() -> 'void':
        ...

    @staticmethod
    def activer_motifs(noeud: 'CanvasItem') -> 'void':
        """À appeler dans _ready des nœuds qui dessinent des trames ou des motifs répétés."""
        ...

    @staticmethod
    def rect(toile: 'CanvasItem', zone: 'Rect2', couleur: 'Color') -> 'void':
        ...

    @staticmethod
    def cadre(toile: 'CanvasItem', zone: 'Rect2', couleur: 'Color') -> 'void':
        """Cadre de 1 px à l'intérieur de la zone."""
        ...

    @staticmethod
    def ligne(toile: 'CanvasItem', debut: 'Vector2', fin: 'Vector2', couleur: 'Color') -> 'void':
        """Ligne de 1 px (algorithme de Bresenham)."""
        ...

    @staticmethod
    def sprite(toile: 'CanvasItem', texture: 'Texture2D', centre: 'Vector2') -> 'void':
        """Dessine une texture centrée, coin haut-gauche arrondi au pixel."""
        ...

    @staticmethod
    def bandes(toile: 'CanvasItem', x: 'float', largeur: 'float', y_haut: 'float', y_bas: 'float', decalage: 'int', palier: 'Callable') -> 'void':
        """Dégradé vertical en paliers nets. Chaque changement de palier passe par trois bandes tramées
        (Bayer 25 %, 50 %, 75 %) au lieu d'un fondu lisse.
        palier : Callable(y_monde: float) -> Color ; decalage : y_monde = y_ecran + decalage (entier)."""
        Pixel.trame(...)

    @staticmethod
    def texte(etiquette: 'Label', couleur: 'String', ombre: 'String') -> 'void':
        """Style commun des textes : police pixel (thème du projet), couleur et ombre portée de 1 px."""
        Palette.couleur(...)

    @staticmethod
    def motif(lignes: 'PackedStringArray', couleurs: 'Dictionary', contour: 'String') -> 'ImageTexture':
        """Texture à partir d'un dessin en caractères : chaque caractère renvoie à un nom de la palette,
        « . » est transparent. contour : nom d'une couleur pour un contour de 1 px tout autour (l'image
        grandit alors de 2 px), vide pour aucun."""
        Palette.couleur(...)
        Pixel.contourner(...)
        Pixel._memoriser(...)

    @staticmethod
    def contourner(image: 'Image', couleur: 'Color') -> 'Image':
        """Ajoute un contour de 1 px (voisins haut, bas, gauche, droite) autour des pixels opaques."""
        ...

    @staticmethod
    def silhouette(texture: 'Texture2D', couleur: 'Color') -> 'ImageTexture':
        """Silhouette pleine d'une texture (pour les ombres portées d'un ton plus sombre)."""
        Pixel._memoriser(...)

    @staticmethod
    def sprite_ombre(toile: 'CanvasItem', texture: 'Texture2D', centre: 'Vector2', ombre: 'Color', decalage: 'Vector2') -> 'void':
        """Sprite avec ombre portée : la silhouette d'abord, décalée, puis le sprite."""
        Pixel.sprite(...)
        Pixel.silhouette(...)

    @staticmethod
    def disque(rayon: 'int', couleur: 'Color') -> 'ImageTexture':
        Pixel._image_carree(...)
        Pixel._memoriser(...)

    @staticmethod
    def anneau(rayon: 'int', couleur: 'Color', pointille: 'bool') -> 'ImageTexture':
        """Anneau de 1 px ; pointille : un pixel sur deux (effet de halo tramé)."""
        Pixel._image_carree(...)
        Pixel._memoriser(...)

    @staticmethod
    def jauge(rayon: 'int', progression: 'float', couleur: 'Color') -> 'ImageTexture':
        """Jauge circulaire de 2 px d'épaisseur, remplie dans le sens horaire depuis le haut (24 crans)."""
        Pixel._image_carree(...)
        Pixel._memoriser(...)

    @staticmethod
    def damier(a: 'Color', b: 'Color') -> 'ImageTexture':
        """Damier 2x2 de deux couleurs (trame à 50 %)."""
        Pixel._memoriser(...)

    @staticmethod
    def trame(niveau: 'int', couleur: 'Color') -> 'ImageTexture':
        """Trame ordonnée (Bayer 4x4) : niveau 0 = transparent, 16 = plein."""
        Pixel._memoriser(...)

    @staticmethod
    def nuage(largeur: 'int', hauteur: 'int', couleur: 'Color', ombre: 'Color') -> 'ImageTexture':
        """Nuage arrondi (trois bosses), ombré en bas."""
        Pixel._memoriser(...)

    @staticmethod
    def _image_carree(rayon: 'int') -> 'Image':
        ...

    @staticmethod
    def _memoriser(cle: 'String', image: 'Image') -> 'ImageTexture':
        ...
