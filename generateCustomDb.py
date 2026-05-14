#!/usr/bin/env python3
"""Generate dicts/customgenerated.txt by applying custom rules to every word in dicts/0.txt.

Rules are declared as a static list near the top of this file — add new entries there.
Each rule is a tuple of (symbol, description, transform_fn).
"""

from __future__ import annotations

import re
import sys
import time
from itertools import permutations, product
from pathlib import Path


def rule(symbol: str, description: str) -> tuple[str, str, object]:
    """Build a rule tuple by parsing the symbol string.

    Supported patterns:
      {$}          — word as-is
      {C}          — capitalize first letter
      {$}{N~M}       — word + looped numbers N to M
                       e.g. {$}{1~100} → word1, word2 … word100
      {C}{N~M}       — capitalized word + looped numbers
      {$}PREFIX{N~M} — word + literal PREFIX + looped numbers
                       e.g. {$}@{1~100} → word@1, word@2 … word@100
      {C}PREFIX{N~M} — capitalized word + PREFIX + looped numbers
      {$}TEXT        — word + TEXT as a plain literal (no loop, single output)
                       e.g. {$}@gmail.com → word@gmail.com
      {C}TEXT        — capitalized word + TEXT literal

    For any numeric range, when M has 2+ digits, zero-padded variants are
    also emitted for widths 2 … len(str(M)), skipping forms identical to plain.
    Example for {$}@{1~100}:
      plain:    word@1 … word@100
      width-2:  word@01 … word@09
      width-3:  word@001 … word@099
    """
    # Matches {$}OPTIONAL_PREFIX{N~M}  — the prefix may be empty
    m_range = re.fullmatch(r"\{(\$|C)\}(.*)\{(\d+)~(\d+)\}", symbol)
    m_base  = re.fullmatch(r"\{(\$|C)\}",                     symbol)
    m_lit   = re.fullmatch(r"\{(\$|C)\}(.+)",                 symbol)

    if m_range:
        base   = m_range.group(1)
        prefix = m_range.group(2)   # e.g. "@" or "" for plain {$}{N~M}
        start  = m_range.group(3)
        end    = m_range.group(4)
        suffix = None
    elif m_base:
        base, prefix, start, end, suffix = m_base.group(1), "", None, None, None
    elif m_lit:
        base, prefix, start, end = m_lit.group(1), "", None, None
        suffix = m_lit.group(2)
    else:
        raise ValueError(f"Unrecognized rule symbol: {symbol!r}")

    def transform(w: str) -> str | list[str]:
        word = w[0].upper() + w[1:] if (base == "C" and w) else w
        if suffix is not None:
            return f"{word}{suffix}"
        if start is not None:
            a, b = int(start), int(end)
            results = [f"{word}{prefix}{n}" for n in range(a, b + 1)]
            if len(str(b)) >= 2:
                for k in range(2, len(str(b)) + 1):
                    for n in range(a, b + 1):
                        p = str(n).zfill(k)
                        if p != str(n):
                            results.append(f"{word}{prefix}{p}")
            return results
        return word

    return (symbol, description, transform)


# ---------------------------------------------------------------------------
# Custom rule definitions
# Add new rules here — only the symbol string and a description are needed.
# ---------------------------------------------------------------------------
RULES = [
    rule("{$}",          "Word as-is"),
    rule("{$}{1~10000}", "Word + {number} 1 to 10000"),
    rule("{$}@{1~10000}", "Word + {number} 1 to 10000"), 
    rule("{$}!{1~10000}", "Word + {number} 1 to 10000"), 
    rule("{$}${1~10000}", "Word + {number} 1 to 10000"), 
    rule("{$}#{1~10000}", "Word + {number} 1 to 10000"), 
    rule("{1~10000}", "  {number} 1 to 10000"), 
    
]


def script_root() -> Path:
    return Path(__file__).resolve().parent


def load_base_words(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    words: list[str] = []
    for line in text.splitlines():
        w = line.strip()
        if w and not w.startswith("#"):
            words.append(w)
    return words


def _cap(w: str) -> str:
    return w[0].upper() + w[1:] if w else w


def expand_combinations(words: list[str]) -> list[str]:
    """Return all ordered concatenations of the input words with capitalisation variants.

    For every permutation of every non-empty subset (length 1 … n):
      - Each word segment can independently be lowercase, Title-case, or UPPERCASE.
      - All combos of a k-word permutation are produced and joined. 
    """
    seen: dict[str, None] = {}
    result: list[str] = []
    for length in range(1, len(words) + 1):
        for perm in permutations(words, length):
            variants: list[list[str]] = []
            for w in perm:
                caps: list[str] = [w]
                c = _cap(w)
                if c != w:
                    caps.append(c)
                u = w.upper()
                if u != w and u not in caps:
                    caps.append(u)
                variants.append(caps)
            for combo in product(*variants):
                combined = "".join(combo)
                if combined not in seen:
                    seen[combined] = None
                    result.append(combined)
    return result


def main() -> int:
    root = script_root()
    words_path = root / "dicts" / "0.txt"
    out_path = root / "dicts" / "customgenerated.txt"

    if not words_path.is_file():
        print(f"Missing wordlist: {words_path}", file=sys.stderr)
        return 1

    words = load_base_words(words_path)
    if not words:
        print(f"No words found in {words_path}", file=sys.stderr)
        return 1

    print(f"Loaded {len(words)} base word(s):")
    for w in words:
        print(f"  {w}")
    print()

    words = expand_combinations(words)
    print(f"Expanded to {len(words)} combination(s) to process:")
    for w in words:
        print(f"  {w}")
    print()

    print("Starting in 3 seconds...")
    for remaining in range(3, 0, -1):
        print(f"  {remaining}...", flush=True)
        time.sleep(1)
    print()

    seen: dict[str, None] = {}
    generated: list[str] = []

    for symbol, description, transform in RULES:
        print(f"Applying rule [{symbol}] {description}...")
        for w in words:
            result = transform(w)  # type: ignore[operator]
            results = result if isinstance(result, list) else [result]
            for r in results:
                if r not in seen:
                    seen[r] = None
                    generated.append(r)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(generated) + "\n", encoding="utf-8")

    print(f"\nWritten {len(generated)} word(s) to {out_path.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
