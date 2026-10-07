#!/usr/bin/env bash
# Model discovery needs no key. Requires curl and jq.
set -euo pipefail
BASE=${BASE_URL:-https://argolink.io}

curl -sS "$BASE/v1/models" | jq -r '.data[] | "\(.owned_by)\t\(.id)"'           # OpenAI shape
curl -sS "$BASE/v1beta/models" | jq -r '.models[].baseModelId' | head -3           # Gemini shape
# The catalog behind both lists, with category (chat/image/video) and recommended endpoint:
curl -sS "$BASE/api/catalog/v1/models?page_size=100" | jq -r '.items[] | [.category, .id, .endpoint] | @tsv'
