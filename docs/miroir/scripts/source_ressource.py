# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/source_ressource.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Une source de ressource sur l'île : éolienne, filon de cristal, nuage, bassin de lumière (îlot)
ou machine construite sur un emplacement (moulin à vent, filet à nuages, entrepôt) ou sur un filon
(foreuse solaire).
Trois façons de récolter :
- CLIC : un clic = une prise (nuages : « rendement » ouates par prise) ;
- MAINTIEN : maintenir le clic remplit une jauge, une unité par cycle (filons, bassin) ;
- RESERVE : la source accumule seule, un clic vide toute la réserve (éolienne, machines).
Le stock se recharge avec le temps jusqu'au plafond (recharge_s secondes par unité).
"""

from __future__ import annotations

from enum import IntEnum
from ..godot import Node2D
from ..scripts.art_abysse import ArtAbysse
from ..scripts.art_ile import ArtIle
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel
from ..scripts.vue_monde import VueMonde


class SourceRessource(Node2D):
    class Mode(IntEnum):
        CLIC = 0
        MAINTIEN = 1
        RESERVE = 2

    class Forme(IntEnum):
        EOLIENNE = 0
        FILON = 1
        NUAGE = 2
        BASSIN = 3
        MOULIN = 4
        FILET = 5
        FOREUSE = 6
        ENTREPOT = 7

    VITESSE_PALES = 1.6
    VITESSE_AILES = 1.1
    HAUTEUR_MACHINE = 8
    IMAGES_PAR_SECONDE = 60
    K = 0.5
    FILON = ...
    TAILLE_NUAGE = ...
    HAUTEUR_MAT = 25
    id_ressource: 'String'
    nom: 'String'
    mode: 'Mode'
    forme: 'Forme'
    stock: 'int'
    rendement: 'int'
    plafond: 'int'
    recharge_s: 'float'
    duree_maintien: 'float'
    rayon_clic: 'float'
    derive: 'float'
    progres: 'float'
    en_survol: 'bool'
    _accumulateur: 'float'
    _angle: 'float'
    _images_par_pas: 'int'
    _compteur_pas: 'int'

    def _process(self, delta: 'float') -> 'void':
        self.recharger(...)

    def _physics_process(self, _delta: 'float') -> 'void':
        ...

    def recharger(self, secondes: 'float') -> 'void':
        """Fait avancer la recharge de « secondes » (aussi utilisé pour rattraper le temps de plongée)."""
        ...

    def etat(self) -> 'Dictionary':
        """État enregistré dans la sauvegarde : stock et recharge en cours."""
        ...

    def restaurer(self, donnees: 'Dictionary') -> 'void':
        """Reprend un état sauvegardé, borné : stock 0..plafond, recharge 0..recharge_s."""
        ...

    def est_disponible(self) -> 'bool':
        ...

    def contient(self, point: 'Vector2') -> 'bool':
        ...

    def prendre(self, nombre: 'int') -> 'int':
        """Retire jusqu'à « nombre » unités ; renvoie la quantité réellement prise."""
        ...

    def dessiner_monde(self, toile: 'CanvasItem') -> 'void':
        VueMonde.vers_monde(...)
        self._dessiner_eolienne(...)
        self._dessiner_filon(...)
        self._dessiner_nuage(...)
        self._dessiner_bassin(...)
        self._dessiner_moulin(...)
        self._dessiner_filet(...)
        self._dessiner_foreuse(...)
        self._dessiner_entrepot(...)
        self.est_disponible(...)
        Pixel.sprite(...)
        Pixel.anneau(...)
        Palette.couleur(...)
        Pixel.jauge(...)

    def _dessiner_eolienne(self, toile: 'CanvasItem', moyeu: 'Vector2') -> 'void':
        Palette.couleur(...)
        Pixel.sprite(...)
        ArtIle.pales(...)
        self._dessiner_points(...)

    def _dessiner_bassin(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        """Bassin de lumière : une flaque du lagon creusée dans l'herbe, qui scintille quand elle est pleine."""
        Palette.couleur(...)
        self.est_disponible(...)
        ArtAbysse.temps(...)
        self._dessiner_points(...)

    def _dessiner_moulin(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        """Moulin à vent : petite tour de bois au toit sombre, quatre ailes de toile sur une armature, qui
        tournent tant qu'il produit (elles s'arrêtent quand la réserve est pleine : il est temps de la vider)."""
        Palette.couleur(...)
        self._dessiner_points(...)

    def _dessiner_filet(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        """Filet à nuages : deux poteaux, un filet qui ondule au vent et les ouates prises dans ses mailles."""
        Palette.couleur(...)
        ArtAbysse.temps(...)
        self._dessiner_points(...)

    def _dessiner_foreuse(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        """Foreuse solaire : un chevalet de bois au-dessus du filon, dont la mèche tourne et descend dans le
        cristal tant que la réserve n'est pas pleine."""
        Pixel.sprite_ombre(...)
        ArtIle.filon(...)
        Palette.couleur(...)
        ArtAbysse.temps(...)
        self._dessiner_points(...)

    def _dessiner_entrepot(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        """Entrepôt : une petite remise de planches au toit sombre, avec une caisse devant la porte."""
        Palette.couleur(...)

    def _dessiner_filon(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        Pixel.sprite_ombre(...)
        ArtIle.filon(...)
        self.est_disponible(...)
        Palette.couleur(...)
        self._dessiner_points(...)

    def _dessiner_nuage(self, toile: 'CanvasItem', centre: 'Vector2') -> 'void':
        Palette.plus_sombre(...)
        ArtIle.couleur_ciel_monde(...)
        Pixel.sprite_ombre(...)
        ArtIle.nuage(...)
        self._dessiner_points(...)

    def _dessiner_points(self, toile: 'CanvasItem', centre: 'Vector2', couleur: 'String') -> 'void':
        """Un pixel du monde par unité de plafond, espacés d'un pixel : plein si disponible, sombre sinon."""
        Palette.couleur(...)
