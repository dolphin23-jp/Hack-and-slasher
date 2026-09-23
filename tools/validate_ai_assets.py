#!/usr/bin/env python3
"""Validate ASHEN VOW's AI asset production backlog.

This is intentionally network-free. CI validates bookkeeping and integration paths,
while generation itself remains an explicit Codex task so pull requests never incur
model/API cost just by running tests.
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
BACKLOG = ROOT / "assets" / "ai" / "asset_backlog.json"

VALID_STATUSES = {"baseline", "planned", "generated", "integrated", "validated", "deferred"}
VALID_KINDS = {"character", "item_art", "icon", "background", "vfx", "motion", "music", "sfx"}
VALID_PRIORITIES = {"low", "medium", "high"}
REQUIRED_KEYS = {
    "id",
    "kind",
    "runtime_path",
    "status",
    "generation_method",
    "priority",
    "ai_target",
    "notes",
}
ID_RE = re.compile(r"^[a-z0-9][a-z0-9_-]{1,95}$")


def error(message: str, errors: list[str]) -> None:
    errors.append(message)


def safe_relative_path(raw: object) -> str | None:
    if not isinstance(raw, str) or not raw.strip():
        return None
    normalized = raw.replace("\\", "/")
    path = PurePosixPath(normalized)
    if path.is_absolute() or ".." in path.parts or "." in path.parts:
        return None
    return normalized


def main() -> int:
    errors: list[str] = []
    try:
        data = json.loads(BACKLOG.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"ERROR: missing {BACKLOG.relative_to(ROOT)}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"ERROR: invalid JSON: {exc}", file=sys.stderr)
        return 1

    if data.get("version") != 1:
        error("top-level version must be 1", errors)
    targets = data.get("targets")
    if not isinstance(targets, list) or not targets:
        error("targets must be a non-empty array", errors)
        targets = []

    seen: set[str] = set()
    status_counts: Counter[str] = Counter()
    kind_counts: Counter[str] = Counter()

    for index, target in enumerate(targets):
        label = f"targets[{index}]"
        if not isinstance(target, dict):
            error(f"{label} must be an object", errors)
            continue

        missing = REQUIRED_KEYS - target.keys()
        if missing:
            error(f"{label} missing keys: {', '.join(sorted(missing))}", errors)

        asset_id = target.get("id")
        if not isinstance(asset_id, str) or not ID_RE.fullmatch(asset_id):
            error(f"{label}.id must match {ID_RE.pattern}", errors)
            asset_id = f"invalid-{index}"
        elif asset_id in seen:
            error(f"duplicate asset id: {asset_id}", errors)
        else:
            seen.add(asset_id)

        kind = target.get("kind")
        if kind not in VALID_KINDS:
            error(f"{asset_id}: unsupported kind {kind!r}", errors)
        else:
            kind_counts[kind] += 1

        status = target.get("status")
        if status not in VALID_STATUSES:
            error(f"{asset_id}: unsupported status {status!r}", errors)
        else:
            status_counts[status] += 1

        priority = target.get("priority")
        if priority not in VALID_PRIORITIES:
            error(f"{asset_id}: unsupported priority {priority!r}", errors)

        if target.get("ai_target") is not True:
            error(f"{asset_id}: ai_target must be true for this backlog", errors)

        method = target.get("generation_method")
        if not isinstance(method, str) or not method.strip():
            error(f"{asset_id}: generation_method must be non-empty", errors)

        notes = target.get("notes")
        if not isinstance(notes, str) or len(notes.strip()) < 8:
            error(f"{asset_id}: notes must explain the production/validation constraint", errors)

        runtime_path = safe_relative_path(target.get("runtime_path"))
        if runtime_path is None:
            error(f"{asset_id}: runtime_path must be a safe repository-relative path", errors)
            continue

        # Assets that claim to exist in or influence the runtime must resolve to a
        # current repository path. Planned targets are allowed to point at the
        # current procedural/code baseline they intend to replace.
        disk_path = ROOT / runtime_path
        if not disk_path.exists():
            error(f"{asset_id}: runtime_path does not exist: {runtime_path}", errors)

        if kind in {"music", "sfx"} and disk_path.suffix.lower() != ".wav":
            error(f"{asset_id}: current Soundscape contract expects WAV: {runtime_path}", errors)

        if kind == "item_art" and disk_path.name != "manifest.json":
            error(f"{asset_id}: item_art catalog should point at assets/items/manifest.json", errors)

    if errors:
        for message in errors:
            print(f"ERROR: {message}", file=sys.stderr)
        print(f"AI asset backlog validation failed with {len(errors)} error(s).", file=sys.stderr)
        return 1

    print(f"AI asset backlog valid: {len(targets)} target(s)")
    print("Status:", ", ".join(f"{k}={v}" for k, v in sorted(status_counts.items())))
    print("Kinds:", ", ".join(f"{k}={v}" for k, v in sorted(kind_counts.items())))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
