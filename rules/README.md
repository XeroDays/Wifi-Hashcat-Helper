# Check rules

Hashcat rule files for basic and numeric suffix attacks.

---

## check-1.rule

Basics only: identity, remove space, case, and common suffixes. **20 rules.**

| Rule | Name | Effect | Example |
|------|------|--------|---------|
| `:` | Nothing | Pass through unchanged | `word` → `word` |
| `@ ` | Purge | Remove all spaces | `hello world` → `helloworld` |
| `l` | Lowercase | Lowercase all letters | `Word` → `word` |
| `u` | Uppercase | Uppercase all letters | `word` → `WORD` |
| `c` | Capitalize | First char upper, rest lower | `word` → `Word` |
| `$0` … `$9` | Append | Single digit suffix | `word` → `word0` … `word9` |
| `$!` | Append | Suffix `!` | `word` → `word!` |
| `$?` | Append | Suffix `?` | `word` → `word?` |
| `$1$2$3` | Append | Suffix `123` | `word` → `word123` |
| `$@$1$2$3` | Append | Suffix `@123` | `word` → `word@123` |

**Usage:** `hashcat -m 22000 -a 0 hashes/file.hc22000 dicts/wordlist.txt -r rules/check-1.rule`

---

## check-2.rule

Numeric suffix 0–9999, plus capitalize-then-suffix. **20,000 rules.**

| Block | Rules | Effect | Example |
|-------|--------|--------|---------|
| Plain suffix | 10,000 | Append 0, 1, 2, … 9999 | `word` → `word0`, `word42`, `word9999` |
| Capitalize + suffix | 10,000 | Capitalize first, then append 0–9999 | `word` → `Word0`, `Word42`, `Word9999` |

Use when targets add numbers (pins, years, counters) without a separator.

**Usage:** `hashcat -m 22000 -a 0 hashes/file.hc22000 dicts/wordlist.txt -r rules/check-2.rule`

---

## check-3.rule

Suffix @0–@9999, plus capitalize-then-@suffix. **20,000 rules.**

| Block | Rules | Effect | Example |
|-------|--------|--------|---------|
| @ suffix | 10,000 | Append @0, @1, … @9999 | `word` → `word@0`, `word@42`, `word@9999` |
| Capitalize + @ suffix | 10,000 | Capitalize first, then append @0–@9999 | `word` → `Word@0`, `Word@42`, `Word@9999` |

Use when targets use an @ before the number (e.g. email-style or “word@123”).

**Usage:** `hashcat -m 22000 -a 0 hashes/file.hc22000 dicts/wordlist.txt -r rules/check-3.rule`
