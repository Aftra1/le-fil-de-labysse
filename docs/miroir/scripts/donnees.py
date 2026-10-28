# Fichier généré automatiquement, ne pas modifier.
# Source : scripts/donnees.gd (le jeu n'utilise que le GDScript).
# Régénérer : python3 tests/generer_miroir.py
"""Lecture des fichiers de données du dossier data/.
"""

from __future__ import annotations

from ..godot import RefCounted


class Donnees(RefCounted):
    @staticmethod
    def charger_json(chemin: 'String') -> 'Variant':
        ...
