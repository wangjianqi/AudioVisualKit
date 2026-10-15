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
# Pick a display width suited to the capture orientation (phone recordings are portrait).
width=800
dims="$(ffmpeg -hide_banner -i "$input" 2>&1 | grep -m1 'Video:' | grep -oE '[0-9]{3,5}x[0-9]{3,5}' | head -n1 || true)"
if [[ "$dims" == *x* ]]; then
  w="${dims%x*}"; h="${dims#*x}"
  if (( h > w )); then width=400; fi
fi
ffmpeg -hide_banner -loglevel error -y -i "$input" \
  -filter_complex "[0:v]fps=15,scale=${width}:-2:flags=lanczos,split[v1][v2];[v1]palettegen=stats_mode=diff[p];[v2][p]paletteuse=dither=bayer:bayer_scale=4" \
  -loop 0 "$output"
printf 'Created: %s\n' "$output"
