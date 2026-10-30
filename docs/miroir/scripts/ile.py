# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/ile.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""L'île flottante : récolte à la souris (vent, nuages, cristaux solaires), inventaire,
atelier (cabane : clic ou C) et départ en plongée en cliquant sur la cloche (ou E / Espace).
Deux îlots isolés (data/ile.json) : à droite, l'îlot de l'est, relié par la passerelle de nuage (son
bassin de lumière donne alors du cristal de lagon, maintien du clic comme les filons) ; en haut à
gauche, l'îlot du nord, relié par le pont suspendu (deux emplacements de machine). Un clic sur un
îlot isolé ouvre l'atelier, onglet Construction.
Machines (data/machines.json) : un clic sur un emplacement libre ouvre l'atelier, onglet Machines ;
une machine construite produit seule jusqu'à sa réserve et un clic vide la réserve (comme l'éolienne).
La foreuse solaire se pose sur un filon, qui ne se récolte plus à la main ; l'entrepôt ne produit
rien (il relève le plafond de l'inventaire). Le premier corail rapporté ouvre le palier 2, la première
pierre de braise le palier 3 : le fourneau (un clic récupère sa réserve et ouvre le choix du raffiné qu'il
fabrique en boucle avec les ingrédients de l'inventaire) et la sonde (qui ne produit qu'en plongée).
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
from ..scripts.autoload.son import Son
from ..scripts.carnet_ui import PanneauCarnet
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
    SONS_RECOLTE = ...
    FORMES_MACHINES = ...
    ZONE_EMPLACEMENT = ...
    RAYON_MACHINE = 16.0
    plongee_demandee = Signal('')
    partie_modifiee = Signal('')
    cloche_visible: 'bool'
    _reglages: 'Dictionary'
    _eolienne: SourceRessource
    _filons: 'Array[SourceRessource]'
    _bassin: SourceRessource
    _survol_ilot: 'String'
    _survol_emplacement: 'String'
    _machines: 'Dictionary'
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
    _carnet: PanneauCarnet

    def _ready(self) -> 'void':
        self._dessiner_monde  # passée comme Callable
        Donnees.charger_json(...)
        self._creer_sources(...)
        self._creer_nuage(...)
        self._basculer_inventaire  # passée comme Callable
        self.basculer_carnet  # passée comme Callable
        PanneauAtelier.fabrique.connect(...)
        self._sur_fabrication  # passée comme Callable
        InterfaceIle.rafraichir_inventaire(...)

    def _notification(self, quoi: 'int') -> 'void':
        """Le bassin (îlot non relié) et les filons sous une foreuse, hors de l'arbre, sont libérés avec l'île."""
        ...

    def panneau_ouvert(self) -> 'bool':
        """Un seul panneau ouvert à la fois (inventaire, atelier ou carnet)."""
        PanneauInventaire.est_ouvert(...)
        PanneauAtelier.est_ouvert(...)
        PanneauCarnet.est_ouvert(...)

    def _fermer_panneaux(self) -> 'void':
        PanneauInventaire.fermer(...)
        PanneauAtelier.fermer(...)
        PanneauCarnet.fermer(...)

    def _basculer_inventaire(self) -> 'void':
        PanneauAtelier.fermer(...)
        PanneauCarnet.fermer(...)
        PanneauInventaire.basculer(...)

    def _basculer_atelier(self) -> 'void':
        PanneauInventaire.fermer(...)
        PanneauCarnet.fermer(...)
        PanneauAtelier.basculer(...)

    def basculer_carnet(self) -> 'void':
        """Carnet de collection (K ou le bouton « Carnet »)."""
        PanneauInventaire.fermer(...)
        PanneauAtelier.fermer(...)
        PanneauCarnet.basculer(...)

    def _sur_fabrication(self, id: 'String', genre: 'String') -> 'void':
        """genre : « composant », « amelioration » ou « construction » (voir PanneauAtelier.fabrique)."""
        InterfaceIle.annoncer(...)
        Atelier.nom_amelioration(...)
        Atelier.niveau(...)
        Son.jouer(...)
        self.actualiser_ilot(...)
        Atelier.annonce_construction(...)
        self.actualiser_machines(...)
        Atelier.nom_machine(...)
        self.machine(...)
        self._vider_fourneau(...)
        Game.nom_ressource(...)
        InterfaceIle.rafraichir_inventaire(...)
        self.partie_modifiee.emit(...)

    def _unhandled_input(self, evenement: 'InputEvent') -> 'void':
        self._basculer_inventaire(...)
        self._basculer_atelier(...)
        self.basculer_carnet(...)
        self.panneau_ouvert(...)
        self._fermer_panneaux(...)
        self._mettre_a_jour_survol(...)
        self._clic(...)
        self.plongee_demandee.emit(...)

    def _process(self, delta: 'float') -> 'void':
        self._gerer_nuages(...)
        self._mettre_a_jour_survol(...)
        self._gerer_maintien(...)
        InterfaceIle.definir_aide(...)
        self._texte_aide(...)

    def _clic(self) -> 'void':
        self.plongee_demandee.emit(...)
        self._basculer_atelier(...)
        PanneauInventaire.fermer(...)
        PanneauAtelier.ouvrir(...)
        PanneauAtelier.choisir_onglet(...)
        Atelier.ilot_de(...)
        PanneauAtelier.selectionner(...)
        PanneauAtelier.ouvrir_machines(...)
        self._recolter(...)
        PanneauAtelier.ouvrir_fourneau(...)

    def _gerer_maintien(self, delta: 'float') -> 'void':
        SourceRessource.est_disponible(...)
        self.panneau_ouvert(...)
        self._arreter_maintien(...)
        self._recolter(...)

    def _arreter_maintien(self) -> 'void':
        """Remet la jauge à zéro : seule l'unité en cours est perdue."""
        ...

    def _recolter(self, source: SourceRessource, nombre: 'int') -> 'void':
        SourceRessource.est_disponible(...)
        Inventaire.place(...)
        InterfaceIle.annoncer(...)
        Game.nom_ressource(...)
        SourceRessource.prendre(...)
        Inventaire.ajouter(...)
        self._afficher_gain(...)
        Son.jouer(...)
        InterfaceIle.rafraichir_inventaire(...)

    def _afficher_gain(self, lieu: 'Vector2', nombre: 'int') -> 'void':
        Pixel.texte(...)

    def _souris_sur_cloche(self) -> 'bool':
        ...

    def _source_sous_souris(self, conteneur: 'Node2D') -> SourceRessource:
        """Source sous la souris dans ce conteneur (sources fixes et machines, ou nuages)."""
        SourceRessource.contient(...)

    def _mettre_a_jour_survol(self) -> 'void':
        self.panneau_ouvert(...)
        self._souris_sur_cloche(...)
        self._source_sous_souris(...)
        self._ilot_isole_sous_souris(...)
        self._emplacement_sous_souris(...)
        SourceRessource.est_disponible(...)

    def _texte_aide(self) -> 'String':
        self._ilot(...)
        Game.nom_ressource(...)
        self._aide_fourneau(...)
        SourceRessource.est_disponible(...)

    def _creer_sources(self) -> 'void':
        self._nouvelle_source(...)
        self._vecteur(...)
        self._ilot(...)
        self.actualiser_ilot(...)

    def actualiser_machines(self) -> 'void':
        """Crée les machines construites à l'atelier (et retire celles qui n'y sont plus : nouvelle partie),
        applique leurs améliorations, et retire de l'île les filons couverts par une foreuse."""
        Atelier.machine(...)
        Atelier.nom_machine(...)
        self.centre_emplacement(...)
        Atelier.plafond_machine(...)
        Atelier.en_plongee(...)
        Atelier.recharge_machine(...)
        Atelier.recette_fourneau(...)
        self._cycle_fourneau  # passée comme Callable
        Atelier.emplacements(...)

    def _cycle_fourneau(self, raffine: 'String') -> 'bool':
        """Un cycle du fourneau : ingrédients pris dans l'inventaire, dont l'affichage suit."""
        Atelier.consommer_fourneau(...)
        InterfaceIle.rafraichir_inventaire(...)
        PanneauAtelier.est_ouvert(...)
        PanneauAtelier.rafraichir(...)

    def _vider_fourneau(self, lieu: 'String') -> 'void':
        """Avant un changement de recette : la réserve du fourneau (l'ancien raffiné) passe dans l'inventaire."""
        self.machine(...)
        Inventaire.ajouter(...)
        SourceRessource.prendre(...)

    def _aide_fourneau(self, fourneau: SourceRessource) -> 'String':
        Game.nom_ressource(...)
        SourceRessource.en_activite(...)

    def machine(self, lieu: 'String') -> SourceRessource:
        """Machine posée sur un emplacement (null s'il est libre)."""
        ...

    def centre_emplacement(self, lieu: 'String') -> 'Vector2':
        """Centre de la zone cliquable d'un emplacement (640x360), au-dessus du sol."""
        self._vecteur(...)
        Atelier.emplacement(...)

    def _emplacement_sous_souris(self) -> 'String':
        Atelier.emplacements_libres(...)
        self.centre_emplacement(...)

    def _ilot(self, id: 'String') -> 'Dictionary':
        """Réglages d'un îlot (data/ile.json)."""
        ...

    def ilot_relie(self, id: 'String') -> 'bool':
        Atelier.est_relie(...)

    def actualiser_ilot(self) -> 'void':
        """Le bassin n'existe sur l'île (récolte, recharge, dessin) que si l'îlot de l'est est relié."""
        self.ilot_relie(...)

    def bassin(self) -> SourceRessource:
        ...

    def centre_ilot(self, id: 'String') -> 'Vector2':
        """Centre de la zone de survol d'un îlot (640x360)."""
        self._vecteur(...)
        self._ilot(...)

    def _ilot_isole_sous_souris(self) -> 'String':
        """Îlot non relié sous la souris (vide s'il n'y en a pas)."""
        self._vecteur(...)
        self.centre_ilot(...)
        self.ilot_relie(...)

    def _nouvelle_source(self, reglage: 'Dictionary', mode: 'SourceRessource.Mode', forme: 'SourceRessource.Forme') -> SourceRessource:
        ...

    def _vecteur(self, valeur: 'Array') -> 'Vector2':
        ...

    def _gerer_nuages(self, delta: 'float') -> 'void':
        self._completer_nuages(...)

    def _completer_nuages(self) -> 'void':
        self._nombre_nuages(...)
        self._creer_nuage(...)

    def _nombre_nuages(self) -> 'int':
        ...

    def _creer_nuage(self, x: 'float') -> 'void':
        ...

    def preparer_depart(self) -> 'void':
        """Appelé au lancement de la descente : l'île se fige et la cloche part avec la transition."""
        self._arreter_maintien(...)
        self._fermer_panneaux(...)

    def reprendre(self) -> 'void':
        """L'île redevient active (fin de remontée, ou retour à l'écran titre depuis une plongée)."""
        ...

    def afficher_interface(self, afficher: 'bool') -> 'void':
        """Interface de l'île cachée sous l'écran titre (le décor reste visible)."""
        self._fermer_panneaux(...)
        self._arreter_maintien(...)

    def arriver(self, temps_plongee: 'float', gardees: 'Dictionary', perdues: 'Dictionary', urgence: 'bool') -> 'void':
        """Appelé à la fin de la remontée : rattrape la recharge, range le butin, annonce le résultat."""
        self.reprendre(...)
        self.rattraper(...)
        SourceRessource.recharger_plongee(...)
        Inventaire.ajouter_tout(...)
        self._total(...)
        InterfaceIle.annoncer(...)
        self._unites(...)
        self._sauvees(...)
        Atelier.decouvrir(...)
        Atelier.liste_machines(...)
        Atelier.machine(...)
        Atelier.nom_machine(...)
        InterfaceIle.texte_annonce(...)
        InterfaceIle.rafraichir_inventaire(...)

    def rattraper(self, secondes: 'float') -> 'void':
        """Fait avancer la recharge des sources comme si « secondes » s'étaient écoulées sur l'île."""
        SourceRessource.recharger(...)
        self._nombre_nuages(...)
        self._creer_nuage(...)

    def etat_sources(self) -> 'Dictionary':
        """État des sources fixes (les nuages ne sont pas sauvegardés : ils réapparaissent seuls)."""
        SourceRessource.etat(...)

    def restaurer_sources(self, donnees: 'Dictionary') -> 'void':
        """Reprend l'état sauvegardé des sources ; ce qui manque ou est faux garde la valeur de départ."""
        self.reinitialiser_sources(...)
        SourceRessource.restaurer(...)
        self.actualiser_ilot(...)
        self.actualiser_machines(...)

    def reinitialiser_sources(self) -> 'void':
        """Sources remises à leur stock de départ (nouvelle partie)."""
        SourceRessource.restaurer(...)
        self._ilot(...)
        self.actualiser_ilot(...)
        self.actualiser_machines(...)
        InterfaceIle.rafraichir_inventaire(...)

    def _total(self, butin: 'Dictionary') -> 'int':
        ...

    def _unites(self, nombre: 'int') -> 'String':
        ...

    def _sauvees(self, nombre: 'int') -> 'String':
        ...

    def _dessiner_monde(self, toile: 'Node2D') -> 'void':
        ArtIle.fond_ile(...)
        SourceRessource.dessiner_monde(...)
        self._dessiner_cabane(...)
        self._dessiner_ilots(...)
        self._dessiner_emplacements(...)
        VueMonde.vers_monde(...)
        ArtIle.cloche(...)
        Palette.couleur(...)
        Pixel.sprite_ombre(...)
        Palette.plus_sombre(...)
        ArtIle.couleur_ciel_monde(...)
        Pixel.cadre(...)

    def _dessiner_cabane(self, toile: 'Node2D') -> 'void':
        """Cabane de l'atelier : fenêtre allumée et fumée qui monte quand une fabrication est possible."""
        VueMonde.vers_monde(...)
        self._fabrication_possible(...)
        ArtIle.cabane(...)
        Pixel.sprite_ombre(...)
        Palette.couleur(...)
        ArtAbysse.temps(...)
        Pixel.cadre(...)

    def _dessiner_ilots(self, toile: 'Node2D') -> 'void':
        """Îlots (assombris tant qu'ils ne sont pas reliés), puis leur passerelle ou leur pont, ou des
        pointillés or à leur place."""
        self._dessiner_ilot(...)

    def _dessiner_ilot(self, toile: 'Node2D', donnees: 'Dictionary') -> 'void':
        self.ilot_relie(...)
        ArtIle.ilot(...)
        VueMonde.vers_monde(...)
        self._vecteur(...)
        Palette.plus_sombre(...)
        ArtIle.couleur_ciel_monde(...)
        Pixel.silhouette(...)
        Palette.couleur(...)
        Pixel.cadre(...)
        self.centre_ilot(...)

    def _dessiner_emplacements(self, toile: 'Node2D') -> 'void':
        """Emplacements libres : une dalle de pierre et, au-dessus, la silhouette en pointillés or d'une machine."""
        Atelier.emplacements_libres(...)
        VueMonde.vers_monde(...)
        self._vecteur(...)
        Atelier.emplacement(...)
        Palette.couleur(...)
        Pixel.cadre(...)
        self.centre_emplacement(...)

    def _fabrication_possible(self) -> 'bool':
        Atelier.machines_disponibles(...)
        Atelier.peut_construire_machine(...)
        Atelier.machine(...)
        Atelier.peut_ameliorer_machine(...)
        Atelier.peut_construire(...)
        Atelier.composants(...)
        Atelier.peut_fabriquer(...)
        Atelier.peut_ameliorer(...)
