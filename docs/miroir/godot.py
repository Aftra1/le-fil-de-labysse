# Fichier généré automatiquement, ne pas modifier.
# Régénérer : python3 tests/generer_miroir.py
"""Classes de Godot dont héritent les scripts du jeu (noms seulement)."""


class Signal:
    """Signal Godot (paramètres en texte)."""

    def __init__(self, parametres: str = '') -> None:
        self.parametres = parametres

    def connect(self, *args) -> None:
        ...

    def emit(self, *args) -> None:
        ...


class CanvasLayer:
    ...


class CharacterBody2D:
    ...


class Node:
    ...


class Node2D:
    ...


class RefCounted:
    ...


class SceneTree:
    ...
