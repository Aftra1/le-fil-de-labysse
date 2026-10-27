#!/usr/bin/env bash
# Lance tous les tests de logique en une commande (Godot sans fenêtre).
# Usage : tests/lancer.sh            (utilise « godot » du PATH)
#         GODOT=/chemin/vers/godot tests/lancer.sh
set -euo pipefail
cd "$(dirname "$0")/.."
exec "${GODOT:-godot}" --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
