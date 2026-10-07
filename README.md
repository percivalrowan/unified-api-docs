# Unified AI API Docs: Text, Image and Video Models on One Base URL

A one-page reference for [ArgoLink](https://argolink.io/gh-unified-api-docs)'s unified API: three text protocols, one image surface and an asynchronous video job API, all behind `https://argolink.io` and a single key. It comes with an [OpenAPI 3.1 file](./openapi.yaml) of the documented endpoints and copy-paste [examples](./examples).

[Endpoints](#endpoints-at-a-glance) · [Text](#text-three-protocols-one-key) · [Images](#images) · [Video](#video-jobs) · [Errors](#errors-and-retries) · [Clients](#client-setup) · [FAQ](#faq)

<sub>Last checked 2026-10-07 against the live docs (`argolink.io/en/docs`), the 45 model pages and the public catalog (revision `0315cdd070b19ded`). Where anything here differs from those pages, the pages are right.</sub>

## Endpoints at a glance

| Job | Method and path | Auth | Notes |
|---|---|---|---|
| List models | `GET /v1/models` (alias `/models`; Gemini shape at `/v1beta/models`) | none | 45 models on 2026-10-07 |
| Text, OpenAI Responses | `POST /v1/responses` | `Authorization: Bearer` | recommended for GPT and Grok; what Codex speaks |
| Text, Chat Completions | `POST /v1/chat/completions` | `Authorization: Bearer` | recommended for DeepSeek, GLM and Kimi; accepted for every text model |
| Text, Anthropic Messages | `POST /v1/messages` | `x-api-key` (Bearer also accepted) | recommended for Claude; not open for OpenAI models |
| Images | `POST /v1/images/generations`, `POST /v1/images/edits` | `Authorization: Bearer` | give clients a 600 s timeout |
| Upload a local file | `POST /v1/media/uploads` | `Authorization: Bearer` | returns `upload_url` and `media_url` |
| Video | `POST /v1/videos/generations` → `GET /v1/videos/{request_id}` → `GET /v1/videos/{request_id}/content` | `Authorization: Bearer` | statuses `pending`, `done`, `failed`, `expired` |

Which base URL to type depends on the client, not the model:

- Clients that append the path after `/v1` (OpenAI SDKs, Codex, Cherry Studio): `https://argolink.io/v1`
- Clients that add `/v1/messages` themselves (Claude Code, Anthropic SDKs) and Infinite Canvas: `https://argolink.io`

Model IDs come from the live list; `curl -s https://argolink.io/v1/models` works without a key. The machine-readable catalog with category, recommended endpoint and prices is `GET /api/catalog/v1/models?page_size=100`.

## Text: three protocols, one key

Each model has one native format; the other two are converted to it. OpenAI models are the exception: they take Responses and Chat Completions only.

| Family (model IDs) | `/v1/responses` | `/v1/chat/completions` | `/v1/messages` |
|---|---|---|---|
| OpenAI: `gpt-6-astra`, `gpt-6-sol`, `gpt-6.1-sol`, `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.6-sol`, `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini` | native | yes | not open |
| xAI: `grok-4.5`, `grok-4.6`, `grok-4.7` | native | converted | converted |
| Anthropic: `claude-opus-5`, `claude-opus-5-5`, `claude-opus-4-8`, `claude-sonnet-5`, `claude-fable-5`, `claude-fable-5-1` | converted | converted | native |
| DeepSeek: `deepseek-v4-pro`, `deepseek-v4.1-flash` | converted | native | converted |
| Zhipu: `glm-5.1`, `glm-5.2`, `glm-5.3`, `glm-5.3-flash`, `glm-5.3-flashx` | converted | native | converted |
| Kimi: `kimi-k2.6`, `kimi-k2.7-code`, `kimi-k3` | converted | native | converted |

Reading the answer: Responses puts text in `output[]` items of type `output_text`; Chat Completions in `choices[0].message.content`; Messages in `content[]` blocks of type `text`. [examples/text.sh](./examples/text.sh) sends one question through all three.

### Reasoning controls are per model

Parameters are not interchangeable, and an upstream can return 200 while ignoring an unknown field. The docs verified these on Chat Completions:

| Model | Send | Behaviour |
|---|---|---|
| `deepseek-v4-pro` | `reasoning_effort`: low / high / max | thinking always on; `none` and `thinking.type: disabled` are ignored; default high |
| `deepseek-v4.1-flash` | `reasoning_effort`: none / low / high / max | on by default at high; `none` turns it off |
| `glm-5.2` | `reasoning_effort` | low/medium/high run as high, xhigh/max as max (default); `none` turns thinking off |
| `glm-5.3` | `reasoning_effort`: low / high / max | cannot be disabled; default max |
| `glm-5.3-flash`, `glm-5.3-flashx` | `reasoning_effort`: low / high / max | low runs as high; default max |
| `kimi-k2.6` | `reasoning_effort`: low / medium / high / xhigh | off by default; max is refused |
| `kimi-k2.7-code` | neither field | always thinking, no levels |
| `kimi-k3` | `reasoning_effort`: low / high / max | default max; pick the level on the first turn, because changing it mid-conversation drops the prompt cache |

GPT models take `reasoning.effort` on Responses (GPT-6 Sol: low to max, default medium). GPT-6 Sol calls tools on Chat Completions only with `reasoning_effort: none`, so send tool-plus-reasoning work to `/v1/responses`.

## Images

One surface for three model families; the size controls differ, so don't copy fields between them.

| Family | IDs | Size control | `n` | Edit references | Output | Price per returned image |
|---|---|---|---|---|---|---|
| GPT Image | `gpt-image-2`, `gpt-image-2.5-flare`, `gpt-image-2.5-sunburst` | `size` in pixels, aspect ratio written in the prompt; `quality` auto/low/medium/high | 1–7 | up to 16 | `b64_json` or `url` | $0.015 at 1K and 2K, $0.02 at 4K |
| Nano Banana | `nano-banana-pro`, `nano-banana-2`, `nano-banana-2-lite` | `aspect_ratio` (10 ratios, 14 on `nano-banana-2`) + `resolution` 1k/2k/4k (Lite: 1k) | 1–4 | up to 14 | base64 JPEG only | Pro $0.03; 2: $0.02, 4K $0.025; Lite $0.01 |
| Grok Image | `grok-imagine-image`, `grok-imagine-image-2.0`, `grok-imagine-image-quality` | `aspect_ratio` (15 ratios + auto) + `resolution` 1k/2k (1.5k on 2.0 and quality) | 1–10 | up to 3 | temporary `url` or `b64_json` | $0.015 |

GPT Image bills by the longest edge of the returned image: up to 1024 px is 1K, 1025–2048 is 2K, above is 4K (so 2560x1440 bills as 4K). Edits take public HTTPS or data URLs in a JSON `images` array, or local files as repeated multipart `image[]` parts. `grok-imagine-image-quality` retires on November 2, 2026; after that its requests run on `grok-imagine-image-2.0` at quality low. See [examples/image.sh](./examples/image.sh).

## Video jobs

```
POST /v1/videos/generations          -> 202 {"request_id": "…"}
GET  /v1/videos/{request_id}          -> pending (progress 0-99) | done | failed | expired
GET  /v1/videos/{request_id}/content  -> MP4 once done; 409 job_video_not_ready before, 424 job_failed after a failure
```

Poll every 10–15 seconds. The docs give two time limits: a job that finds no capacity within 10 minutes ends as `capacity_unavailable`, and one that has started generating ends as `generation_timeout` only after 24 hours. Billing happens once, when `done` is first seen: `usage.billed_seconds` = output seconds + reference-video seconds. Reference images and audio are free and failed or expired jobs cost nothing. Without `duration`, Seedance, Wan and MiniMax render and bill 5 seconds; Grok Video defaults to 8.

| Model | Seconds | Resolutions | Price per second | Inputs |
|---|---|---|---|---|
| `seedance-2.5` | 4–30 | 480p, 720p, 1080p | $0.0874 / $0.196 / $0.483 | text, first or first+last frame, ≤30 images, 10 videos, 10 audio; video edit |
| `seedance-2.0` | 4–15 | 480p–1080p, 4k | $0.053 / $0.11 / $0.28; 4k $0.58 | text, frames, ≤9 images, 3 videos, 3 audio |
| `seedance-2.0-mini` | 4–15 | 480p, 720p | $0.026 / $0.057 | as 2.0 |
| `seedance-2.0-fast` | 4–15 | 480p, 720p | $0.042 / $0.091 | as 2.0 |
| `wan-3` | 2–30 | 480p, 720p, 1080p | $0.038 / $0.075 / $0.15 | text, frames, ≤10 images, 5 videos, 5 audio; edit; `seed` |
| `wan-3-prime` | 4–30 | 480p, 720p, 1080p | $0.051 / $0.11 / $0.21 | text and references only; 16:9, 1:1, 9:16 |
| `minimax-h3` | 4–15 | 768p, 2k | $0.039 / $0.064 | text, frames, ≤9 images, 3 videos, 3 audio |
| `grok-imagine-video-1.5` | 1–15 (default 8) | 480p, 720p, 1080p | $0.064 / $0.112 / $0.20 | text, first/last frame, keyframes, reference images, preset voices |

Seedance, Wan and MiniMax media fields take public `https://` URLs only (Grok Video's `image` also accepts a data URI or `file_id`). For a local file, ask `POST /v1/media/uploads` for a ticket (`model`, `type`, `content_type`, `size_bytes`), `PUT` the bytes to `upload_url` within 15 minutes, then send `media_url` (readable for 7 days). The whole JSON body must stay under 1 MiB. Full loop: [examples/video.sh](./examples/video.sh).

## Errors and retries

Errors carry `{"error": {"type", "code", "param", "message"}}`; `code` is stable, `param` names the field at fault.

| HTTP | `error.type` / `code` | Meaning | Retry? |
|---|---|---|---|
| 400 | `invalid_request_error` / `field_invalid`, `json_invalid` | malformed request | fix it |
| 400 | `invalid_request_error` / `request_unsupported` | the model refuses this combination (resolution, duration, seed, asset count…) | fix it |
| 401 | `authentication_error` | missing or invalid key | no |
| 402 / 403 | — | insufficient balance, or the key's group lacks permission | top up / change group |
| 404 | `not_found_error` / `video_request_not_found` | unknown `request_id`, or another user's key | no |
| 409 | `job_video_not_ready` | video still rendering | yes, same URL |
| 429 | `rate_limit_error` | concurrency or rate limit | yes, after running jobs finish |
| 503 | `overloaded_error` / `no_capacity` | no capacity right now | yes, after `Retry-After` |

A video job can also end as `failed` with `error.code` and `retryable`: `invalid_input`, `content_policy_violation` and `generation_timeout` are not retryable; `capacity_unavailable` and `internal_error` are; `copyright_violation` and `generation_failed` say which in `retryable`. Nothing failed is billed.

## Client setup

```python
from openai import OpenAI                      # chat, responses, images
client = OpenAI(base_url="https://argolink.io/v1", api_key=API_KEY)

from anthropic import Anthropic                # messages
claude = Anthropic(base_url="https://argolink.io", api_key=API_KEY)
```

Codex (`~/.codex/config.toml`; key names from OpenAI's Codex config reference):

```toml
model = "gpt-6-sol"
model_provider = "relay"

[model_providers.relay]
name = "ArgoLink"
base_url = "https://argolink.io/v1"
env_key = "RELAY_API_KEY"
wire_api = "responses"
```

Claude Code (`~/.claude/settings.json`): `{"env": {"ANTHROPIC_BASE_URL": "https://argolink.io", "ANTHROPIC_AUTH_TOKEN": "<key>"}}`. Claude Code sends the token as `Authorization: Bearer`, which `/v1/messages` accepts. Cherry Studio: an OpenAI-type provider whose endpoint includes `/v1`.

## FAQ

**Is there one OpenAI-compatible interface for text, image and video models?**
For text and images, yes: `/v1/chat/completions`, `/v1/responses` and `/v1/images/*` follow OpenAI's shapes. Video uses its own job API (submit, poll, download), not OpenAI's video format. One key covers all three.

**Which headers show rate limits and retry timing for video?**
None are documented on success. Over the limit you get `429 rate_limit_error`; with no capacity, `503` and a `Retry-After` header. Both are safe to retry and neither is billed.

**Why does a Python script get `403` with "error code: 1010"?**
The CDN rejects urllib's default `Python-urllib/x.y` User-Agent; set any other `User-Agent` header. `requests`, `httpx` and the OpenAI SDK are not affected.

**Is there an SDK or webhooks?**
No SDK of its own: use the OpenAI or Anthropic SDKs with the base URLs above. The video docs describe polling only; no webhook is documented.

**Do failed video or image jobs cost money?**
Failed or expired video jobs are not charged. Images are billed per returned image.

**How do I pay, and is there a minimum?**
Top-ups go through PayPal in the console; Visa, Mastercard and Amex work without a PayPal account. The minimum is $1.

## Tests

```bash
pip install pytest pyyaml openapi-spec-validator
pytest tests/
```

The tests validate `openapi.yaml` as OpenAPI 3.1, check that its paths, video statuses and video model list match the docs and a catalog snapshot, and check that every model ID in this README exists and that no retired host, path or status name appears.

## License

MIT for the text and examples in this repository.
