# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/art_abysse.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Pixel art de l'abysse (plongée), dessiné dans le monde 320x180 (voir VueMonde).
Repère : pixels du monde de la plongée, x = 0 au centre, y = 0 à la surface de la mer.
L'eau, les reflets, les particules et la surface sont des fonctions du lieu et d'une horloge
commune (images de physique) : la transition peut redessiner exactement la même image.
Contour bleu nuit (« contour_bas »), ombres portées d'un ton plus sombre que l'eau derrière.
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.art_ile import ArtIle
from ..scripts.donnees import Donnees
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel


class ArtAbysse(RefCounted):
    CONTOUR = "contour_bas"
    PX_PAR_METRE = 5.0
    PROFONDEUR_REFLETS = 140
    VAGUES = ...
    CELLULE_PARTICULES = 16
    CELLULE_REFLETS = ...
    DECALAGE_COLONNE = ...
    CRISTAL = ...
    BRAISE = ...
    CORAIL = ...
    DEBUT_OBSCURITE_M = 40.0
    PAS_OBSCURITE_M = 40.0
    ANNEAU_HALO = 10.0
    LUEURS = ...
    FOND_MAGMA = 12
    SHADER_OBSCURITE = ...
    figer_temps: 'bool'
    _etapes: 'Array'
    _cache: 'Dictionary'
    _debuts_zones: 'Array'

    @staticmethod
    def c(nom: 'String') -> 'Color':
        Palette.couleur(...)

    @staticmethod
    def temps() -> 'float':
        ...

    @staticmethod
    def couleur_eau(profondeur: 'float') -> 'Color':
        """Couleur de l'eau à une profondeur (px du monde sous la surface), paliers des zones (data/zones.json)."""
        ...

    @staticmethod
    def couleur_fond(point: 'Vector2') -> 'Color':
        """Couleur de ce qu'il y a derrière un point de la plongée (ciel au-dessus de la surface, eau dessous)."""
        ArtIle.couleur_ciel_monde(...)

    @staticmethod
    def contour_cloche(y_plongee: 'float') -> 'String':
        """Contour de la cloche : brun au-dessus de la surface (monde du haut), bleu nuit dessous."""
        ...

    @staticmethod
    def dessiner_eau(toile: 'CanvasItem', zone: 'Rect2', profondeur_max: 'float', avec_ciel: 'bool') -> 'void':
        """Dessine le décor de la plongée visible dans « zone » (pixels du monde de la plongée) :
    ciel au-dessus de la surface, surface animée, eau en paliers à bords en vagues, reflets, particules."""
        ArtIle.dessiner_ciel(...)

    @staticmethod
    def _dessiner_magma(toile: 'CanvasItem', zone: 'Rect2', profondeur_max: 'float', t: 'float') -> 'void':
        """Fond de la Faille : roche sombre crénelée, fissures de magma qui palpitent (lueur jamais assombrie)."""
        ...

    @staticmethod
    def _dessiner_particules(toile: 'CanvasItem', zone: 'Rect2', t: 'float') -> 'void':
        """Particules : un point par cellule (ou rien), qui dérive d'un pixel entier à la fois.
    Lagon : poussière claire ; forêt de coraux : bioluminescence cyan et violette."""
        ...

    @staticmethod
    def dessiner_reperes(toile: 'CanvasItem', zone: 'Rect2', profondeur_max: 'float') -> 'void':
        """Repères de profondeur tous les 10 m sur les bords."""
        Palette.plus_clair(...)

    @staticmethod
    def niveau_obscurite(profondeur_m: 'float', obscurite_max: 'int') -> 'int':
        """Nombre de tons d'obscurité à une profondeur, sans halo (0 à 3, limité par la lanterne)."""
        ...

    @staticmethod
    def crans_halo(distance: 'float', rayon: 'float') -> 'int':
        """Tons retirés par le halo à une distance de la cloche (pixels du monde) : 0 au centre, puis 1, 2, 3."""
        ...

    @staticmethod
    def assombrir(teinte: 'Color', profondeur_m: 'float', distance: 'float', rayon: 'float', obscurite_max: 'int') -> 'Color':
        """Couleur affichée d'un pixel du monde : son ton, assombri dans sa propre rampe."""
        Palette.plus_sombre(...)

    @staticmethod
    def materiau_obscurite() -> 'ShaderMaterial':
        """Matériau d'obscurité de la vue du monde de la plongée (ombre « un ton plus sombre » par pixel).
    Table : ligne k = chaque couleur de la palette assombrie de k tons dans sa rampe."""
        Palette.noms(...)

    @staticmethod
    def gisement(minerai: 'String', grise: 'bool') -> 'ImageTexture':
        Pixel.motif(...)

    @staticmethod
    def lueur(minerai: 'String') -> 'String':
        """Couleur de lueur d'un minerai (stock, anneaux) : jamais assombrie par l'obscurité."""
        ...

    @staticmethod
    def cadre() -> 'StyleBoxTexture':
        """Cadre des panneaux de l'abysse : liseré bleu nuit, métal sombre en relief, lueur cyan, fond nuit."""
        ArtIle.style_anneaux(...)

    @staticmethod
    def vider_cache() -> 'void':
        ...

    @staticmethod
    def _charger() -> 'void':
        Donnees.charger_json(...)

    @staticmethod
    def _debut_zone(indice: 'int') -> 'float':
        """Début de la zone d'indice « indice » (0 : Lagon, 1 : Coraux, 2 : Faille), en pixels du monde."""
        Donnees.charger_json(...)

    @staticmethod
    def _hasard(a: 'int', b: 'int', usage: 'int') -> 'float':
        """Nombre pseudo-aléatoire stable dans [0, 1) pour une cellule et un usage donnés."""
        ...
