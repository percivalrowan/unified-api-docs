"""Offline consistency checks between openapi.yaml, the README and a catalog snapshot.

    pip install pytest pyyaml        # optional: openapi-spec-validator
    pytest tests/
"""
import json
import os
import re

import pytest
import yaml

ROOT = os.path.join(os.path.dirname(__file__), "..")
with open(os.path.join(ROOT, "openapi.yaml"), encoding="utf-8") as handle:
    SPEC = yaml.safe_load(handle)
with open(os.path.join(ROOT, "tests", "fixtures", "catalog-ids-2026-10-07.json"), encoding="utf-8") as handle:
    CATALOG = {m["id"]: m for m in json.load(handle)["items"]}
with open(os.path.join(ROOT, "README.md"), encoding="utf-8") as handle:
    README = handle.read()


def test_spec_is_valid_openapi_when_the_validator_is_installed():
    validator = pytest.importorskip("openapi_spec_validator")
    validator.validate(SPEC)


def test_base_url_and_paths():
    assert SPEC["servers"] == [{"url": "https://argolink.io"}]
    expected = {"/v1/models", "/models", "/v1beta/models", "/v1/responses", "/v1/chat/completions",
                "/v1/messages", "/v1/images/generations", "/v1/images/edits", "/v1/media/uploads",
                "/v1/videos/generations", "/v1/videos/{request_id}", "/v1/videos/{request_id}/content"}
    assert set(SPEC["paths"]) == expected


def test_video_statuses_are_exactly_the_documented_four():
    status = SPEC["components"]["schemas"]["VideoJob"]["properties"]["status"]
    assert status["enum"] == ["pending", "done", "failed", "expired"]


def test_video_model_enum_matches_the_catalog():
    enum = SPEC["components"]["schemas"]["VideoRequest"]["properties"]["model"]["enum"]
    assert set(enum) == {m for m, info in CATALOG.items() if info["category"] == "video"}


def test_discovery_needs_no_key_but_inference_does():
    for path in ("/v1/models", "/models", "/v1beta/models"):
        assert SPEC["paths"][path]["get"]["security"] == []
    assert SPEC["security"] == [{"bearerAuth": []}]


def test_every_model_id_in_the_readme_exists():
    ids = set(re.findall(r"`([a-z0-9][a-z0-9.\-]+)`", README))
    candidates = {i for i in ids if any(i.startswith(p) for p in (
        "gpt-", "claude-", "grok-", "deepseek-", "glm-", "kimi-", "seedance-", "wan-", "minimax-", "nano-banana"))}
    unknown = sorted(c for c in candidates if c not in CATALOG)
    assert not unknown, unknown


def test_no_retired_or_wrong_api_shapes_in_the_readme():
    assert "api.argolink.io" not in README
    assert "/v1/tasks" not in README
    for word in ("running", "completed"):
        assert f"`{word}`" not in README
