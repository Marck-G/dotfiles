#!/usr/bin/env python3
"""
rust_add_dep.py  ·  Add a dependency to Cargo.toml
Searches crates.io for versions and features, then appends to Cargo.toml.

Usage:
    python3 rust_add_dep.py --crate serde --cargo-toml /path/to/Cargo.toml
                            --features derive --dev --optional --json
"""

import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

CRATES_IO_API = "https://crates.io/api/v1"
HEADERS = {
    "User-Agent": "rust-tools.nvim/1.0 (neovim plugin)",
    "Accept": "application/json",
}


def api_get(url: str) -> dict | None:
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            return json.loads(resp.read().decode())
    except Exception:
        return None


def search_crate(name: str) -> list[dict]:
    """Search crates.io for crates matching name."""
    data = api_get(f"{CRATES_IO_API}/crates?q={name}&per_page=10")
    if not data:
        return []
    return [
        {
            "name": c["id"],
            "version": c["newest_version"],
            "description": (c.get("description") or "").strip()[:80],
            "downloads": c.get("downloads", 0),
        }
        for c in data.get("crates", [])
    ]


def get_crate_info(name: str) -> dict | None:
    """Get latest version info and features for a specific crate."""
    data = api_get(f"{CRATES_IO_API}/crates/{name}")
    if not data or "crate" not in data:
        return None

    crate = data["crate"]
    versions = data.get("versions", [])
    latest = next((v for v in versions if not v.get("yanked")), None)

    # Get features from latest version
    features = []
    if latest:
        feat_data = api_get(f"{CRATES_IO_API}/crates/{name}/{latest['num']}")
        if feat_data:
            features = list((feat_data.get("version") or {}).get("features", {}).keys())

    return {
        "name": crate["id"],
        "version": crate["newest_version"],
        "description": (crate.get("description") or "").strip(),
        "repository": crate.get("repository", ""),
        "features": [f for f in features if f != "default"],
        "downloads": crate.get("downloads", 0),
    }


def parse_cargo_toml(path: Path) -> dict:
    """Very simple TOML parser for Cargo.toml sections."""
    content = path.read_text()
    sections = {}
    current = None

    for line in content.splitlines():
        stripped = line.strip()
        section_match = re.match(r"^\[([^\]]+)\]$", stripped)
        if section_match:
            current = section_match.group(1)
            sections.setdefault(current, [])
        elif current is not None:
            sections[current].append(line)

    return sections


def dep_line_exists(cargo_toml: Path, dep_name: str) -> bool:
    """Check if a dependency is already in Cargo.toml."""
    content = cargo_toml.read_text()
    pattern = rf"^{re.escape(dep_name)}\s*="
    for line in content.splitlines():
        if re.match(pattern, line.strip()):
            return True
    return False


def add_dependency(
    cargo_toml_path: Path,
    crate_name: str,
    version: str,
    features: list[str],
    dev: bool,
    optional: bool,
    section: str | None = None,
) -> dict:
    """Add a dependency line to Cargo.toml."""

    if dep_line_exists(cargo_toml_path, crate_name):
        return {
            "success": False,
            "error": f"'{crate_name}' already exists in Cargo.toml",
        }

    content = cargo_toml_path.read_text()
    lines = content.splitlines()

    # Build the dependency line
    if features or optional:
        parts = [f'version = "{version}"']
        if features:
            feat_str = ", ".join(f'"{f}"' for f in features)
            parts.append(f"features = [{feat_str}]")
        if optional:
            parts.append("optional = true")
        dep_line = f'{crate_name} = {{ {", ".join(parts)} }}'
    else:
        dep_line = f'{crate_name} = "{version}"'

    # Determine target section
    target_section = section or ("dev-dependencies" if dev else "dependencies")

    # Find the section in the file and append after it
    section_pattern = re.compile(rf"^\[{re.escape(target_section)}\]")
    inserted = False
    new_lines = []
    i = 0

    while i < len(lines):
        new_lines.append(lines[i])
        if section_pattern.match(lines[i].strip()):
            # Skip existing deps in this section, insert at end
            j = i + 1
            while j < len(lines) and not re.match(r"^\[", lines[j].strip()):
                new_lines.append(lines[j])
                j += 1
            new_lines.append(dep_line)
            i = j
            inserted = True
            continue
        i += 1

    # Section doesn't exist yet — append it
    if not inserted:
        new_lines.append("")
        new_lines.append(f"[{target_section}]")
        new_lines.append(dep_line)

    cargo_toml_path.write_text("\n".join(new_lines) + "\n")

    return {
        "success": True,
        "crate": crate_name,
        "version": version,
        "section": target_section,
        "line": dep_line,
    }


def main():
    parser = argparse.ArgumentParser(description="Add a Rust dependency")
    parser.add_argument("--crate", required=True, help="Crate name to add")
    parser.add_argument("--cargo-toml", required=True, help="Path to Cargo.toml")
    parser.add_argument("--version", default=None, help="Version (latest if omitted)")
    parser.add_argument("--features", default="", help="Comma-separated features")
    parser.add_argument("--dev", action="store_true", help="Add to [dev-dependencies]")
    parser.add_argument("--optional", action="store_true", help="Mark as optional")
    parser.add_argument(
        "--search", action="store_true", help="Search mode: print matches as JSON"
    )
    parser.add_argument(
        "--info", action="store_true", help="Info mode: print crate info as JSON"
    )
    parser.add_argument("--json", action="store_true", help="Output result as JSON")

    args = parser.parse_args()

    # ── Search mode ───────────────────────────────────────
    if args.search:
        results = search_crate(args.crate)
        print(json.dumps(results))
        return

    # ── Info mode ─────────────────────────────────────────
    if args.info:
        info = get_crate_info(args.crate)
        if info:
            print(json.dumps(info))
        else:
            print(json.dumps({"error": f"Crate '{args.crate}' not found"}))
        return

    # ── Add mode ──────────────────────────────────────────
    cargo_toml = Path(args.cargo_toml)
    if not cargo_toml.exists():
        result = {"success": False, "error": f"Cargo.toml not found: {cargo_toml}"}
    else:
        # Fetch latest version if not specified
        version = args.version
        if not version:
            info = get_crate_info(args.crate)
            if info:
                version = info["version"]
            else:
                result = {
                    "success": False,
                    "error": f"Could not find crate '{args.crate}' on crates.io",
                }
                print(json.dumps(result) if args.json else f"❌ {result['error']}")
                sys.exit(1)

        features = [f.strip() for f in args.features.split(",") if f.strip()]

        result = add_dependency(
            cargo_toml_path=cargo_toml,
            crate_name=args.crate,
            version=version,
            features=features,
            dev=args.dev,
            optional=args.optional,
        )

    if args.json:
        print(json.dumps(result))
    else:
        if result["success"]:
            print(
                f"✅ Added {result['crate']} = \"{result['version']}\" to [{result['section']}]"
            )
            print(f"   Line: {result['line']}")
        else:
            print(f"❌ {result['error']}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
