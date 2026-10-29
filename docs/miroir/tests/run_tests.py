# Fichier généré automatiquement, ne pas modifier.
# Source : tests/run_tests.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Tests de logique (étapes 1 à 5). Lancement : voir tests/lancer.sh ou le README.
Chaque vérification affiche PASS ou FAIL, puis un total ; code de sortie 1 s'il y a un échec.
"""

from __future__ import annotations

from ..godot import SceneTree
from ..scripts.art_abysse import ArtAbysse
from ..scripts.atelier import Atelier
from ..scripts.bell import Cloche
from ..scripts.dive import Dive
from ..scripts.donnees import Donnees
from ..scripts.gisement import Gisement
from ..scripts.ile import Ile
from ..scripts.inventaire import Inventaire
from ..scripts.jeu import Jeu
from ..scripts.palette import Palette
from ..scripts.pixel import Pixel
from ..scripts.sac import Sac
from ..scripts.sauvegarde import Sauvegarde
from ..scripts.source_ressource import SourceRessource
from ..scripts.synthe import Synthe
from ..scripts.vue_monde import VueMonde


class RunTests(SceneTree):
    SCENE_PLONGEE = Dive
    SCENE_ILE = Ile
    SCENE_JEU = Jeu
    ETAT_ILE = 0
    ETAT_DESCENTE = 1
    ETAT_PLONGEE = 2
    ETAT_REMONTEE = 3
    IMAGES_PAR_S = 60.0
    SAUVEGARDE_TESTS = "user://tests_sauvegarde.json"
    _reussis: 'int'
    _total: 'int'
    _dive_script: Dive
    _ile_script: Ile
    _plongee: 'Node'
    _bell: 'CharacterBody2D'
    _jeu: 'Node'
    _retours: 'Array'
    _quitter_demande: 'int'

    def _initialize(self) -> 'void':
        self._lancer(...)

    def _lancer(self) -> 'void':
        self._effacer_sauvegarde(...)
        self._titre(...)
        self._test_inertie(...)
        self._test_flottabilite(...)
        self._test_bornes(...)
        self._test_oxygene_baisse_et_recharge(...)
        self._test_remontee_automatique(...)
        self._test_budget_oxygene(...)
        self._test_budget_faille(...)
        self._test_sac(...)
        self._test_placement(...)
        self._test_minage(...)
        self._test_minage_hors_portee(...)
        self._test_sac_plein(...)
        self._test_perte_de_butin(...)
        self._test_armement(...)
        self._test_inventaire(...)
        self._test_sources(...)
        self._test_recolte(...)
        self._test_panneau_inventaire(...)
        self._test_lancer_plongee_depuis_ile(...)
        self._test_scene_principale(...)
        self._test_transitions(...)
        self._test_glissement_hud(...)
        self._test_recharge_pendant_plongee(...)
        self._test_flux_urgence(...)
        self._test_atelier_logique(...)
        self._test_atelier_ile(...)
        self._test_limite_cable(...)
        self._test_reservoir(...)
        self._test_obscurite_regles(...)
        self._test_lueur_braise(...)
        self._test_equilibre(...)
        self._test_sauvegarde_fichier(...)
        self._test_sauvegarde_contenu(...)
        self._test_sauvegarde_jeu(...)
        self._test_sauvegarde_automatique(...)
        self._test_ecran_titre(...)
        self._test_pause_ile(...)
        self._test_pause_plongee(...)
        self._test_echap_transition(...)
        self._test_ilot_logique(...)
        self._test_ilot_ile(...)
        self._test_ilot_sauvegarde(...)
        self._test_machines_logique(...)
        self._test_machines_ile(...)
        self._test_machines_sauvegarde(...)
        self._test_palier2_logique(...)
        self._test_palier2_ile(...)
        self._test_palier2_sauvegarde(...)
        self._test_sac_12(...)
        self._test_synthese(...)
        self._test_bus_et_volumes(...)
        self._test_ambiances(...)
        self._test_sons_ile(...)
        self._test_sons_plongee(...)
        self._test_sons_transitions(...)
        self._test_volumes_sauvegarde(...)
        self._test_rendu_pixel(...)
        self._test_monde_320(...)
        self._test_camera_plongee(...)
        self._couper_son_et_quitter(...)

    def _titre(self, texte: 'String') -> 'void':
        ...

    def _verifier(self, condition: 'bool', nom: 'String', detail: 'String') -> 'void':
        ...

    def _images(self, nombre: 'int') -> 'void':
        ...

    def _secondes(self, duree: 'float') -> 'void':
        self._images(...)

    def _demarrer(self) -> 'void':
        Inventaire()

    def _terminer(self) -> 'void':
        ...

    def _somme(self, butin: 'Dictionary') -> 'int':
        ...

    def _vers_fenetre(self, point: 'Vector2') -> 'Vector2':
        """Évènements souris envoyés en coordonnées fenêtre (le jeu les ramène en 640x360)."""
        ...

    def _souris(self, point: 'Vector2') -> 'void':
        self._vers_fenetre(...)

    def _bouton(self, point: 'Vector2', appuye: 'bool') -> 'void':
        self._vers_fenetre(...)

    def _cliquer(self, point: 'Vector2') -> 'void':
        self._souris(...)
        self._images(...)
        self._bouton(...)

    def _touche(self, code: 'Key') -> 'void':
        ...

    def _gisements(self) -> 'Array[Gisement]':
        ...

    def _test_inertie(self) -> 'void':
        self._demarrer(...)
        self._secondes(...)
        self._verifier(...)
        self._terminer(...)

    def _test_flottabilite(self) -> 'void':
        self._demarrer(...)
        self._secondes(...)
        self._verifier(...)
        self._terminer(...)

    def _test_bornes(self) -> 'void':
        self._demarrer(...)
        self._secondes(...)
        self._verifier(...)
        self._terminer(...)

    def _test_oxygene_baisse_et_recharge(self) -> 'void':
        self._demarrer(...)
        self._verifier(...)
        self._secondes(...)
        self._terminer(...)

    def _test_remontee_automatique(self) -> 'void':
        self._demarrer(...)
        self._images(...)
        self._verifier(...)
        self._secondes(...)
        self._terminer(...)

    def _test_budget_oxygene(self) -> 'void':
        self._demarrer(...)
        self._images(...)
        self._verifier(...)
        Donnees.charger_json(...)
        self._terminer(...)

    def _test_sac(self) -> 'void':
        self._verifier(...)
        Sac.nombre(...)
        Sac.est_plein(...)
        Sac.ajouter(...)
        Sac.perdre(...)
        Sac.compter(...)
        Sac.vider(...)

    def _test_placement(self) -> 'void':
        Donnees.charger_json(...)
        self._demarrer(...)
        self._gisements(...)
        self._terminer(...)
        self._verifier(...)

    def _test_minage(self) -> 'void':
        self._demarrer(...)
        self._gisements(...)
        self._images(...)
        self._verifier(...)
        self._secondes(...)
        self._terminer(...)

    def _test_minage_hors_portee(self) -> 'void':
        self._demarrer(...)
        self._gisements(...)
        self._secondes(...)
        self._images(...)
        self._verifier(...)
        self._terminer(...)

    def _test_sac_plein(self) -> 'void':
        self._demarrer(...)
        self._gisements(...)
        self._secondes(...)
        self._verifier(...)
        self._terminer(...)

    def _test_perte_de_butin(self) -> 'void':
        self._demarrer(...)
        self._images(...)
        self._verifier(...)
        self._secondes(...)
        self._somme(...)
        self._terminer(...)

    def _test_armement(self) -> 'void':
        self._demarrer(...)
        self._images(...)
        self._verifier(...)
        self._secondes(...)
        self._terminer(...)

    def _test_inventaire(self) -> 'void':
        self._verifier(...)
        Inventaire.total(...)
        Inventaire.quantite(...)
        Inventaire.ajouter(...)
        Inventaire.ajouter_tout(...)
        Inventaire.retirer(...)

    def _source(self, plafond: 'int', recharge_s: 'float') -> SourceRessource:
        ...

    def _test_sources(self) -> 'void':
        Donnees.charger_json(...)
        self._source(...)
        SourceRessource.recharger(...)
        self._verifier(...)
        SourceRessource.prendre(...)

    def _ouvrir_ile(self) -> 'Node':
        Inventaire()
        self._images(...)

    def _fermer_ile(self, ile: 'Node') -> 'void':
        self._bouton(...)
        self._images(...)

    def _nuage_degage(self, ile: 'Node') -> SourceRessource:
        """Premier nuage de l'île, immobile et cliquable. Les nuages naissent au hasard entre y = 34 et 112 :
        l'un d'eux peut se trouver sous le bouton « Inventaire » (en haut à gauche), et un clic ouvrirait alors
        l'inventaire, qui bloque tous les clics suivants. On le déplace dans ce cas (c'est le premier des
        nuages parcourus au survol : un autre nuage au même endroit ne gêne pas)."""
        ...

    def _test_recolte(self) -> 'void':
        self._ouvrir_ile(...)
        self._nuage_degage(...)
        self._cliquer(...)
        self._verifier(...)
        self._souris(...)
        self._images(...)
        self._bouton(...)
        self._secondes(...)
        self._fermer_ile(...)

    def _test_panneau_inventaire(self) -> 'void':
        self._ouvrir_ile(...)
        self._touche(...)
        self._images(...)
        self._verifier(...)
        self._cliquer(...)
        self._fermer_ile(...)

    def _test_lancer_plongee_depuis_ile(self) -> 'void':
        self._ouvrir_ile(...)
        self._cliquer(...)
        self._verifier(...)
        self._touche(...)
        self._images(...)
        self._fermer_ile(...)

    def _ouvrir_jeu(self, avec_titre: 'bool') -> 'Node':
        Inventaire()
        self._images(...)

    def _fermer_jeu(self, jeu: 'Node') -> 'void':
        self._images(...)

    def _attendre_etat(self, jeu: 'Node', etat: 'int', limite: 'float') -> 'float':
        """Attend un état du jeu ; renvoie le temps écoulé (ou -1 si dépassé)."""
        self._images(...)

    def _remonter(self, jeu: 'Node') -> 'void':
        """Termine la plongée en cours : la cloche passe sous 10 m puis revient en surface."""
        self._images(...)

    def _test_scene_principale(self) -> 'void':
        self._verifier(...)

    def _test_transitions(self) -> 'void':
        self._ouvrir_jeu(...)
        self._verifier(...)
        self._cliquer(...)
        self._attendre_etat(...)
        self._remonter(...)
        self._secondes(...)
        self._touche(...)
        self._images(...)
        self._bouton(...)
        self._fermer_jeu(...)

    def _plongee_de(self, duree: 'float') -> 'Array':
        """Vide les sources de l'île, plonge « duree » secondes, revient ;
        renvoie [vent, plafond vent, cristaux, plafond cristaux, temps sous l'eau]."""
        self._ouvrir_jeu(...)
        self._touche(...)
        self._images(...)
        self._attendre_etat(...)
        self._secondes(...)
        self._remonter(...)
        self._fermer_jeu(...)

    def _test_recharge_pendant_plongee(self) -> 'void':
        self._plongee_de(...)
        self._verifier(...)

    def _test_flux_urgence(self) -> 'void':
        self._ouvrir_jeu(...)
        self._touche(...)
        self._images(...)
        self._attendre_etat(...)
        self._verifier(...)
        self._somme(...)
        self._fermer_jeu(...)

    def _test_rendu_pixel(self) -> 'void':
        Palette.noms(...)
        self._verifier(...)
        Palette.rampe(...)
        Palette.plus_sombre(...)
        Palette.couleur(...)
        Donnees.charger_json(...)
        Palette.contient(...)
        Pixel.motif(...)

    def _test_monde_320(self) -> 'void':
        self._ouvrir_ile(...)
        self._verifier(...)
        self._fermer_ile(...)

    def _test_camera_plongee(self) -> 'void':
        self._demarrer(...)
        self._verifier(...)
        self._images(...)
        self._secondes(...)
        self._terminer(...)

    def _test_glissement_hud(self) -> 'void':
        self._ouvrir_jeu(...)
        self._touche(...)
        self._images(...)
        self._verifier(...)
        self._attendre_etat(...)
        self._remonter(...)
        self._secondes(...)
        self._fermer_jeu(...)

    def _test_atelier_logique(self) -> 'void':
        self._verifier(...)
        Atelier.fabriquer(...)
        Inventaire.quantite(...)
        Atelier.manquants(...)
        Atelier.ingredients_composant(...)
        Inventaire.ajouter(...)
        Atelier.longueur_cable_m(...)
        Atelier.oxygene_max(...)
        Atelier.rayon_halo(...)
        Atelier.obscurite_max(...)
        Atelier.ameliorer(...)
        Atelier.niveau(...)
        Atelier.est_au_maximum(...)
        Atelier.prochain_niveau(...)

    def _test_atelier_ile(self) -> 'void':
        self._ouvrir_ile(...)
        self._touche(...)
        self._images(...)
        self._verifier(...)
        self._cliquer(...)
        self._fermer_ile(...)

    def _test_limite_cable(self) -> 'void':
        self._demarrer(...)
        self._secondes(...)
        self._verifier(...)
        self._terminer(...)

    def _test_reservoir(self) -> 'void':
        self._demarrer(...)
        self._terminer(...)
        self._images(...)
        self._verifier(...)

    def _test_obscurite_regles(self) -> 'void':
        self._verifier(...)
        ArtAbysse.niveau_obscurite(...)
        ArtAbysse.crans_halo(...)
        Palette.couleur(...)
        ArtAbysse.assombrir(...)

    def _test_equilibre(self) -> 'void':
        """Simulation prudente de la boucle : entre deux plongées, l'île donne 5 vents, 6 nuages et 3 cristaux
        solaires ; une plongée rapporte un sac de 8 (lagon seulement tant que le câble fait 150 m).
        On fabrique ce qui sert à la prochaine amélioration. Tout doit être débloqué en 6 plongées au plus."""
        Atelier.niveau(...)
        Inventaire.ajouter(...)
        Atelier.ameliorer(...)
        Inventaire.quantite(...)
        Atelier.fabriquer(...)
        self._verifier(...)

    def _effacer_sauvegarde(self) -> 'void':
        ...

    def _ecrire_texte(self, chemin: 'String', texte: 'String') -> 'void':
        ...

    def _lire_texte(self, chemin: 'String') -> 'String':
        ...

    def _partie_exemple(self) -> 'Dictionary':
        ...

    def _test_sauvegarde_fichier(self) -> 'void':
        """Lecture et écriture du fichier : absent, aller-retour, copie de secours, fichiers abîmés, versions."""
        self._verifier(...)
        self._effacer_sauvegarde(...)
        Sauvegarde.lire(...)
        Sauvegarde.existe(...)
        Sauvegarde.ecrire(...)
        self._partie_exemple(...)
        self._ecrire_texte(...)
        self._lire_texte(...)
        Sauvegarde.mettre_de_cote_version_recente(...)

    def _test_sauvegarde_contenu(self) -> 'void':
        """Valeurs fausses ou incomplètes : ignorées ou ramenées dans les limites."""
        Sauvegarde.migrer(...)
        self._verifier(...)
        Inventaire.depuis_dictionnaire(...)
        Atelier()
        Atelier.charger_machines(...)
        Inventaire.vers_dictionnaire(...)
        Atelier.charger_niveaux(...)
        Atelier.niveau(...)
        Atelier.niveau_max(...)
        self._source(...)
        SourceRessource.restaurer(...)
        SourceRessource.etat(...)
        Sauvegarde.secondes_depuis(...)

    def _test_sauvegarde_jeu(self) -> 'void':
        """Sauvegarder une partie, puis la reprendre par l'écran titre ; rattrapage du temps jeu fermé."""
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._verifier(...)
        self._fermer_jeu(...)
        self._images(...)
        Sauvegarde.ecrire(...)

    def _inventaire_sauve(self) -> 'Dictionary':
        Sauvegarde.lire(...)

    def _test_sauvegarde_automatique(self) -> 'void':
        """Moments de sauvegarde : fabrication, départ, fermeture en plongée (état du départ), retour."""
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._images(...)
        self._verifier(...)
        self._inventaire_sauve(...)
        self._cliquer(...)
        self._attendre_etat(...)
        self._lire_texte(...)
        self._remonter(...)
        self._fermer_jeu(...)

    def _centre(self, controle: 'Control') -> 'Vector2':
        ...

    def _test_ecran_titre(self) -> 'void':
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._verifier(...)
        self._cliquer(...)
        self._centre(...)
        self._fermer_jeu(...)
        self._touche(...)
        self._images(...)
        self._inventaire_sauve(...)
        self._ecrire_texte(...)

    def _test_pause_ile(self) -> 'void':
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._touche(...)
        self._images(...)
        self._verifier(...)
        self._secondes(...)
        self._cliquer(...)
        self._centre(...)
        self._inventaire_sauve(...)
        self._fermer_jeu(...)

    def _test_pause_plongee(self) -> 'void':
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._touche(...)
        self._attendre_etat(...)
        self._secondes(...)
        self._images(...)
        self._verifier(...)
        self._cliquer(...)
        self._centre(...)
        self._inventaire_sauve(...)
        self._fermer_jeu(...)

    def _test_echap_transition(self) -> 'void':
        """Échap pendant la descente et la remontée : ignoré (ni pause, ni transition passée)."""
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._touche(...)
        self._secondes(...)
        self._images(...)
        self._verifier(...)
        self._attendre_etat(...)
        self._remonter(...)
        self._fermer_jeu(...)

    def _ingredients_passerelle(self, inventaire: Inventaire) -> 'void':
        Inventaire.ajouter(...)

    def _test_ilot_logique(self) -> 'void':
        self._verifier(...)
        Atelier.est_relie(...)
        Atelier.ilot_de(...)
        Atelier.construire(...)
        self._ingredients_passerelle(...)
        Inventaire.total(...)
        Atelier.peut_construire(...)
        Atelier.charger_ilots(...)

    def _test_ilot_ile(self) -> 'void':
        self._ouvrir_ile(...)
        self._verifier(...)
        self._souris(...)
        self._images(...)
        self._bouton(...)
        self._secondes(...)
        self._ingredients_passerelle(...)
        self._fermer_ile(...)

    def _test_ilot_sauvegarde(self) -> 'void':
        """Aller-retour sauvegarde / chargement avec l'îlot relié (liste des îlots, stock du bassin)."""
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._ingredients_passerelle(...)
        self._images(...)
        Sauvegarde.lire(...)
        self._verifier(...)
        self._fermer_jeu(...)
        self._cliquer(...)
        self._centre(...)
        Sauvegarde.ecrire(...)

    def _ingredients_moulin(self, inventaire: Inventaire) -> 'void':
        Inventaire.ajouter(...)

    def _ingredients_filet(self, inventaire: Inventaire) -> 'void':
        Inventaire.ajouter(...)

    def _test_machines_logique(self) -> 'void':
        self._verifier(...)
        Atelier.machines_disponibles(...)
        Atelier.emplacements_libres(...)
        Atelier.construire_machine(...)
        self._ingredients_moulin(...)
        Inventaire.total(...)
        Atelier.nombre_machines(...)
        self._ingredients_filet(...)
        Atelier.peut_construire_machine(...)
        Inventaire.quantite(...)
        Atelier.charger_machines(...)

    def _test_machines_ile(self) -> 'void':
        self._son(...)
        self._ouvrir_ile(...)
        self._souris(...)
        self._images(...)
        self._verifier(...)
        self._cliquer(...)
        self._ingredients_moulin(...)
        self._ingredients_filet(...)
        self._fermer_ile(...)

    def _test_machines_sauvegarde(self) -> 'void':
        """Machines : sauvegarde, production pendant la plongée et jeu fermé (dans la limite de la réserve)."""
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._ingredients_moulin(...)
        self._images(...)
        Sauvegarde.lire(...)
        self._verifier(...)
        Sauvegarde.ecrire(...)
        self._fermer_jeu(...)
        self._cliquer(...)
        self._centre(...)

    def _ingredients(self, inventaire: Inventaire, ingredients: 'Dictionary') -> 'void':
        Inventaire.ajouter(...)

    def _test_palier2_logique(self) -> 'void':
        self._verifier(...)
        Atelier.decouvrir(...)
        self._ingredients(...)
        Atelier.machine(...)
        Atelier.peut_construire_machine(...)
        Atelier.machines_disponibles(...)
        Atelier.construire_machine(...)
        Inventaire.total(...)
        Atelier.emplacements_libres(...)
        Atelier.nombre_machines(...)
        Inventaire.ajouter(...)
        Atelier.construire(...)
        Atelier.est_relie(...)
        Atelier.peut_ameliorer_machine(...)
        Atelier.prochaine_amelioration_machine(...)
        Atelier.ameliorer_machine(...)
        Atelier.recharge_machine(...)
        Atelier.plafond_machine(...)
        Atelier.machines_ameliorables(...)
        Atelier.charger_niveaux_machines(...)
        Atelier.places_sac(...)
        Atelier.ameliorer(...)
        Atelier.charger_palier(...)

    def _test_palier2_ile(self) -> 'void':
        self._son(...)
        self._ouvrir_ile(...)
        self._ingredients(...)
        self._verifier(...)
        self._images(...)
        self._cliquer(...)
        self._souris(...)
        self._secondes(...)
        self._fermer_ile(...)

    def _test_palier2_sauvegarde(self) -> 'void':
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._ingredients(...)
        Atelier.machine(...)
        Atelier.construire_machine(...)
        Atelier.construire(...)
        Atelier.prochaine_amelioration_machine(...)
        Atelier.ameliorer_machine(...)
        self._fermer_jeu(...)
        self._images(...)
        self._verifier(...)
        self._cliquer(...)
        self._centre(...)

    def _test_sac_12(self) -> 'void':
        self._demarrer(...)
        self._verifier(...)
        self._terminer(...)

    def _aller_retour(self, fond: 'float') -> 'Array':
        """Aller-retour à pleine vitesse jusqu'à « fond » px ; renvoie [oxygène à 300 m, au fond, en surface, remontée auto]."""
        self._images(...)

    def _test_budget_faille(self) -> 'void':
        Donnees.charger_json(...)
        self._demarrer(...)
        self._aller_retour(...)
        self._verifier(...)
        self._terminer(...)

    def _test_lueur_braise(self) -> 'void':
        """Pierres de braise : leur lueur n'est jamais assombrie (même règle que le cyan et le corail)."""
        Palette.couleur(...)
        self._verifier(...)
        ArtAbysse.assombrir(...)
        ArtAbysse.lueur(...)

    def _couper_son_et_quitter(self, code: 'int') -> 'void':
        """Coupe le son quelques images avant de quitter (le serveur audio relâche alors ses lectures)."""
        ...

    def _son(self) -> 'Node':
        ...

    def _test_synthese(self) -> 'void':
        Synthe.effets(...)
        Synthe.echantillons(...)
        self._verifier(...)
        Synthe.ambiances(...)
        Synthe.effet(...)

    def _test_bus_et_volumes(self) -> 'void':
        self._son(...)
        self._verifier(...)

    def _test_ambiances(self) -> 'void':
        self._son(...)
        self._secondes(...)
        self._verifier(...)

    def _test_sons_ile(self) -> 'void':
        self._son(...)
        self._ouvrir_ile(...)
        self._nuage_degage(...)
        self._cliquer(...)
        self._verifier(...)
        self._souris(...)
        self._images(...)
        self._bouton(...)
        self._secondes(...)
        self._fermer_ile(...)

    def _test_sons_plongee(self) -> 'void':
        self._son(...)
        self._demarrer(...)
        self._gisements(...)
        self._secondes(...)
        self._verifier(...)
        self._images(...)
        self._terminer(...)

    def _test_sons_transitions(self) -> 'void':
        self._son(...)
        self._ouvrir_jeu(...)
        self._touche(...)
        self._images(...)
        self._verifier(...)
        self._attendre_etat(...)
        self._remonter(...)
        self._fermer_jeu(...)

    def _test_volumes_sauvegarde(self) -> 'void':
        self._son(...)
        self._effacer_sauvegarde(...)
        self._ouvrir_jeu(...)
        self._touche(...)
        self._images(...)
        self._cliquer(...)
        self._verifier(...)
        Sauvegarde.lire(...)
        self._fermer_jeu(...)
        Sauvegarde.ecrire(...)
