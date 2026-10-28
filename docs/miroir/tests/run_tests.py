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
        ...

    def _lancer(self) -> 'void':
        ...

    def _titre(self, texte: 'String') -> 'void':
        ...

    def _verifier(self, condition: 'bool', nom: 'String', detail: 'String') -> 'void':
        ...

    def _images(self, nombre: 'int') -> 'void':
        ...

    def _secondes(self, duree: 'float') -> 'void':
        ...

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
        ...

    def _bouton(self, point: 'Vector2', appuye: 'bool') -> 'void':
        ...

    def _cliquer(self, point: 'Vector2') -> 'void':
        ...

    def _touche(self, code: 'Key') -> 'void':
        ...

    def _gisements(self) -> 'Array[Gisement]':
        ...

    def _test_inertie(self) -> 'void':
        ...

    def _test_flottabilite(self) -> 'void':
        ...

    def _test_bornes(self) -> 'void':
        ...

    def _test_oxygene_baisse_et_recharge(self) -> 'void':
        ...

    def _test_remontee_automatique(self) -> 'void':
        ...

    def _test_budget_oxygene(self) -> 'void':
        ...

    def _test_sac(self) -> 'void':
        Sac.ajouter(...)
        Sac.perdre(...)
        Sac.compter(...)
        Sac.vider(...)

    def _test_placement(self) -> 'void':
        Donnees.charger_json(...)

    def _test_minage(self) -> 'void':
        ...

    def _test_minage_hors_portee(self) -> 'void':
        ...

    def _test_sac_plein(self) -> 'void':
        ...

    def _test_perte_de_butin(self) -> 'void':
        ...

    def _test_armement(self) -> 'void':
        ...

    def _test_inventaire(self) -> 'void':
        Inventaire.ajouter(...)
        Inventaire.ajouter_tout(...)

    def _source(self, plafond: 'int', recharge_s: 'float') -> SourceRessource:
        ...

    def _test_sources(self) -> 'void':
        Donnees.charger_json(...)
        SourceRessource.recharger(...)

    def _ouvrir_ile(self) -> 'Node':
        Inventaire()

    def _fermer_ile(self, ile: 'Node') -> 'void':
        ...

    def _test_recolte(self) -> 'void':
        ...

    def _test_panneau_inventaire(self) -> 'void':
        ...

    def _test_lancer_plongee_depuis_ile(self) -> 'void':
        ...

    def _ouvrir_jeu(self, avec_titre: 'bool') -> 'Node':
        Inventaire()

    def _fermer_jeu(self, jeu: 'Node') -> 'void':
        ...

    def _attendre_etat(self, jeu: 'Node', etat: 'int', limite: 'float') -> 'float':
        """Attend un état du jeu ; renvoie le temps écoulé (ou -1 si dépassé)."""
        ...

    def _remonter(self, jeu: 'Node') -> 'void':
        """Termine la plongée en cours : la cloche passe sous 10 m puis revient en surface."""
        ...

    def _test_scene_principale(self) -> 'void':
        ...

    def _test_transitions(self) -> 'void':
        ...

    def _plongee_de(self, duree: 'float') -> 'Array':
        """Vide les sources de l'île, plonge « duree » secondes, revient ;
    renvoie [vent, plafond vent, cristaux, plafond cristaux, temps sous l'eau]."""
        ...

    def _test_recharge_pendant_plongee(self) -> 'void':
        ...

    def _test_flux_urgence(self) -> 'void':
        ...

    def _test_rendu_pixel(self) -> 'void':
        Palette.noms(...)
        Palette.rampe(...)
        Palette.plus_sombre(...)
        Donnees.charger_json(...)
        Palette.contient(...)
        Pixel.motif(...)

    def _test_monde_320(self) -> 'void':
        ...

    def _test_camera_plongee(self) -> 'void':
        ...

    def _test_glissement_hud(self) -> 'void':
        ...

    def _test_atelier_logique(self) -> 'void':
        Inventaire.ajouter(...)
        Inventaire.quantite(...)
        Atelier.rayon_halo(...)
        Atelier.obscurite_max(...)

    def _test_atelier_ile(self) -> 'void':
        ...

    def _test_limite_cable(self) -> 'void':
        ...

    def _test_reservoir(self) -> 'void':
        ...

    def _test_obscurite_regles(self) -> 'void':
        ArtAbysse.niveau_obscurite(...)
        ArtAbysse.crans_halo(...)
        Palette.couleur(...)

    def _test_equilibre(self) -> 'void':
        """Simulation prudente de la boucle : entre deux plongées, l'île donne 5 vents, 6 nuages et 3 cristaux
    solaires ; une plongée rapporte un sac de 8 (lagon seulement tant que le câble fait 150 m).
    On fabrique ce qui sert à la prochaine amélioration. Tout doit être débloqué en 6 plongées au plus."""
        Atelier.niveau(...)
        Inventaire.ajouter(...)
        Atelier.ameliorer(...)
        Inventaire.quantite(...)
        Atelier.fabriquer(...)

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
        Sauvegarde.lire(...)
        Sauvegarde.ecrire(...)
        Sauvegarde.mettre_de_cote_version_recente(...)

    def _test_sauvegarde_contenu(self) -> 'void':
        """Valeurs fausses ou incomplètes : ignorées ou ramenées dans les limites."""
        Sauvegarde.migrer(...)
        Inventaire.depuis_dictionnaire(...)
        Atelier.charger_niveaux(...)
        Atelier.niveau(...)
        SourceRessource.restaurer(...)
        Sauvegarde.secondes_depuis(...)

    def _test_sauvegarde_jeu(self) -> 'void':
        """Sauvegarder une partie, puis la reprendre par l'écran titre ; rattrapage du temps jeu fermé."""
        Sauvegarde.ecrire(...)

    def _inventaire_sauve(self) -> 'Dictionary':
        Sauvegarde.lire(...)

    def _test_sauvegarde_automatique(self) -> 'void':
        """Moments de sauvegarde : fabrication, départ, fermeture en plongée (état du départ), retour."""
        ...

    def _centre(self, controle: 'Control') -> 'Vector2':
        ...

    def _test_ecran_titre(self) -> 'void':
        ...

    def _test_pause_ile(self) -> 'void':
        ...

    def _test_pause_plongee(self) -> 'void':
        ...

    def _test_echap_transition(self) -> 'void':
        """Échap pendant la descente et la remontée : ignoré (ni pause, ni transition passée)."""
        ...

    def _ingredients_passerelle(self, inventaire: Inventaire) -> 'void':
        Inventaire.ajouter(...)

    def _test_ilot_logique(self) -> 'void':
        Atelier.charger_ilots(...)

    def _test_ilot_ile(self) -> 'void':
        ...

    def _test_ilot_sauvegarde(self) -> 'void':
        """Aller-retour sauvegarde / chargement avec l'îlot relié (liste des îlots, stock du bassin)."""
        Sauvegarde.lire(...)
        Sauvegarde.ecrire(...)

    def _aller_retour(self, fond: 'float') -> 'Array':
        """Aller-retour à pleine vitesse jusqu'à « fond » px ; renvoie [oxygène à 300 m, au fond, en surface, remontée auto]."""
        ...

    def _test_budget_faille(self) -> 'void':
        ...

    def _test_lueur_braise(self) -> 'void':
        """Pierres de braise : leur lueur n'est jamais assombrie (même règle que le cyan et le corail)."""
        Palette.couleur(...)
