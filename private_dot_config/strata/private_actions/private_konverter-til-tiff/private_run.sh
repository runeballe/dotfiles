#!/usr/bin/env bash
# Convert one file to tiff next to the original. Never overwrites:
# picks name.tiff, then name-1.@TARGET@, name-2.@TARGET@ ...
set -euo pipefail
TARGET=tiff
IFS= read -r -d '' src < "$STRATA_ACTION_PATHS" || true
[[ -f $src ]] || { echo "Fant ikke fila: $src" >&2; exit 1; }

dir=$(dirname -- "$src"); base=$(basename -- "$src"); stem=${base%.*}
ext=${base##*.}; ext=${ext,,}

free_name() { # $1 = stem → first unused path
  local out="$dir/$1.$TARGET" n=1
  while [[ -e $out ]]; do out="$dir/$1-$n.$TARGET"; n=$((n+1)); done
  printf '%s' "$out"
}

convert_image() { # $1 = in, $2 = out
  case $TARGET in
    jpg)  magick -- "$1" -background white -alpha remove -alpha off -quality 92 "$2" ;;
    webp) magick -- "$1" -quality 90 "$2" ;;
    *)    magick -- "$1" "$2" ;;
  esac
}

if [[ $ext == pdf ]]; then
  # One image per page: name-side1.png, name-side2.png ...
  tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
  pdftoppm -r 200 -png -- "$src" "$tmp/p"
  shopt -s nullglob; pages=("$tmp"/p*.png)
  (( ${#pages[@]} )) || { echo "PDF-en ga ingen sider" >&2; exit 1; }
  i=1
  for page in "${pages[@]}"; do
    if (( ${#pages[@]} == 1 )); then out=$(free_name "$stem"); else out=$(free_name "$stem-side$i"); fi
    convert_image "$page" "$out"; echo "Laget $out"; i=$((i+1))
  done
else
  out=$(free_name "$stem")
  convert_image "$src" "$out"
  echo "Laget $out"
fi
