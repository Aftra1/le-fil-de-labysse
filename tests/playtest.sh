#!/usr/bin/env bash
# Playtest robot : joue N parties complètes (sans fenêtre) avec chaque profil (robot parfait, joueur
# humain) et enregistre les mesures dans docs/playtest/mesures-<profil>-N.json ; avec --video,
# enregistre aussi la séquence de démonstration (Xvfb + Movie Maker) et la convertit en MP4 et en GIF.
# Usage : tests/playtest.sh [nombre de parties] [--video]
#         GODOT=/chemin/vers/godot tests/playtest.sh 4 --video
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
PARTIES="${1:-4}"
mkdir -p docs/playtest

for profil in parfait humain; do
	for i in $(seq 1 "$PARTIES"); do
		"$GODOT" --headless --path . --fixed-fps 60 --script res://tests/playtest.gd -- --profil="$profil" \
			--sortie="$PWD/docs/playtest/mesures-$profil-$i.json" | grep -v "^MESURES" &
	done
	wait
done

if [[ "${2:-}" == "--video" ]]; then
	TEMP="$(mktemp -d)"
	LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
		"$GODOT" --path . --rendering-driver opengl3 --write-movie "$TEMP/sequence.avi" --fixed-fps 30 \
		--script res://tests/playtest.gd -- --video | tee "$TEMP/journal.txt"
	# Montage : la descente vers la Faille et la remontée (lignes « VIDEO » du robot) passent en accéléré ×4.
	marque() { awk -v nom="$1" '$1 == "VIDEO" && $2 == nom { print $3; exit }' "$TEMP/journal.txt"; }
	S="$(marque sous_l_eau)"; F="$(marque fond)"; R="$(marque remontee)"; U="$(marque surface)"
	FILTRE="[0:v]trim=0:$S,setpts=PTS-STARTPTS[a];[0:v]trim=$S:$F,setpts=(PTS-STARTPTS)/4[b];"
	FILTRE+="[0:v]trim=$F:$R,setpts=PTS-STARTPTS[c];[0:v]trim=$R:$U,setpts=(PTS-STARTPTS)/4[d];"
	FILTRE+="[0:v]trim=start=$U,setpts=PTS-STARTPTS[e];[a][b][c][d][e]concat=n=5:v=1:a=0,fps=30[v]"
	ffmpeg -loglevel error -y -i "$TEMP/sequence.avi" -filter_complex "$FILTRE" -map "[v]" \
		-c:v libx264 -qp 0 -preset ultrafast "$TEMP/montage.mkv"
	ffmpeg -loglevel error -y -i "$TEMP/montage.mkv" -vf "scale=1280:720:flags=neighbor,format=yuv420p" \
		-c:v libx264 -preset slow -crf 24 -movflags +faststart -an docs/playtest/sequence.mp4
	ffmpeg -loglevel error -y -i "$TEMP/montage.mkv" \
		-vf "fps=12,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" \
		docs/playtest/sequence.gif
	rm -rf "$TEMP"
fi
