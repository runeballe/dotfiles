#!/usr/bin/env bash
set -euo pipefail
IFS= read -r -d "" src < "$STRATA_ACTION_PATHS" || true
[[ -f $src ]] || { echo "Fant ikke fila: $src" >&2; exit 1; }
dir=$(dirname -- "$src"); base=$(basename -- "$src"); stem=${base%.*}
ext=${base##*.}; ext=${ext,,}
command -v ffmpeg >/dev/null || { echo "ffmpeg mangler" >&2; exit 1; }

free_name() { # $1 = stem, $2 = extension; never overwrites
  local out="$dir/$1.$2" n=1
  while [[ -e $out ]]; do out="$dir/$1-$n.$2"; n=$((n+1)); done
  printf "%s" "$out"
}

has_audio() { [[ -n $(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 -- "$1" | head -n1) ]]; }

# Codecs per container, as an array in ENC. VF holds a scale filter for 3GP
# (phone size), merged into any other video filter by the caller.
encode_args() { # $1 = target extension
  VF=""
  case $1 in
    mp4) ENC=(-c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart) ;;
    avi) ENC=(-c:v mpeg4 -q:v 3 -c:a libmp3lame -q:a 3) ;;
    flv) ENC=(-c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p -c:a aac -b:a 128k -ar 44100) ;;
    3gp) ENC=(-c:v libx264 -profile:v baseline -level 3.0 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 64k -ac 1 -ar 22050)
         VF='scale=trunc(min(640\,iw)/2)*2:-2' ;;
    *)   echo "Ukjent format: $1" >&2; exit 1 ;;
  esac
}

vf_args() { # $1 = extra video filter or empty
  local f=$1
  [[ -n $VF ]] && f=${f:+$f,}$VF
  [[ -n $f ]] && printf '%s\n' -filter:v "$f"
  return 0
}
TARGET=avi
out=$(free_name "$stem" "$TARGET")
encode_args "$TARGET"
mapfile -t vf < <(vf_args "")
ffmpeg -hide_banner -loglevel error -nostdin -i "$src" -map 0:v:0 -map '0:a:0?' "${vf[@]}" "${ENC[@]}" "$out"
echo "Laget $out"
