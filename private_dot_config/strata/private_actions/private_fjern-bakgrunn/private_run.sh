#!/usr/bin/env bash
# Remove the background of one image (or each page of a PDF) with rembg.
# Writes name-uten-bakgrunn.png next to the original; never overwrites.
set -euo pipefail
MODEL=isnet-general-use
REMBG=$(command -v rembg || echo "$HOME/.local/bin/rembg")
[[ -x $REMBG ]] || { echo 'rembg mangler. Installer med: uv tool install --python 3.12 "rembg[cpu,cli]"' >&2; exit 1; }

IFS= read -r -d '' src < "$STRATA_ACTION_PATHS" || true
[[ -f $src ]] || { echo "Fant ikke fila: $src" >&2; exit 1; }
dir=$(dirname -- "$src"); base=$(basename -- "$src"); stem=${base%.*}
ext=${base##*.}; ext=${ext,,}

free_name() {
  local out="$dir/$1.png" n=1
  while [[ -e $out ]]; do out="$dir/$1-$n.png"; n=$((n+1)); done
  printf '%s' "$out"
}

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
if [[ $ext == pdf ]]; then
  pdftoppm -r 200 -png -- "$src" "$tmp/p"
  shopt -s nullglob; inputs=("$tmp"/p*.png)
  (( ${#inputs[@]} )) || { echo "PDF-en ga ingen sider" >&2; exit 1; }
else
  # rembg reads PNG/JPG/WebP directly; normalise anyway so odd files work.
  magick -- "$src" "$tmp/in.png"; inputs=("$tmp/in.png")
fi

i=1
for in in "${inputs[@]}"; do
  if (( ${#inputs[@]} == 1 )); then out=$(free_name "$stem-uten-bakgrunn")
  else out=$(free_name "$stem-side$i-uten-bakgrunn"); fi
  "$REMBG" i -m "$MODEL" "$in" "$out"
  echo "Laget $out"; i=$((i+1))
done
