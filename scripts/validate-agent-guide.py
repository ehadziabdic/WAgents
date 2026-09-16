#!/usr/bin/env python3
"""Validate wagents agent guide files.

Integrated concept from third-party ui-ux/validate-agent-guide.py, adapted:
- every .agent.md in .github/agents has a frontmatter with name + description
- the name matches the file name
- any `skills/...` or skill-name references point to real skill directories
- every SKILL.md in .github/skills has a frontmatter with name + description
- the SKILL.md name matches its directory name
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT / ".github" / "agents"
SKILLS = ROOT / ".github" / "skills"

FRONTMATTER_RE = re.compile(r"\A---\s*\n(.*?)\n---", re.DOTALL)


def frontmatter(text: str) -> dict[str, str]:
    # Strip UTF-8 BOM if present (many SKILL.md files carry one).
    if text.startswith("\ufeff"):
        text = text[1:]
    match = FRONTMATTER_RE.match(text)
    fields: dict[str, str] = {}
    if not match:
        return fields
    for line in match.group(1).splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip().strip("\"'")
    return fields


def validate_agent(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    fm = frontmatter(text)
    if not fm:
        return [f"{path.name}: missing YAML frontmatter"]
    # File convention: <name>.agent.md -> expected name is <name>.
    expected_name = path.stem[:-len(".agent")] if path.stem.endswith(".agent") else path.stem
    name = fm.get("name", "")
    if name != expected_name:
        errors.append(f"{path.name}: frontmatter name {name!r} != expected {expected_name!r}")
    if not fm.get("description"):
        errors.append(f"{path.name}: missing description in frontmatter")
    # Skill references like "skills/<name>" or ".github/skills/<name>" must exist.
    # Skill references like "skills/<name>" or ".github/skills/<name>" must exist.
    for ref in re.findall(r"(?:\.github/)?skills/([A-Za-z0-9_-]+)/", text):
        if ref.startswith("_"):
            continue  # underscore dirs are support dirs (no SKILL.md), e.g. _devops-pack-docs
        if not (SKILLS / ref / "SKILL.md").exists():
            errors.append(f"{path.name}: references missing skill: {ref}")
    return errors


def validate_skill(skill_dir: Path) -> list[str]:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return [f"{skill_dir.name}: missing SKILL.md"]
    text = skill_md.read_text(encoding="utf-8")
    fm = frontmatter(text)
    if not fm:
        return [f"{skill_dir.name}: SKILL.md missing YAML frontmatter"]
    errors: list[str] = []
    name = fm.get("name", "")
    if name and name != skill_dir.name:
        errors.append(f"{skill_dir.name}: SKILL.md name {name!r} != directory name")
    if not fm.get("description"):
        errors.append(f"{skill_dir.name}: SKILL.md missing description")
    return errors

def main() -> int:
    errors: list[str] = []

    if AGENTS.exists():
        agents = sorted(AGENTS.glob("*.agent.md"))
        if not agents:
            errors.append("no .agent.md files found in .github/agents")
        for path in agents:
            errors.extend(validate_agent(path))
    else:
        errors.append(".github/agents directory not found")

    if SKILLS.exists():
        skill_dirs = sorted(p for p in SKILLS.iterdir() if p.is_dir() and not p.name.startswith("_"))
        if not skill_dirs:
            errors.append("no skill directories found in .github/skills")
        for skill_dir in skill_dirs:
            errors.extend(validate_skill(skill_dir))
    else:
        errors.append(".github/skills directory not found")

    if errors:
        print("Agent guide validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    agents_n = len(list(AGENTS.glob("*.agent.md"))) if AGENTS.exists() else 0
    skills_n = len([p for p in SKILLS.iterdir() if p.is_dir() and not p.name.startswith("_")]) if SKILLS.exists() else 0
    print(f"Agent guide validation passed: {agents_n} agents, {skills_n} skills checked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
