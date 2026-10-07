#!/usr/bin/env bash
# Text to image with GPT Image 2, then a JSON reference edit with Nano Banana 2.
set -euo pipefail
BASE=${BASE_URL:-https://argolink.io}
KEY=${API_KEY:?export API_KEY}

# GPT Image: pixel size in `size`, aspect ratio spelled out in the prompt. 1024x1024 bills as 1K ($0.015).
curl -sS --max-time 600 "$BASE/v1/images/generations" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model": "gpt-image-2", "prompt": "A red apple on a wooden table, square 1:1 composition",
       "size": "1024x1024", "quality": "auto", "n": 1, "response_format": "b64_json"}' \
  | jq -r '.data[0].b64_json' | base64 --decode > apple.png

# Nano Banana: aspect_ratio + resolution fields; output is always base64 JPEG. 2k bills $0.02.
curl -sS --max-time 600 "$BASE/v1/images/edits" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model": "nano-banana-2", "prompt": "Keep the subject and put it in a quiet Japanese garden",
       "images": [{"image_url": "https://example.com/reference-1.png"}],
       "aspect_ratio": "4:3", "resolution": "2k", "n": 1}' \
  | jq -r '.data[0].b64_json' | base64 --decode > garden.jpg
