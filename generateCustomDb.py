#!/usr/bin/env python3
"""Expand each line in dicts/0.txt using every *.rule file in rules/ via hashcat --stdout into dicts/customgenerated.txt.

Multiple ``-r`` flags chain/stack rule sets (Cartesian-style limits); this script merges all ``*.rule`` files into one temporary rule file so every rule line applies without chaining limits.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def script_root() -> Path:
    return Path(__file__).resolve().parent


def resolve_hashcat() -> Path | None:
    env = os.environ.get("HASHCAT_PATH")
    if env:
        p = Path(env).expanduser()
        if p.is_file():
            return p.resolve()
    for name in ("hashcat.exe", "hashcat"):
        found = shutil.which(name)
        if found:
            return Path(found).resolve()
    default = Path(r"C:\hashcat\hashcat.exe")
    if default.is_file():
        return default.resolve()
    return None


def load_base_words(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    words: list[str] = []
    for line in text.splitlines():
        w = line.strip()
        if w and not w.startswith("#"):
            words.append(w)
    return words


def discover_rule_files(rules_dir: Path) -> list[Path]:
    return sorted(p.resolve() for p in rules_dir.glob("*.rule") if p.is_file())


def strip_utf8_bom(raw: bytes) -> bytes:
    return raw[3:] if raw.startswith(b"\xef\xbb\xbf") else raw


def write_merged_rules(rule_files: list[Path], out_path: Path) -> None:
    """Concatenate rule files in order (bytes) so hashcat sees one flat rule set."""
    with out_path.open("wb") as merged:
        for rf in rule_files:
            data = strip_utf8_bom(rf.read_bytes())
            if not data:
                continue
            merged.write(data)
            if not data.endswith(b"\n"):
                merged.write(b"\n")


def main() -> int:
    root = script_root()
    words_path = root / "dicts" / "0.txt"
    rules_dir = root / "rules"
    out_path = root / "dicts" / "customgenerated.txt"

    if not words_path.is_file():
        print(f"Missing wordlist: {words_path}", file=sys.stderr)
        return 1
    if not rules_dir.is_dir():
        print(f"Missing rules directory: {rules_dir}", file=sys.stderr)
        return 1

    rule_files = discover_rule_files(rules_dir)
    if not rule_files:
        print(f"No .rule files found in {rules_dir}", file=sys.stderr)
        return 1

    words = load_base_words(words_path)
    if not words:
        print(f"No words found in {words_path}", file=sys.stderr)
        return 1

    hashcat = resolve_hashcat()
    if hashcat is None:
        print(
            "hashcat not found. Set HASHCAT_PATH to hashcat.exe or add hashcat to PATH.",
            file=sys.stderr,
        )
        return 1

    out_path.parent.mkdir(parents=True, exist_ok=True)

    tmp_words: Path | None = None
    tmp_rules: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            suffix=".txt",
            delete=False,
            encoding="utf-8",
            newline="\n",
        ) as tmp:
            tmp.writelines(w + "\n" for w in words)
            tmp_words = Path(tmp.name)

        fd, merged_name = tempfile.mkstemp(suffix=".rule", prefix="merged-rules-")
        os.close(fd)
        tmp_rules = Path(merged_name)
        write_merged_rules(rule_files, tmp_rules)

        cmd: list[str] = [
            str(hashcat),
            "--force",
            "--stdout",
            str(tmp_words.resolve()),
            "-r",
            str(tmp_rules.resolve()),
        ]
        with out_path.open("wb") as out_f:
            cp = subprocess.run(
                cmd,
                cwd=str(hashcat.parent),
                stdout=out_f,
                stderr=subprocess.PIPE,
            )
        if cp.returncode != 0:
            sys.stderr.write(cp.stderr.decode(errors="replace"))
            return cp.returncode
    finally:
        if tmp_words is not None:
            tmp_words.unlink(missing_ok=True)
        if tmp_rules is not None:
            tmp_rules.unlink(missing_ok=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
