#!/usr/bin/env bash
# Playtest robot : joue N parties complètes (sans fenêtre) et enregistre les mesures dans
# docs/playtest/mesures-partieN.json ; avec --video, enregistre aussi la séquence de démonstration
# (Xvfb + Movie Maker) et la convertit en MP4 et en GIF dans docs/playtest/.
# Usage : tests/playtest.sh [nombre de parties] [--video]
#         GODOT=/chemin/vers/godot tests/playtest.sh 4 --video
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
PARTIES="${1:-4}"
mkdir -p docs/playtest

for i in $(seq 1 "$PARTIES"); do
	"$GODOT" --headless --path . --fixed-fps 60 --script res://tests/playtest.gd -- \
		--sortie="$PWD/docs/playtest/mesures-partie$i.json" | grep -v "^MESURES" &
done
wait

if [[ "${2:-}" == "--video" ]]; then
	TEMP="$(mktemp -d)"
	LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
		"$GODOT" --path . --rendering-driver opengl3 --write-movie "$TEMP/sequence.avi" --fixed-fps 30 \
		--script res://tests/playtest.gd -- --video
	ffmpeg -loglevel error -y -i "$TEMP/sequence.avi" -vf "scale=1280:720:flags=neighbor,format=yuv420p" \
		-c:v libx264 -preset slow -crf 24 -movflags +faststart -an docs/playtest/sequence.mp4
	ffmpeg -loglevel error -y -i "$TEMP/sequence.avi" \
		-vf "fps=12,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" \
		docs/playtest/sequence.gif
	rm -rf "$TEMP"
fi
