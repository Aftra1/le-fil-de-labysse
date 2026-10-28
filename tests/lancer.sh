#!/usr/bin/env bash
# Lance tous les tests de logique en une commande (Godot sans fenêtre).
# Usage : tests/lancer.sh            (utilise « godot » du PATH)
#         GODOT=/chemin/vers/godot tests/lancer.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# Miroir Python et docs/architecture.md à jour (python3 tests/generer_miroir.py pour les régénérer).
if command -v python3 >/dev/null; then
	python3 tests/generer_miroir.py --verifier
else
	echo "python3 absent : vérification du miroir (docs/miroir/) sautée"
fi
exec "${GODOT:-godot}" --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
