#!/usr/bin/env bash
set -euo pipefail

# Produce a GitHub-ready preview from a genuine iOS Simulator screen recording.
# Usage: ./Scripts/make-gif.sh path/to/minimal-mode.mov [output.gif]
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 INPUT.mov [OUTPUT.gif]" >&2
  exit 64
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install it with: brew install ffmpeg" >&2
  exit 69
fi
input="$1"
output="${2:-Docs/Assets/minimal-preview.gif}"
mkdir -p "$(dirname "$output")"
ffmpeg -hide_banner -loglevel error -y -i "$input" \
  -filter_complex "[0:v]fps=15,scale=800:-1:flags=lanczos,split[v1][v2];[v1]palettegen=stats_mode=diff[p];[v2][p]paletteuse=dither=bayer:bayer_scale=4" \
  -loop 0 "$output"
printf 'Created: %s\n' "$output"
