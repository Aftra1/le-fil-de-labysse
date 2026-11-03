# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/carnet.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Carnet de collection : les trouvailles rares de l'abysse (data/trouvailles.json) et les machines déjà
construites. Quatre pages : Perles du Lagon, Fossiles des Coraux, Reliques de la Faille (6 trouvailles
chacune) et Machines (une case par sorte de machine). Une page complète donne un bonus durable.
Le carnet appartient à la partie (gardé par l'atelier, enregistré dans la sauvegarde).
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.donnees import Donnees


class Carnet(RefCounted):
    PAGES_TROUVAILLES = ...
    trouvees: 'Array'
    machines_vues: 'Array'
    a_voir: 'String'
    _donnees: 'Dictionary'
    _machines: 'Array'

    def _init(self) -> 'void':
        Donnees.charger_json(...)

    def pages(self) -> 'Array':
        """Pages : [{ id, titre, bonus, … }], dans l'ordre d'affichage."""
        ...

    def page(self, id: 'String') -> 'Dictionary':
        self.pages(...)

    def cases(self, id_page: 'String') -> 'Array':
        """Identifiants des cases d'une page (trouvailles de la zone, ou sortes de machines)."""
        ...

    def trouvaille(self, id: 'String') -> 'Dictionary':
        """Réglages d'une trouvaille : { id, zone, nom, description } (vide si elle est inconnue)."""
        ...

    def chance_par_zone(self) -> 'float':
        ...

    def duree_minage(self) -> 'float':
        ...

    def a_trouve(self, id: 'String') -> 'bool':
        ...

    def trouver(self, id: 'String') -> 'bool':
        """Note une trouvaille ; renvoie vrai si elle est nouvelle."""
        self.trouvaille(...)

    def voir_machine(self, id: 'String') -> 'void':
        ...

    def restantes(self, zone: 'String') -> 'Array':
        """Trouvailles de cette zone pas encore découvertes."""
        self.cases(...)

    def est_dans_carnet(self, id_page: 'String', id: 'String') -> 'bool':
        ...

    def remplies(self, id_page: 'String') -> 'int':
        self.cases(...)
        self.est_dans_carnet(...)

    def page_complete(self, id_page: 'String') -> 'bool':
        self.remplies(...)
        self.cases(...)

    def pourcentage(self) -> 'int':
        """Pourcentage du carnet rempli (trouvailles et machines), arrondi à l'entier inférieur."""
        self.pages(...)
        self.cases(...)
        self.remplies(...)

    def facteur_minage(self, zone: 'String') -> 'float':
        """Vitesse de minage dans une zone (page de ses trouvailles complète : ×1,25)."""
        self.page(...)
        self.page_complete(...)

    def facteur_oxygene(self, zone: 'String') -> 'float':
        """Consommation d'air dans une zone (page de la Faille complète : ×0,8 dans la Faille)."""
        self.page(...)
        self.page_complete(...)

    def places_sac_bonus(self) -> 'int':
        """Places de sac en plus (page des perles complète : +1)."""
        self.pages(...)
        self.page_complete(...)

    def facteur_machines(self) -> 'float':
        """Vitesse de production des machines (page des machines complète : ×1,1)."""
        self.page(...)
        self.page_complete(...)

    def vers_dictionnaire(self) -> 'Dictionary':
        ...

    def charger(self, donnees: 'Dictionary') -> 'void':
        """Carnet lu depuis une sauvegarde : identifiants inconnus et doublons ignorés."""
        self.trouver(...)
        self.voir_machine(...)
