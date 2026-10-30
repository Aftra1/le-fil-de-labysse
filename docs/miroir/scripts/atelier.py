# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/atelier.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json)
et installe les améliorations de la cloche, niveau par niveau.
Les effets des niveaux (longueur du câble, halo, oxygène) sont dans data/ameliorations.json.
Les niveaux installés sont gardés ici et enregistrés dans la sauvegarde (voir charger_niveaux).
Construit aussi les passerelles qui relient les îlots à l'île (une construction = un îlot relié)
et les machines de l'île (data/machines.json), chacune sur un emplacement libre (la foreuse sur un
filon). Les machines sont rangées par paliers : le palier 2 s'ouvre au premier corail rapporté,
le palier 3 à la première pierre de braise (voir decouvrir). À partir du palier 2, chaque sorte de
machine s'améliore : vitesse (production plus rapide) et capacité (réserve plus grande) ; le niveau 2
se paie en matériaux raffinés. Le fourneau (palier 3) fabrique en boucle le raffiné choisi pour lui,
avec les ingrédients de l'inventaire (voir consommer_fourneau).
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.carnet import Carnet
from ..scripts.donnees import Donnees
from ..scripts.inventaire import Inventaire
from ..scripts.marchand import Marchand


class Atelier(RefCounted):
    AMELIORATIONS = ...
    CONSTRUCTIONS = ...
    PALIERS = ...
    GENRES_AMELIORATION = ...
    inventaire: Inventaire
    niveaux: 'Dictionary'
    ilots_relies: 'Array'
    machines: 'Dictionary'
    palier: 'int'
    niveaux_machines: 'Dictionary'
    recettes_fourneau: 'Dictionary'
    depenses: 'Dictionary'
    consomme_fourneau: 'Dictionary'
    carnet: Carnet
    marchand: Marchand
    _recettes: 'Dictionary'
    _effets: 'Dictionary'
    _machines: 'Dictionary'

    def _init(self, inventaire_joueur: Inventaire) -> 'void':
        Donnees.charger_json(...)

    def composants(self) -> 'Array':
        ...

    def ingredients_composant(self, id: 'String') -> 'Dictionary':
        ...

    def peut_fabriquer(self, id: 'String') -> 'bool':
        self.manquants(...)
        self.ingredients_composant(...)
        Inventaire.place(...)

    def fabriquer(self, id: 'String') -> 'bool':
        self.peut_fabriquer(...)
        self._payer(...)
        self.ingredients_composant(...)
        Inventaire.ajouter(...)

    def nom_amelioration(self, id: 'String') -> 'String':
        ...

    def niveau(self, id: 'String') -> 'int':
        ...

    def niveau_max(self, id: 'String') -> 'int':
        ...

    def est_au_maximum(self, id: 'String') -> 'bool':
        self.niveau(...)
        self.niveau_max(...)

    def prochain_niveau(self, id: 'String') -> 'Dictionary':
        """Recette du prochain niveau (vide si l'amélioration est au maximum)."""
        self.est_au_maximum(...)
        self.recette_niveau(...)
        self.niveau(...)

    def recette_niveau(self, id: 'String', cible: 'int') -> 'Dictionary':
        """Recette d'un niveau donné (1 = premier niveau), vide s'il n'existe pas."""
        ...

    def peut_ameliorer(self, id: 'String') -> 'bool':
        self.prochain_niveau(...)
        self.manquants(...)

    def ameliorer(self, id: 'String') -> 'bool':
        self.peut_ameliorer(...)
        self._payer(...)
        self.prochain_niveau(...)
        self.niveau(...)

    def charger_niveaux(self, donnees: 'Dictionary') -> 'void':
        """Niveaux lus depuis une sauvegarde : améliorations inconnues ignorées, niveaux bornés à 0..max."""
        self.niveau_max(...)

    def nom_construction(self, id: 'String') -> 'String':
        ...

    def ingredients_construction(self, id: 'String') -> 'Dictionary':
        ...

    def effet_construction(self, id: 'String') -> 'String':
        ...

    def annonce_construction(self, id: 'String') -> 'String':
        """Message affiché sur l'île une fois la construction faite."""
        self.nom_construction(...)

    def ilot_de(self, id: 'String') -> 'String':
        """Îlot relié par cette construction."""
        ...

    def est_construite(self, id: 'String') -> 'bool':
        self.est_relie(...)
        self.ilot_de(...)

    def est_relie(self, ilot: 'String') -> 'bool':
        ...

    def peut_construire(self, id: 'String') -> 'bool':
        self.est_construite(...)
        self.manquants(...)
        self.ingredients_construction(...)

    def construire(self, id: 'String') -> 'bool':
        self.peut_construire(...)
        self._payer(...)
        self.ingredients_construction(...)
        self.ilot_de(...)

    def charger_ilots(self, donnees: 'Array') -> 'void':
        """Îlots lus depuis une sauvegarde : seuls les îlots connus sont gardés, sans doublon."""
        self.ilot_de(...)

    def liste_machines(self) -> 'Array':
        """Identifiants des machines, dans l'ordre du fichier de données."""
        ...

    def machines_disponibles(self) -> 'Array':
        """Machines des paliers atteints (celles que l'atelier propose)."""
        self.liste_machines(...)
        self.machine(...)

    def machine(self, id: 'String') -> 'Dictionary':
        """Réglages d'une machine : nom, palier, ressource, recharge_s, plafond, ingredients, effet, ameliorations."""
        ...

    def nom_machine(self, id: 'String') -> 'String':
        self.machine(...)

    def sur_filon(self, id: 'String') -> 'bool':
        self.machine(...)

    def en_plongee(self, id: 'String') -> 'bool':
        """Vrai pour une machine qui ne produit que pendant les plongées (sonde)."""
        self.machine(...)

    def decouvrir(self, ids: 'Array') -> 'bool':
        """Note les ressources rapportées d'une plongée ; renvoie vrai si un nouveau palier s'ouvre."""
        ...

    def charger_palier(self, valeur) -> 'void':
        """Palier lu depuis une sauvegarde. Une sauvegarde d'avant les paliers n'en a pas : on le déduit de ce
        qui a déjà coûté du corail ou de la pierre de braise (lanterne, réservoir, passerelle) et de l'inventaire."""
        self.niveau(...)
        self.est_relie(...)
        Inventaire.quantite(...)
        self.decouvrir(...)

    def emplacements(self) -> 'Array':
        """Emplacements : [{ id, nom, position, ilot, filon? }], dans l'ordre du fichier de données."""
        ...

    def emplacement(self, id: 'String') -> 'Dictionary':
        self.emplacements(...)

    def est_filon(self, id: 'String') -> 'bool':
        """Vrai pour un emplacement de foreuse (un filon de cristal solaire)."""
        self.emplacement(...)

    def emplacement_accessible(self, id: 'String') -> 'bool':
        """Un emplacement est utilisable s'il est sur l'île ou sur un îlot relié."""
        self.emplacement(...)
        self.est_relie(...)

    def emplacement_libre(self, id: 'String') -> 'bool':
        self.emplacement_accessible(...)

    def emplacements_libres(self, id: 'String') -> 'Array':
        """Emplacements accessibles et libres pour cette machine (sans machine : les emplacements au sol),
        dans l'ordre du fichier de données."""
        self.sur_filon(...)
        self.emplacements(...)
        self.emplacement_libre(...)
        self.est_filon(...)

    def nombre_machines(self, id: 'String') -> 'int':
        """Nombre de machines « id » construites."""
        ...

    def peut_construire_machine(self, id: 'String') -> 'bool':
        self.machine(...)
        self.emplacements_libres(...)
        self.manquants(...)

    def construire_machine(self, id: 'String', cible: 'String') -> 'String':
        """Construit la machine sur « cible » si cet emplacement lui convient et est libre, sinon sur le
        premier qui convient. Renvoie l'emplacement choisi (vide si la construction est impossible)."""
        self.peut_construire_machine(...)
        self.emplacements_libres(...)
        self._payer(...)
        self.machine(...)
        Carnet.voir_machine(...)
        self._appliquer_entrepot(...)

    def charger_machines(self, donnees: 'Dictionary') -> 'void':
        """Machines lues depuis une sauvegarde : emplacements et machines inconnus ignorés.
        À appeler après charger_ilots (un emplacement d'îlot n'existe que si l'îlot est relié)."""
        self.emplacement_libre(...)
        self.est_filon(...)
        self.sur_filon(...)
        Carnet.voir_machine(...)
        self._appliquer_entrepot(...)

    def _appliquer_entrepot(self) -> 'void':
        """Un entrepôt construit relève le plafond de l'inventaire (plusieurs entrepôts ne s'additionnent pas)."""
        self.machine(...)
        self.niveau_machine(...)
        Inventaire.borner(...)

    def machines_ameliorables(self) -> 'Array':
        """Sortes de machines qui s'améliorent (le fourneau ne s'améliore pas)."""
        self.liste_machines(...)
        self.machine(...)

    def niveau_machine(self, id: 'String', genre: 'String') -> 'int':
        ...

    def niveau_machine_max(self, id: 'String', genre: 'String') -> 'int':
        self.machine(...)

    def genres_amelioration(self, id: 'String') -> 'Array':
        """Améliorations proposées pour cette sorte de machine (« vitesse », « capacite » ; l'entrepôt : capacité)."""
        self.machine(...)

    def facteur(self, genre: 'String', niveau: 'int') -> 'float':
        """Multiplicateur de vitesse ou de réserve à un niveau donné."""
        ...

    def prochaine_amelioration_machine(self, id: 'String', genre: 'String') -> 'Dictionary':
        """Ingrédients du prochain niveau (vide au niveau maximal)."""
        self.niveau_machine(...)
        self.niveau_machine_max(...)
        self.machine(...)

    def peut_ameliorer_machine(self, id: 'String', genre: 'String') -> 'bool':
        """Possible dès le palier 2, si au moins une machine de cette sorte est construite."""
        self.prochaine_amelioration_machine(...)
        self.nombre_machines(...)
        self.manquants(...)

    def ameliorer_machine(self, id: 'String', genre: 'String') -> 'bool':
        self.peut_ameliorer_machine(...)
        self._payer(...)
        self.prochaine_amelioration_machine(...)
        self.niveau_machine(...)
        self._appliquer_entrepot(...)

    def recharge_machine(self, id: 'String') -> 'float':
        """Secondes par unité produite, vitesse comprise."""
        self.machine(...)
        self.niveau_machine(...)
        Carnet.facteur_machines(...)

    def plafond_machine(self, id: 'String') -> 'int':
        """Réserve d'une machine, capacité comprise."""
        self.machine(...)
        self.niveau_machine(...)

    def plafond_entrepot_suivant(self) -> 'int':
        """Plafond de l'inventaire que donnerait le prochain niveau de l'entrepôt."""
        self.machine(...)
        self.niveau_machine(...)

    def raffines(self) -> 'Array':
        """Raffinés que le fourneau sait faire, dans l'ordre du fichier de données."""
        self.machine(...)

    def recette_raffine(self, raffine: 'String') -> 'Dictionary':
        """Ingrédients d'un cycle du fourneau pour ce raffiné."""
        self.machine(...)

    def recette_fourneau(self, lieu: 'String') -> 'String':
        ...

    def choisir_recette_fourneau(self, lieu: 'String', raffine: 'String') -> 'bool':
        self.raffines(...)

    def consommer_fourneau(self, raffine: 'String') -> 'bool':
        """Un cycle du fourneau : prend les ingrédients dans l'inventaire s'ils y sont (vrai), sinon rien (faux)."""
        self.manquants(...)
        self.recette_raffine(...)
        Inventaire.retirer(...)

    def charger_fourneaux(self, donnees: 'Dictionary') -> 'void':
        """Recettes des fourneaux lues depuis une sauvegarde (à appeler après charger_machines)."""
        self.raffines(...)

    def charger_niveaux_machines(self, donnees: 'Dictionary') -> 'void':
        """Améliorations lues depuis une sauvegarde : sortes et genres inconnus ignorés, niveaux bornés."""
        self.machines_ameliorables(...)
        self.niveau_machine_max(...)
        self._appliquer_entrepot(...)

    def longueur_cable_m(self) -> 'float':
        self._effet(...)

    def rayon_halo(self) -> 'float':
        self._effet(...)

    def obscurite_max(self) -> 'int':
        self._effet(...)

    def oxygene_max(self) -> 'float':
        self._effet(...)

    def places_sac(self) -> 'int':
        """Places du sac : niveau du sac, plus la place offerte par la page des perles du carnet."""
        self._effet(...)
        Carnet.places_sac_bonus(...)

    def manquants(self, ingredients: 'Dictionary') -> 'Dictionary':
        """Ce qui manque pour une recette : { id: quantité manquante }."""
        Inventaire.quantite(...)

    def _payer(self, ingredients: 'Dictionary') -> 'void':
        Inventaire.retirer(...)

    def _effet(self, id: 'String', cle: 'String') -> 'float':
        self.niveau(...)
