#!/usr/bin/env bash
# One question, three protocols. Each model is sent to the endpoint its page recommends.
set -euo pipefail
BASE=${BASE_URL:-https://argolink.io}
KEY=${API_KEY:?export API_KEY}
Q="Explain what an idempotent API operation is in two sentences."

# OpenAI Responses (GPT, Grok): text is in the output_text items
curl -sS "$BASE/v1/responses" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\": \"gpt-6-sol\", \"input\": \"$Q\", \"reasoning\": {\"effort\": \"low\"}}" \
  | jq -r '.output[] | select(.type == "message") | .content[] | select(.type == "output_text") | .text'

# Chat Completions (DeepSeek, GLM, Kimi): text is in choices[0].message.content
curl -sS "$BASE/v1/chat/completions" -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\": \"deepseek-v4.1-flash\", \"messages\": [{\"role\": \"user\", \"content\": \"$Q\"}], \"reasoning_effort\": \"none\"}" \
  | jq -r '.choices[0].message.content'

# Anthropic Messages (Claude): x-api-key auth, max_tokens required, text blocks in content[]
curl -sS "$BASE/v1/messages" -H "x-api-key: $KEY" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -d "{\"model\": \"claude-sonnet-5\", \"max_tokens\": 300, \"messages\": [{\"role\": \"user\", \"content\": \"$Q\"}]}" \
  | jq -r '.content[] | select(.type == "text") | .text'
