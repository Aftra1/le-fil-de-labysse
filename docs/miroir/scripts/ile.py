# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/ile.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""L'île flottante : récolte à la souris (vent, nuages, cristaux solaires), inventaire,
atelier (cabane : clic ou C) et départ en plongée en cliquant sur la cloche (ou E / Espace).
À droite, un îlot isolé : la passerelle de nuage (atelier, onglet Construction) le relie à l'île,
et son bassin de lumière donne alors du cristal de lagon (maintien du clic, comme les filons).
Les sources se rechargent avec le temps, y compris pendant la plongée (voir rattraper()).
Échap ferme un panneau ouvert ; sinon il remonte à la scène principale (menu pause).
Rendu : le monde est dessiné en 320x180 (VueMonde, affiché ×2) ; la logique reste en 640x360.
"""

from __future__ import annotations

from ..godot import Node2D, Signal
from ..scripts.art_abysse import ArtAbysse
from ..scripts.art_ile import ArtIle
from ..scripts.atelier import Atelier
from ..scripts.atelier_ui import PanneauAtelier
from ..scripts.autoload.game import Game
from ..scripts.donnees import Donnees
from ..scripts.hud_ile import InterfaceIle
from ..scripts.inventaire import Inventaire
from ..scripts.inventaire_ui import PanneauInventaire
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel
from ..scripts.source_ressource import SourceRessource
from ..scripts.vue_monde import VueMonde


class Ile(Node2D):
    POSITION_CLOCHE = ...
    ATTACHE_CABLE = ...
    ZONE_CLOCHE = ...
    POSITION_CABANE = ...
    ZONE_CABANE = ...
    DUREE_EFFET = 0.8
    MONTEE_EFFET = 18.0
    K = 0.5
    plongee_demandee = Signal('')
    partie_modifiee = Signal('')
    cloche_visible: 'bool'
    _reglages: 'Dictionary'
    _eolienne: SourceRessource
    _filons: 'Array[SourceRessource]'
    _bassin: SourceRessource
    _survol_ilot: 'bool'
    _souris: 'Vector2'
    _survol_cloche: 'bool'
    _survol_cabane: 'bool'
    _survol: SourceRessource
    _maintien: SourceRessource
    _progres_maintien: 'float'
    _attente_nuage: 'float'
    _hasard: 'RandomNumberGenerator'
    _monde: VueMonde
    _nuages: 'Node2D'
    _sources: 'Node2D'
    _effets: 'Node2D'
    _interface: InterfaceIle
    _panneau: PanneauInventaire
    _atelier: PanneauAtelier

    def _ready(self) -> 'void':
        Donnees.charger_json(...)
        PanneauAtelier.fabrique.connect(...)
        InterfaceIle.rafraichir_inventaire(...)

    def _notification(self, quoi: 'int') -> 'void':
        """Le bassin hors de l'arbre (îlot non relié) est libéré avec l'île."""
        ...

    def panneau_ouvert(self) -> 'bool':
        """Un seul panneau ouvert à la fois (inventaire ou atelier)."""
        PanneauInventaire.est_ouvert(...)
        PanneauAtelier.est_ouvert(...)

    def _basculer_inventaire(self) -> 'void':
        PanneauAtelier.fermer(...)
        PanneauInventaire.basculer(...)

    def _basculer_atelier(self) -> 'void':
        PanneauInventaire.fermer(...)
        PanneauAtelier.basculer(...)

    def _sur_fabrication(self, id: 'String', genre: 'String') -> 'void':
        """genre : « composant », « amelioration » ou « construction » (voir PanneauAtelier.fabrique)."""
        InterfaceIle.annoncer(...)
        InterfaceIle.rafraichir_inventaire(...)

    def _unhandled_input(self, evenement: 'InputEvent') -> 'void':
        PanneauInventaire.fermer(...)
        PanneauAtelier.fermer(...)

    def _process(self, delta: 'float') -> 'void':
        InterfaceIle.definir_aide(...)

    def _clic(self) -> 'void':
        PanneauInventaire.fermer(...)
        PanneauAtelier.ouvrir(...)
        PanneauAtelier.choisir_onglet(...)

    def _gerer_maintien(self, delta: 'float') -> 'void':
        SourceRessource.est_disponible(...)

    def _arreter_maintien(self) -> 'void':
        """Remet la jauge à zéro : seule l'unité en cours est perdue."""
        ...

    def _recolter(self, source: SourceRessource, nombre: 'int') -> 'void':
        SourceRessource.est_disponible(...)
        Inventaire.place(...)
        InterfaceIle.annoncer(...)
        SourceRessource.prendre(...)
        Inventaire.ajouter(...)
        InterfaceIle.rafraichir_inventaire(...)

    def _afficher_gain(self, lieu: 'Vector2', nombre: 'int') -> 'void':
        Pixel.texte(...)

    def _souris_sur_cloche(self) -> 'bool':
        ...

    def _source_sous_souris(self) -> SourceRessource:
        SourceRessource.contient(...)

    def _mettre_a_jour_survol(self) -> 'void':
        SourceRessource.est_disponible(...)

    def _texte_aide(self) -> 'String':
        Game.nom_ressource(...)
        SourceRessource.est_disponible(...)

    def _creer_sources(self) -> 'void':
        ...

    def ilot_relie(self) -> 'bool':
        Atelier.est_relie(...)

    def actualiser_ilot(self) -> 'void':
        """Le bassin n'existe sur l'île (récolte, recharge, dessin) que si l'îlot est relié."""
        ...

    def bassin(self) -> SourceRessource:
        ...

    def centre_ilot(self) -> 'Vector2':
        """Centre de la zone de survol de l'îlot (640x360)."""
        ...

    def _souris_sur_ilot(self) -> 'bool':
        ...

    def _nouvelle_source(self, reglage: 'Dictionary', mode: 'SourceRessource.Mode', forme: 'SourceRessource.Forme') -> SourceRessource:
        ...

    def _vecteur(self, valeur: 'Array') -> 'Vector2':
        ...

    def _gerer_nuages(self, delta: 'float') -> 'void':
        ...

    def _completer_nuages(self) -> 'void':
        ...

    def _nombre_nuages(self) -> 'int':
        ...

    def _creer_nuage(self, x: 'float') -> 'void':
        ...

    def preparer_depart(self) -> 'void':
        """Appelé au lancement de la descente : l'île se fige et la cloche part avec la transition."""
        PanneauInventaire.fermer(...)
        PanneauAtelier.fermer(...)

    def reprendre(self) -> 'void':
        """L'île redevient active (fin de remontée, ou retour à l'écran titre depuis une plongée)."""
        ...

    def afficher_interface(self, afficher: 'bool') -> 'void':
        """Interface de l'île cachée sous l'écran titre (le décor reste visible)."""
        PanneauInventaire.fermer(...)
        PanneauAtelier.fermer(...)

    def arriver(self, temps_plongee: 'float', gardees: 'Dictionary', perdues: 'Dictionary', urgence: 'bool') -> 'void':
        """Appelé à la fin de la remontée : rattrape la recharge, range le butin, annonce le résultat."""
        Inventaire.ajouter_tout(...)
        InterfaceIle.annoncer(...)
        InterfaceIle.rafraichir_inventaire(...)

    def rattraper(self, secondes: 'float') -> 'void':
        """Fait avancer la recharge des sources comme si « secondes » s'étaient écoulées sur l'île."""
        SourceRessource.recharger(...)

    def etat_sources(self) -> 'Dictionary':
        """État des sources fixes (les nuages ne sont pas sauvegardés : ils réapparaissent seuls)."""
        SourceRessource.etat(...)

    def restaurer_sources(self, donnees: 'Dictionary') -> 'void':
        """Reprend l'état sauvegardé des sources ; ce qui manque ou est faux garde la valeur de départ."""
        SourceRessource.restaurer(...)

    def reinitialiser_sources(self) -> 'void':
        """Sources remises à leur stock de départ (nouvelle partie)."""
        SourceRessource.restaurer(...)
        InterfaceIle.rafraichir_inventaire(...)

    def _total(self, butin: 'Dictionary') -> 'int':
        ...

    def _unites(self, nombre: 'int') -> 'String':
        ...

    def _sauvees(self, nombre: 'int') -> 'String':
        ...

    def _dessiner_monde(self, toile: 'Node2D') -> 'void':
        SourceRessource.dessiner_monde(...)
        VueMonde.vers_monde(...)
        ArtIle.cloche(...)
        Pixel.sprite_ombre(...)
        Pixel.cadre(...)

    def _dessiner_cabane(self, toile: 'Node2D') -> 'void':
        """Cabane de l'atelier : fenêtre allumée et fumée qui monte quand une fabrication est possible."""
        VueMonde.vers_monde(...)
        ArtIle.cabane(...)
        Pixel.sprite_ombre(...)
        Pixel.cadre(...)

    def _dessiner_ilot(self, toile: 'Node2D') -> 'void':
        """Îlot (assombri tant qu'il n'est pas relié), puis la passerelle, ou des pointillés or à sa place."""
        ArtIle.ilot(...)
        VueMonde.vers_monde(...)
        Palette.plus_sombre(...)
        Pixel.cadre(...)

    def _fabrication_possible(self) -> 'bool':
        Atelier.peut_construire(...)
        Atelier.composants(...)
        Atelier.peut_fabriquer(...)
        Atelier.peut_ameliorer(...)
