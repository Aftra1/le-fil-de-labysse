# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/dive.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Plongée : décor par zones, câble, oxygène, minage, sac et règles de remontée.
Pas de game over : à 0 d'oxygène, la cloche remonte toute seule et une partie du butin est perdue.
Quand la cloche revient en surface après être descendue sous PROFONDEUR_ARMEMENT_M,
la plongée est terminée : on émet retour_ile et la scène Jeu lance la remontée vers l'île.
Rendu : le monde est dessiné en 320x180 (VueMonde, ArtAbysse) ; la logique reste en 640x360.
"""

from __future__ import annotations

from ..godot import Node2D, Signal
from ..scripts.art_abysse import ArtAbysse
from ..scripts.art_ile import ArtIle
from ..scripts.atelier import Atelier
from ..scripts.autoload.game import Game
from ..scripts.bell import Cloche
from ..scripts.donnees import Donnees
from ..scripts.gisement import Gisement
from ..scripts.hud import Interface
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel
from ..scripts.sac import Sac
from ..scripts.vue_monde import VueMonde


class Dive(Node2D):
    SURFACE_Y = 0.0
    PROFONDEUR_MAX = 4500.0
    PIXELS_PAR_METRE = 10.0
    MARGE_CAMERA_HAUT = 90.0
    MARGE_CAMERA_BAS = 60.0
    OXYGENE_MAX = 100.0
    CONSOMMATION_PAR_S = 1.2
    RECHARGE_PAR_S = 25.0
    SEUIL_SURFACE = 6.0
    PROFONDEUR_ARMEMENT_M = 10.0
    PORTEE_MINAGE = 28.0
    PERTE_REMONTEE_AUTO = 0.4
    ESPACEMENT_MIN = 40.0
    MARGE_BORD = 24.0
    DISTANCE_MIN_SURFACE = 100.0
    MARGE_FOND = 30.0
    ESSAIS_PLACEMENT = 200
    SEGMENTS_CABLE = 16
    ONDULATION_CABLE = 6.0
    LONGUEUR_CABLE_DROIT = 40.0
    ECRAN = ...
    LISSAGE_CAMERA = 10.0
    COULEUR_CABLE = "metal.3"
    COULEUR_CABLE_TENDU = "nuage.1"
    COULEUR_LIMITE = "or.3"
    retour_ile = Signal('gardees: Dictionary, perdues: Dictionary, urgence: bool')
    oxygene: 'float'
    oxygene_max: 'float'
    limite_px: 'float'
    _zones: 'Array'
    _minerais: 'Dictionary'
    _armee: 'bool'
    _terminee: 'bool'
    _sac: Sac
    _hasard: 'RandomNumberGenerator'
    _sous_leau_avant: 'bool'
    _id_zone: 'String'
    _gisement_mine: Gisement
    _progres_minage: 'float'
    _gisement_a_portee: Gisement
    _monde: VueMonde
    _camera: 'Vector2'
    _cloche: Cloche
    _interface: Interface
    _gisements: 'Node2D'

    def _ready(self) -> 'void':
        Donnees.charger_json(...)
        ArtAbysse.materiau_obscurite(...)

    def _physics_process(self, delta: 'float') -> 'void':
        Interface.annoncer(...)

    def _process(self, _delta: 'float') -> 'void':
        ...

    def appliquer_ameliorations(self) -> 'void':
        """Lit les niveaux installés à l'atelier : longueur du câble, réserve d'oxygène, lanterne."""
        Atelier.oxygene_max(...)
        Interface.regler_reserve(...)

    def au_bout_du_cable(self) -> 'bool':
        """Vrai quand le câble est tendu au maximum (la cloche ne peut pas descendre plus bas)."""
        ...

    def _regler_obscurite(self) -> 'void':
        """Paramètres du shader d'obscurité pour l'image en cours (mêmes coordonnées que VueMonde)."""
        VueMonde.origine_monde(...)

    def rafraichir_interface(self) -> 'void':
        """Met à jour l'interface (aussi appelé pendant la descente, quand la plongée est encore figée)."""
        Interface.mettre_a_jour(...)

    def _profondeur_m(self) -> 'float':
        ...

    def _zone_a(self, profondeur_m: 'float') -> 'Dictionary':
        ...

    def _gerer_minage(self, delta: 'float') -> 'void':
        Sac.est_plein(...)

    def _trouver_gisement_a_portee(self) -> Gisement:
        ...

    def _arreter_minage(self) -> 'void':
        """Remet la jauge à zéro : seule l'unité en cours est perdue."""
        ...

    def _terminer_unite(self, gisement: Gisement) -> 'void':
        Sac.ajouter(...)
        Gisement.retirer_unite(...)

    def _rafraichir_sac(self) -> 'void':
        Interface.definir_sac(...)
        Sac.est_plein(...)

    def _message_bas(self, sous_leau: 'bool') -> 'String':
        Sac.est_plein(...)

    def _terminer_plongee(self) -> 'void':
        Sac.perdre(...)
        Sac.vider(...)

    def _total(self, butin: 'Dictionary') -> 'int':
        ...

    def _texte_butin(self, prefixe: 'String', butin: 'Dictionary') -> 'String':
        ...

    def _generer_gisements(self) -> 'void':
        Gisement.configurer(...)
        Game.couleur_ressource(...)

    def _trouver_emplacement(self, existantes: 'Array[Vector2]', y_min: 'float', y_max: 'float') -> 'Vector2':
        """Cherche un point libre (espacement minimal) ; renvoie Vector2.INF si on n'en trouve pas."""
        ...

    def _cible_camera(self) -> 'Vector2':
        """La caméra vise la position *dessinée* de la cloche (arrondie au pixel du monde) et la rattrape en
    douceur. Elle avance au même rythme que la cloche (dans _physics_process), et VueMonde l'arrondit
    au pixel d'écran : le décor glisse d'un pixel d'écran à la fois."""
        VueMonde.vers_monde(...)

    def _suivre_camera(self, delta: 'float') -> 'void':
        ...

    def _dessiner_monde(self, toile: 'Node2D') -> 'void':
        ...

    def dessiner_monde(self, toile: 'CanvasItem', vue: 'Rect2', avec_ciel: 'bool', avec_cloche: 'bool') -> 'void':
        """Décor, gisements, câble et cloche dans « vue » (pixels du monde de la plongée). La transition
    l'appelle aussi (sans ciel ni cloche) pour que la surface raccorde sans coupure."""
        ArtAbysse.dessiner_eau(...)
        ArtAbysse.dessiner_reperes(...)
        Gisement.dessiner_monde(...)
        VueMonde.vers_monde(...)
        Pixel.sprite_ombre(...)
        Palette.plus_sombre(...)

    def cloche_position(self) -> 'Vector2':
        """Position de la cloche et haut de la vue (640x360), pour une remontée qui part de cette image."""
        ...

    def haut_camera(self) -> 'float':
        ...

    def _dessiner_cable(self, toile: 'CanvasItem', vue: 'Rect2') -> 'void':
        """Câble de 1 px : vertical au-dessus de la surface (il monte vers l'île), puis de la surface au haut
    de la cloche, légèrement ondulant."""
        VueMonde.vers_monde(...)
        Pixel.ligne(...)
        ArtAbysse.temps(...)

    def _dessiner_limite(self, toile: 'CanvasItem', vue: 'Rect2') -> 'void':
        """Limite du câble : une ligne de tirets or sur toute la largeur, sous la cloche au plus bas."""
        ...
