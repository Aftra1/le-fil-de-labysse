# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/atelier.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Atelier de l'île : fabrique des composants à partir des ressources (data/recettes.json)
et installe les améliorations de la cloche, niveau par niveau.
Les effets des niveaux (longueur du câble, halo, oxygène) sont dans data/ameliorations.json.
Les niveaux installés sont gardés ici et enregistrés dans la sauvegarde (voir charger_niveaux).
Construit aussi les passerelles qui relient les îlots à l'île (une construction = un îlot relié).
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.donnees import Donnees
from ..scripts.inventaire import Inventaire


class Atelier(RefCounted):
    AMELIORATIONS = ...
    CONSTRUCTIONS = ...
    inventaire: Inventaire
    niveaux: 'Dictionary'
    ilots_relies: 'Array'
    _recettes: 'Dictionary'
    _effets: 'Dictionary'

    def _init(self, inventaire_joueur: Inventaire) -> 'void':
        Donnees.charger_json(...)

    def composants(self) -> 'Array':
        ...

    def ingredients_composant(self, id: 'String') -> 'Dictionary':
        ...

    def peut_fabriquer(self, id: 'String') -> 'bool':
        Inventaire.place(...)

    def fabriquer(self, id: 'String') -> 'bool':
        Inventaire.ajouter(...)

    def nom_amelioration(self, id: 'String') -> 'String':
        ...

    def niveau(self, id: 'String') -> 'int':
        ...

    def niveau_max(self, id: 'String') -> 'int':
        ...

    def est_au_maximum(self, id: 'String') -> 'bool':
        ...

    def prochain_niveau(self, id: 'String') -> 'Dictionary':
        """Recette du prochain niveau (vide si l'amélioration est au maximum)."""
        ...

    def recette_niveau(self, id: 'String', cible: 'int') -> 'Dictionary':
        """Recette d'un niveau donné (1 = premier niveau), vide s'il n'existe pas."""
        ...

    def peut_ameliorer(self, id: 'String') -> 'bool':
        ...

    def ameliorer(self, id: 'String') -> 'bool':
        ...

    def charger_niveaux(self, donnees: 'Dictionary') -> 'void':
        """Niveaux lus depuis une sauvegarde : améliorations inconnues ignorées, niveaux bornés à 0..max."""
        ...

    def nom_construction(self, id: 'String') -> 'String':
        ...

    def ingredients_construction(self, id: 'String') -> 'Dictionary':
        ...

    def effet_construction(self, id: 'String') -> 'String':
        ...

    def ilot_de(self, id: 'String') -> 'String':
        """Îlot relié par cette construction."""
        ...

    def est_construite(self, id: 'String') -> 'bool':
        ...

    def est_relie(self, ilot: 'String') -> 'bool':
        ...

    def peut_construire(self, id: 'String') -> 'bool':
        ...

    def construire(self, id: 'String') -> 'bool':
        ...

    def charger_ilots(self, donnees: 'Array') -> 'void':
        """Îlots lus depuis une sauvegarde : seuls les îlots connus sont gardés, sans doublon."""
        ...

    def longueur_cable_m(self) -> 'float':
        ...

    def rayon_halo(self) -> 'float':
        ...

    def obscurite_max(self) -> 'int':
        ...

    def oxygene_max(self) -> 'float':
        ...

    def manquants(self, ingredients: 'Dictionary') -> 'Dictionary':
        """Ce qui manque pour une recette : { id: quantité manquante }."""
        Inventaire.quantite(...)

    def _payer(self, ingredients: 'Dictionary') -> 'void':
        Inventaire.retirer(...)

    def _effet(self, id: 'String', cle: 'String') -> 'float':
        ...
