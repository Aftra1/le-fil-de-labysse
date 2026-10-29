# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/inventaire.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Inventaire unique : ressources du ciel et minerais de plongée.
"""

from __future__ import annotations

from ..godot import RefCounted


class Inventaire(RefCounted):
    PLAFOND = 99
    _quantites: 'Dictionary'

    def quantite(self, id: 'String') -> 'int':
        ...

    def place(self, id: 'String') -> 'int':
        """Place restante avant le plafond pour cette ressource."""
        self.quantite(...)

    def ajouter(self, id: 'String', nombre: 'int') -> 'int':
        """Ajoute dans la limite du plafond ; renvoie la quantité réellement ajoutée."""
        self.place(...)
        self.quantite(...)

    def ajouter_tout(self, butin: 'Dictionary') -> 'Dictionary':
        """Ajoute un butin { id: nombre } ; renvoie ce qui n'a pas pu entrer."""
        self.ajouter(...)

    def retirer(self, id: 'String', nombre: 'int') -> 'bool':
        self.quantite(...)

    def total(self) -> 'int':
        ...

    def vers_dictionnaire(self) -> 'Dictionary':
        """Quantités non nulles { id: nombre }."""
        ...

    @staticmethod
    def depuis_dictionnaire(donnees: 'Dictionary', ids_connus: 'Array') -> Inventaire:
        """Inventaire lu depuis une sauvegarde : identifiants inconnus ignorés, quantités bornées à 0..PLAFOND."""
        Inventaire.ajouter(...)
