# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/sac.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Le sac de la cloche : une unité de minerai = un emplacement.
"""

from __future__ import annotations

from ..godot import RefCounted


class Sac(RefCounted):
    CAPACITE = 8
    _unites: 'Array[String]'

    def nombre(self) -> 'int':
        ...

    def est_plein(self) -> 'bool':
        ...

    def ajouter(self, minerai: 'String') -> 'bool':
        self.est_plein(...)

    def compter(self) -> 'Dictionary':
        """Nombre d'unités par minerai : { "cristal": 3, "corail": 1 }"""
        ...

    def vider(self) -> 'Dictionary':
        """Vide le sac et renvoie son contenu."""
        self.compter(...)

    def perdre(self, fraction: 'float', hasard: 'RandomNumberGenerator') -> 'Dictionary':
        """Perd une fraction des unités, tirées au hasard (arrondi à l'inférieur).
        Renvoie ce qui a été perdu."""
        ...
