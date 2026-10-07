#!/usr/bin/env bash
# Submit -> poll -> download. 4 s at 480p on seedance-2.0-mini bills 4 x $0.026 = $0.104.
set -euo pipefail
BASE=${BASE_URL:-https://argolink.io}
KEY=${API_KEY:?export API_KEY}

ID=$(curl -fsS "$BASE/v1/videos/generations" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model": "seedance-2.0-mini", "prompt": "A paper boat drifts down a rain gutter, close tracking shot",
       "duration": 4, "resolution": "480p", "aspect_ratio": "16:9"}' | jq -er '.request_id')
echo "request_id: $ID"

while :; do
  JOB=$(curl -fsS "$BASE/v1/videos/$ID" -H "Authorization: Bearer $KEY")
  STATUS=$(jq -r '.status' <<<"$JOB")
  case "$STATUS" in
    done) jq '.usage' <<<"$JOB"; break ;;
    failed|expired) jq '.error' <<<"$JOB"; exit 1 ;;   # failed and expired jobs are not charged
    *) echo "pending $(jq -r '.progress // 0' <<<"$JOB")%"; sleep 10 ;;
  esac
done

curl -fsSL "$BASE/v1/videos/$ID/content" -H "Authorization: Bearer $KEY" -o boat.mp4
echo "saved boat.mp4"
