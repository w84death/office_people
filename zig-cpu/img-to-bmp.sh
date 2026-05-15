#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <input.(gif|png)> [output.bmp]"
    exit 1
fi

input="$1"
output="${2:-${input%.*}.bmp}"

if [[ ! -f "$input" ]]; then
    echo "Input file not found: $input"
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is required but not installed."
    exit 1
fi

lower_input="${input,,}"
if [[ "$lower_input" != *.gif && "$lower_input" != *.png ]]; then
    echo "Unsupported input format: $input"
    echo "Supported formats: .gif, .png"
    exit 1
fi

if [[ "${output,,}" != *.bmp ]]; then
    echo "Output must be a .bmp file: $output"
    exit 1
fi

ffmpeg -y -i "$input" -frames:v 1 -c:v bmp -pix_fmt pal8 "$output"

echo "Converted: $input -> $output"
