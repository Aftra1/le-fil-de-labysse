# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/art_ile.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Pixel art du monde du haut (île, ciel, nuages, cloche, interface), généré en code.
Tout est paramétré par une échelle k : 1 pour 640x360, 0.5 pour 320x180 (essai comparatif).
Les grandes images (fond de l'île) sont peintes une fois dans une Image, puis mises en cache.
Règles : couleurs de la palette uniquement, contour brun foncé (« contour_haut »), jamais noir,
ombre portée pleine d'un ton plus sombre (Palette.plus_sombre), pas de transparence partielle.
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.art_abysse import ArtAbysse
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel


class ArtIle(RefCounted):
    CONTOUR = "contour_haut"
    GRAINE = 1407
    PALIERS_CIEL = ...
    HAUTEUR_CIEL = 900
    CRENEAUX = ...
    DENT = 3
    CLOCHE = ...
    CLOCHE_PETITE = ...
    FILON = ...
    FILON_PETIT = ...
    CORAIL = ...
    CORAIL_PETIT = ...
    VENT = ...
    VENT_PETIT = ...
    CABANE = ...
    FIL_NUAGE = ...
    LENTILLE = ...
    POCHE_AIR = ...
    ICONE_CABLE = ...
    ICONE_LANTERNE = ...
    ICONE_RESERVOIR = ...
    ICONE_PASSERELLE = ...
    ICONE_MOULIN = ...
    ICONE_FILET = ...
    COULEURS_CABANE = ...
    COULEURS_OBJETS = ...
    COULEURS_CLOCHE = ...
    LARGEUR_ILOT = 34
    HAUTEUR_ILOT = 20
    _cache: 'Dictionary'

    @staticmethod
    def vider_cache() -> 'void':
        ...

    @staticmethod
    def c(nom: 'String') -> 'Color':
        Palette.couleur(...)

    @staticmethod
    def couleurs_rampe(nom_rampe: 'String', decalage: 'int') -> 'Dictionary':
        """Associe les chiffres d'un motif aux tons d'une rampe (décalage pour éclaircir ou assombrir)."""
        Palette.rampe(...)

    @staticmethod
    def couleur_ciel_monde(y: 'float') -> 'Color':
        """Couleur du ciel à une hauteur de la colonne (sans les créneaux) : sert aux ombres des objets qui volent."""
        ArtIle.c(...)
        ArtIle._palier_ciel(...)

    @staticmethod
    def couleur_ciel_pixel(x: 'int', y: 'int') -> 'Color':
        """Couleur exacte d'un pixel du ciel (x, y en pixels du monde de la colonne), créneaux compris."""
        ArtIle._palier_ciel(...)
        ArtIle._creneau(...)
        ArtIle.c(...)

    @staticmethod
    def dessiner_ciel(toile: 'CanvasItem', zone: 'Rect2', dx: 'int', dy: 'int') -> 'void':
        """Dessine le ciel sur une toile ; un point de la toile (x, y) est le pixel (x + dx, y + dy) de la colonne."""
        ArtIle.c(...)
        ArtIle._creneau(...)

    @staticmethod
    def _palier_ciel(y: 'float') -> 'int':
        ...

    @staticmethod
    def _creneau(x: 'int') -> 'int':
        ...

    @staticmethod
    def fond_ile(k: 'float') -> 'ImageTexture':
        ArtIle.peindre_ciel(...)
        ArtIle.peindre_soleil(...)
        ArtIle.peindre_ile(...)

    @staticmethod
    def peindre_ciel(image: 'Image') -> 'void':
        ArtIle.couleur_ciel_pixel(...)

    @staticmethod
    def peindre_soleil(image: 'Image', centre: 'Vector2i', rayon: 'int') -> 'void':
        ArtIle.c(...)

    @staticmethod
    def peindre_ile(image: 'Image', k: 'float') -> 'void':
        """L'île : herbe en touffes, couche de terre, roche en pavés avec cristaux incrustés,
        contour brun, ombre portée d'un ton plus sombre sur le ciel, treuil dessous."""
        Palette.plus_sombre(...)
        ArtIle.c(...)
        Palette.rampe(...)

    @staticmethod
    def nuage(largeur: 'int', hauteur: 'int') -> 'ImageTexture':
        """Nuage en volume : lumière chaude en haut à gauche, ombre bleutée en bas, contour bleu-gris."""
        ArtIle.c(...)
        Pixel.contourner(...)

    @staticmethod
    def pales(k: 'float', angle: 'float') -> 'ImageTexture':
        """Pales de l'éolienne (voiles crème bordées de brun), pour un angle donné (12 images par tiers de tour)."""
        ArtIle.c(...)
        Pixel.contourner(...)

    @staticmethod
    def cloche(k: 'float', contour: 'String') -> 'ImageTexture':
        Pixel.motif(...)

    @staticmethod
    def filon(k: 'float', plein: 'bool') -> 'ImageTexture':
        Pixel.motif(...)
        ArtIle.couleurs_rampe(...)

    @staticmethod
    def cabane(allumee: 'bool') -> 'ImageTexture':
        """Cabane de l'atelier (monde 320x180) ; fenêtre allumée quand une fabrication est possible."""
        Pixel.motif(...)

    @staticmethod
    def ilot(relie: 'bool') -> 'ImageTexture':
        ArtIle.c(...)
        Pixel.contourner(...)
        Palette.plus_sombre(...)

    @staticmethod
    def icone_construction(_id: 'String') -> 'Texture2D':
        """Icône d'une construction (atelier)."""
        Pixel.motif(...)

    @staticmethod
    def icone_machine(id: 'String') -> 'Texture2D':
        """Icône d'une machine de l'île (atelier, onglet Machines)."""
        Pixel.motif(...)
        Pixel.disque(...)
        ArtIle.c(...)

    @staticmethod
    def icone_amelioration(id: 'String') -> 'Texture2D':
        """Icône d'une amélioration de la cloche (atelier)."""
        Pixel.motif(...)
        Pixel.disque(...)
        ArtIle.c(...)

    @staticmethod
    def icone(id: 'String', k: 'float') -> 'Texture2D':
        """Icône d'une ressource (inventaire, barre de ressources)."""
        Pixel.motif(...)
        ArtIle.couleurs_rampe(...)
        ArtIle.nuage(...)
        ArtIle.filon(...)
        Pixel.disque(...)
        ArtIle.c(...)

    @staticmethod
    def cadre(k: 'float', fond: 'String', bord: 'String') -> 'StyleBoxTexture':
        """fond : ton de crème du centre (« interface.4 » normal, « .5 » survol, « .3 » appui)."""
        ArtIle.style_anneaux(...)
        ArtIle.c(...)

    @staticmethod
    def style_anneaux(anneaux: 'Array', fond: 'Color') -> 'StyleBoxTexture':
        """Cadre épais en 9 parties à partir d'anneaux [couleur haut/gauche, couleur bas/droite], de l'extérieur
        vers l'intérieur : le relief vient de l'opposition clair en haut à gauche / sombre en bas à droite."""
        ...

    @staticmethod
    def ancrer(controle: 'Control', ax: 'float', ay: 'float', marge: 'float') -> 'void':
        """Ancre un panneau dans un coin ou au centre (0, 0.5 ou 1 sur chaque axe) ; il grandit vers l'intérieur."""
        ...

    @staticmethod
    def styler_bouton(bouton: 'Button') -> 'void':
        """Style des boutons de l'interface du haut (cadre or et crème, relief inversé à l'appui)."""
        ArtIle.cadre(...)
        ArtIle.c(...)
