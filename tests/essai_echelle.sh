#!/usr/bin/env bash
# Essai comparatif 640x360 / 320x180 de l'île (Xvfb + rendu logiciel Mesa/llvmpipe).
# Usage : tests/essai_echelle.sh   (GODOT=/chemin/vers/godot si « godot » n'est pas dans le PATH)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p docs/captures
export LIBGL_ALWAYS_SOFTWARE=1
exec xvfb-run -a -s "-screen 0 1280x720x24" \
	"${GODOT:-godot}" --path . --rendering-driver opengl3 --script res://tests/essai_echelle.gd
