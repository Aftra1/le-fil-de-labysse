# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/marchand.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Le vieux marchand de vent (data/marchand.json) : son dirigeable passe au-dessus de l'île environ toutes
les 4 min de jeu (île et plongée comptées, pas le jeu fermé) et reste 60 s. S'il arrive pendant une
plongée, il attend le retour sur l'île et reste alors ses 60 s ; s'il était déjà là, il ne repart jamais
pendant une plongée : au retour, il reste encore au moins 20 s (« reste_au_retour_s »).
À chaque passage, il propose 3 échanges tirés parmi ceux du palier atteint (chacun une fois) et dit une
réplique (une par visite, dans l'ordre). Il ne rachète que des surplus (surtout les ouates du filet)
contre des ressources de la surface : jamais un minerai de l'abysse ni ce qui en est fait (« interdits »),
pour qu'aucun échange ne remplace une plongée. Aucun échange n'est obligatoire, rien n'est perdu
si on le manque. Il appartient à la partie (gardé par l'atelier, enregistré dans la sauvegarde).
"""

from __future__ import annotations

from ..godot import RefCounted
from ..scripts.donnees import Donnees
from ..scripts.inventaire import Inventaire


class Marchand(RefCounted):
    attente: 'float'
    restant: 'float'
    offres: 'Array'
    faits: 'Array'
    visites: 'int'
    vendu: 'Dictionary'
    recu: 'Dictionary'
    _donnees: 'Dictionary'
    _hasard: 'RandomNumberGenerator'

    def _init(self) -> 'void':
        Donnees.charger_json(...)

    def duree(self) -> 'float':
        ...

    def intervalle(self) -> 'float':
        ...

    def echanges(self) -> 'Array':
        """Tous les échanges : [{ id, palier, donne, recoit }], dans l'ordre du fichier de données."""
        ...

    def echange(self, id: 'String') -> 'Dictionary':
        self.echanges(...)

    def interdits(self) -> 'Array':
        """Ce que le marchand ne donne jamais (minerais de l'abysse et ce qui en est fait)."""
        ...

    def repliques(self) -> 'Array':
        ...

    def replique(self) -> 'String':
        """Réplique du passage en cours (ou du dernier)."""
        self.repliques(...)

    def est_present(self) -> 'bool':
        ...

    def temps_present(self) -> 'float':
        """Secondes depuis son arrivée (pour l'animation du dirigeable)."""
        self.duree(...)
        self.est_present(...)

    def avancer(self, secondes: 'float', sur_ile: 'bool', palier: 'int') -> 'String':
        """Fait avancer le temps de « secondes ». Sur l'île : il arrive quand l'attente est finie, puis repart à
        la fin de son passage ; hors de l'île (plongée) : l'attente avance sans jamais le faire arriver, et son
        passage aussi, sans le faire partir (il reste au moins « reste_au_retour_s » pour le retour).
        Renvoie « arrivee », « depart » ou une chaîne vide."""
        self.est_present(...)
        self.intervalle(...)
        self.arriver(...)

    def arriver(self, palier: 'int') -> 'void':
        """Début d'un passage : offres tirées parmi les échanges du palier (complétées par les paliers d'avant
        s'il en manque), et réplique suivante."""
        self.duree(...)
        self.echanges(...)

    def peut_echanger(self, id: 'String', inventaire: Inventaire) -> 'bool':
        """Vrai si cet échange est proposé maintenant, pas encore fait, payable et rangeable dans l'inventaire."""
        self.est_present(...)
        self.echange(...)
        Inventaire.quantite(...)
        Inventaire.place(...)

    def echanger(self, id: 'String', inventaire: Inventaire) -> 'bool':
        self.peut_echanger(...)
        self.echange(...)
        Inventaire.retirer(...)
        Inventaire.ajouter(...)

    def vers_dictionnaire(self) -> 'Dictionary':
        ...

    def charger(self, donnees: 'Dictionary') -> 'void':
        """Marchand lu depuis une sauvegarde : valeurs bornées, échanges inconnus ignorés. Sans données (sauvegarde
        d'avant le marchand), il passe pour la première fois après l'attente habituelle."""
        self._nombre(...)
        self.intervalle(...)
        self.duree(...)
        self.echange(...)
        self.est_present(...)

    def _nombre(self, valeur, defaut: 'float', minimum: 'float', maximum: 'float') -> 'float':
        ...
