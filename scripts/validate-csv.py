#!/usr/bin/env python3
"""Validate CSV data files for structural issues that csv.DictReader silently accepts.

Integrated from third-party ui-ux/validate-csv.py, generalized for wagents.

Checks every CSV under a target directory (default: the whole repo):
- duplicate or blank header names
- rows with too many fields (unquoted commas)
- rows with too few fields (missing trailing columns)
- unexpected blank rows inside the dataset

Usage:
  python3 scripts/validate-csv.py                 # scan repo (skips .git, node_modules)
  python3 scripts/validate-csv.py DIR [DIR...]    # scan specific directories/files
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {".git", "node_modules", ".github", "_third-party", "vendor"}


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    rel = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path

    try:
        with path.open("r", encoding="utf-8-sig", newline="") as fh:
            reader = csv.reader(fh)
            try:
                header = next(reader)
            except StopIteration:
                errors.append(f"{rel}: empty file")
                return errors

            if not header or all(not col.strip() for col in header):
                errors.append(f"{rel}: missing header")
                return errors

            blank_headers = [i + 1 for i, col in enumerate(header) if not col.strip()]
            if blank_headers:
                errors.append(f"{rel}: blank header columns {blank_headers}")

            duplicates = sorted({col for col in header if col and header.count(col) > 1})
            if duplicates:
                errors.append(f"{rel}: duplicate headers {duplicates}")

            expected = len(header)
            for line_no, row in enumerate(reader, start=2):
                if not row or all(not cell.strip() for cell in row):
                    errors.append(f"{rel}:{line_no}: blank row")
                    continue
                if len(row) != expected:
                    errors.append(
                        f"{rel}:{line_no}: expected {expected} fields, got {len(row)}"
                    )
    except UnicodeDecodeError:
        errors.append(f"{rel}: not valid UTF-8")
    return errors


def main() -> int:
    targets = [Path(a) for a in sys.argv[1:]]
    if not targets:
        targets = [ROOT]

    files: list[Path] = []
    for target in targets:
        if not target.exists():
            print(f"csv-validate: target not found: {target}", file=sys.stderr)
            return 2
        if target.is_file():
            files.append(target)
        else:
            files.extend(
                p for p in sorted(target.rglob("*.csv"))
                if not any(part in SKIP_DIRS for part in p.parts)
            )

    if not files:
        print("csv-validate: no CSV files found — nothing to check.")
        return 0

    errors: list[str] = []
    for path in files:
        errors.extend(validate_file(path))

    if errors:
        print("CSV validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        print(f"\nChecked {len(files)} CSV file(s).", file=sys.stderr)
        return 1

    print(f"CSV validation passed: {len(files)} CSV file(s) checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
