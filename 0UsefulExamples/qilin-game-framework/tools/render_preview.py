#!/usr/bin/env python3
"""Fast one-shot or persistent preview CLI for Qilin cartridges.

Normal previewing creates only preview artifacts. It never packages a release.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
import time
from dataclasses import asdict
from pathlib import Path
from typing import Any

from PIL import Image

from render_core import (
    DEFAULT_FONT_URL,
    RENDERER_VERSION,
    GateSpec,
    Pico8BitmapFont,
    PreviewError,
    PreviewState,
    default_cache_dir,
    load_font_header,
    parse_font_map,
    parse_gate_spec,
    render_source,
)


def parse_counts(raw: str | None) -> dict[str, int] | None:
    if raw is None:
        return None
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise argparse.ArgumentTypeError(f"Invalid counts JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise argparse.ArgumentTypeError("Counts must be a JSON object.")
    result: dict[str, int] = {}
    for key, count in value.items():
        if not isinstance(key, str) or not isinstance(count, int) or count < 0:
            raise argparse.ArgumentTypeError(
                "Counts keys must be strings and values non-negative integers."
            )
        result[key] = count
    return result


def infer_project_root(source: Path) -> Path:
    source = source.resolve()
    if source.parent.name == "framework":
        return source.parent.parent
    return Path.cwd().resolve()


def stable_json(value: Any) -> bytes:
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")


def compute_fingerprint(
    source_bytes: bytes,
    font_header: str,
    state: PreviewState,
    *,
    scale: int,
) -> str:
    digest = hashlib.sha256()
    digest.update(source_bytes)
    digest.update(hashlib.sha256(font_header.encode("utf-8")).digest())
    digest.update(RENDERER_VERSION.encode("ascii"))
    digest.update(stable_json({
        "level_number": state.level_number,
        "cursor_visual_q": state.cursor_visual_q,
        "gates": [asdict(gate) for gate in state.gates],
        "counts": state.counts,
        "feedback": state.feedback,
        "scale": scale,
    }))
    return digest.hexdigest()


def load_cache(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"version": 1, "entries": {}}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"version": 1, "entries": {}}
    if not isinstance(value, dict) or not isinstance(value.get("entries"), dict):
        return {"version": 1, "entries": {}}
    return value


def save_cache(path: Path, cache: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(cache, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


def save_image_atomic(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        suffix=path.suffix or ".png",
        dir=path.parent,
        delete=False,
    ) as handle:
        temporary = Path(handle.name)
    try:
        image.save(temporary)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def save_json_atomic(value: dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(value, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


class RenderSession:
    """Persistent session that loads the font once and reuses glyph caches."""

    def __init__(
        self,
        *,
        source: Path,
        output: Path,
        native_output: Path | None,
        metadata_output: Path | None,
        cache_file: Path,
        state: PreviewState,
        scale: int,
        font_header_path: Path | None,
        font_cache_path: Path,
        font_url: str,
        no_font_download: bool,
        force: bool,
    ):
        self.source = source
        self.output = output
        self.native_output = native_output
        self.metadata_output = metadata_output
        self.cache_file = cache_file
        self.state = state
        self.scale = scale
        self.force = force

        header_text, font_source = load_font_header(
            explicit_path=font_header_path,
            cache_path=font_cache_path,
            font_url=font_url,
            no_download=no_font_download,
        )
        self.header_text = header_text
        self.font_source = font_source
        self.font = Pico8BitmapFont(parse_font_map(header_text))
        self.cache = load_cache(cache_file)

    def render_if_changed(self) -> tuple[bool, float, str]:
        started = time.perf_counter()
        source_bytes = self.source.read_bytes()
        fingerprint = compute_fingerprint(
            source_bytes,
            self.header_text,
            self.state,
            scale=self.scale,
        )
        key = str(self.output.resolve())
        cached = self.cache["entries"].get(key, {})
        outputs_exist = self.output.exists()
        if self.native_output is not None:
            outputs_exist = outputs_exist and self.native_output.exists()
        if self.metadata_output is not None:
            outputs_exist = outputs_exist and self.metadata_output.exists()

        if not self.force and outputs_exist and cached.get("fingerprint") == fingerprint:
            return False, time.perf_counter() - started, fingerprint

        source = source_bytes.decode("utf-8")
        native, metadata = render_source(source, self.font, self.state)
        scaled = (
            native
            if self.scale == 1
            else native.resize(
                (native.width * self.scale, native.height * self.scale),
                Image.Resampling.NEAREST,
            )
        )
        save_image_atomic(scaled, self.output)
        if self.native_output is not None:
            save_image_atomic(native, self.native_output)
        metadata.update({
            "source": str(self.source),
            "font_source": self.font_source,
            "fingerprint": fingerprint,
            "scaled_output": str(self.output),
            "native_output": str(self.native_output) if self.native_output else None,
        })
        if self.metadata_output is not None:
            save_json_atomic(metadata, self.metadata_output)

        self.cache["entries"][key] = {
            "fingerprint": fingerprint,
            "source": str(self.source.resolve()),
            "updated_unix": time.time(),
        }
        save_cache(self.cache_file, self.cache)
        self.force = False
        return True, time.perf_counter() - started, fingerprint


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Render a P8SCII-faithful Qilin cartridge preview."
    )
    parser.add_argument("source", type=Path, help="Framework .p8 or bundled .lua")
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--native-output", type=Path)
    parser.add_argument("--metadata-output", type=Path)
    parser.add_argument("--project-root", type=Path)
    parser.add_argument("--scale", type=int, default=8)
    parser.add_argument("--level", type=int, default=1)
    parser.add_argument("--cursor-q", type=int)
    parser.add_argument("--gate", action="append", default=[])
    parser.add_argument("--counts")
    parser.add_argument("--feedback")
    parser.add_argument("--font-header", type=Path)
    parser.add_argument("--font-url", default=DEFAULT_FONT_URL)
    parser.add_argument("--no-font-download", action="store_true")
    parser.add_argument("--cache-file", type=Path)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--watch", action="store_true")
    parser.add_argument("--poll-interval", type=float, default=0.15)
    parser.add_argument("--quiet", action="store_true")
    return parser


def create_session(args: argparse.Namespace) -> RenderSession:
    source = args.source.resolve()
    if not source.exists():
        raise PreviewError(f"Source file not found: {source}")
    if args.scale < 1:
        raise PreviewError("--scale must be at least 1.")
    if args.poll_interval < 0.05:
        raise PreviewError("--poll-interval must be at least 0.05 seconds.")

    project_root = (
        args.project_root.resolve()
        if args.project_root
        else infer_project_root(source)
    )
    cache_dir = default_cache_dir(project_root)
    cache_file = args.cache_file or cache_dir / "preview-cache.json"
    font_cache_path = cache_dir / "pico_font.h"

    gates: list[GateSpec] = [parse_gate_spec(spec) for spec in args.gate]
    counts = parse_counts(args.counts)
    state = PreviewState(
        level_number=args.level,
        cursor_visual_q=args.cursor_q,
        gates=tuple(gates),
        counts=counts,
        feedback=args.feedback,
    )
    return RenderSession(
        source=source,
        output=args.output.resolve(),
        native_output=args.native_output.resolve() if args.native_output else None,
        metadata_output=(
            args.metadata_output.resolve() if args.metadata_output else None
        ),
        cache_file=cache_file.resolve(),
        state=state,
        scale=args.scale,
        font_header_path=(
            args.font_header.resolve() if args.font_header else None
        ),
        font_cache_path=font_cache_path.resolve(),
        font_url=args.font_url,
        no_font_download=args.no_font_download,
        force=args.force,
    )


def report(changed: bool, elapsed: float, output: Path, quiet: bool) -> None:
    if quiet:
        return
    if changed:
        print(f"rendered {output} in {elapsed * 1000:.1f} ms")
    else:
        print(f"unchanged; skipped render in {elapsed * 1000:.1f} ms")


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        session = create_session(args)
        changed, elapsed, _ = session.render_if_changed()
        report(changed, elapsed, session.output, args.quiet)

        if not args.watch:
            return 0

        if not args.quiet:
            print(
                f"watching {session.source} every {args.poll_interval:.2f}s; "
                "press Ctrl+C to stop"
            )
        last_stat: tuple[int, int] | None = None
        try:
            while True:
                stat = session.source.stat()
                signature = (stat.st_mtime_ns, stat.st_size)
                if signature != last_stat:
                    last_stat = signature
                    changed, elapsed, _ = session.render_if_changed()
                    if changed:
                        report(True, elapsed, session.output, args.quiet)
                time.sleep(args.poll_interval)
        except KeyboardInterrupt:
            if not args.quiet:
                print("watch stopped")
            return 0
    except (OSError, PreviewError) as exc:
        parser.error(str(exc))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
