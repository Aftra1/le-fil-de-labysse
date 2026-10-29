#!/usr/bin/env bash
# Playtest robot : joue N parties complètes (sans fenêtre) avec chaque profil (robot parfait, joueur
# humain) et enregistre les mesures dans docs/playtest/mesures-<profil>-N.json ; avec --video,
# enregistre aussi la séquence de démonstration avec le son (Xvfb + Movie Maker) et la convertit en MP4
# (image et son) et en GIF (image seule).
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
	# Montage : la descente vers la Faille et la remontée (lignes « VIDEO » du robot) passent en accéléré ×2 ;
	# le son est accéléré sans changer de hauteur (atempo).
	marque() { awk -v nom="$1" '$1 == "VIDEO" && $2 == nom { print $3; exit }' "$TEMP/journal.txt"; }
	S="$(marque sous_l_eau)"; F="$(marque fond)"; R="$(marque remontee)"; U="$(marque surface)"
	FILTRE=""
	i=0
	for morceau in "0:$S:1" "$S:$F:2" "$F:$R:1" "$R:$U:2" "$U::1"; do
		IFS=: read -r DEBUT FIN VITESSE <<< "$morceau"
		BORNES="start=$DEBUT${FIN:+:end=$FIN}"
		FILTRE+="[0:v]trim=$BORNES,setpts=(PTS-STARTPTS)/$VITESSE[v$i];"
		FILTRE+="[0:a]atrim=$BORNES,asetpts=PTS-STARTPTS,atempo=$VITESSE[a$i];"
		i=$((i + 1))
	done
	FILTRE+="[v0][a0][v1][a1][v2][a2][v3][a3][v4][a4]concat=n=5:v=1:a=1[v][a]"
	ffmpeg -loglevel error -y -i "$TEMP/sequence.avi" -filter_complex "$FILTRE" -map "[v]" -map "[a]" \
		-c:v libx264 -qp 0 -preset ultrafast -c:a pcm_s16le "$TEMP/montage.mkv"
	ffmpeg -loglevel error -y -i "$TEMP/montage.mkv" -vf "scale=1280:720:flags=neighbor,format=yuv420p,fps=30" \
		-af "volume=6dB,alimiter=limit=0.89:level=false" -c:v libx264 -preset slow -crf 24 -c:a aac -b:a 128k -movflags +faststart \
		docs/playtest/sequence.mp4   # +6 dB et limiteur (crête -1 dB) : audible sur un téléphone
	ffmpeg -loglevel error -y -i "$TEMP/montage.mkv" \
		-vf "fps=12,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle" \
		docs/playtest/sequence.gif
	rm -rf "$TEMP"
fi
