#!/usr/bin/env bash
# Enregistre les 5 captures dans docs/captures/ (Xvfb + rendu logiciel Mesa/llvmpipe).
# Usage : tests/captures.sh            (utilise « godot » du PATH)
#         GODOT=/chemin/vers/godot tests/captures.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p docs/captures
export LIBGL_ALWAYS_SOFTWARE=1
exec xvfb-run -a -s "-screen 0 1280x720x24" \
	"${GODOT:-godot}" --path . --rendering-driver opengl3 --fixed-fps 60 --script res://tests/captures.gd
