#!/usr/bin/env python3
"""
rust_new_module.py  ·  Create a new Rust module (file or directory module)
Handles: mod declaration injection, pub/private, nested modules.

Usage:
    python3 rust_new_module.py --name my_module --src /path/to/src
                               --type file|dir --parent lib|main|path/to/parent
                               --visibility pub|pub(crate)|private
"""

import argparse
import json
import re
import sys
from pathlib import Path


def to_snake_case(name: str) -> str:
    """Convert any case to snake_case."""
    # Insert underscore before uppercase letters
    s1 = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    s2 = re.sub(r"([a-z\d])([A-Z])", r"\1_\2", s1)
    return s2.replace("-", "_").lower()


def to_pascal_case(name: str) -> str:
    return "".join(w.capitalize() for w in name.replace("-", "_").split("_"))


def get_module_template(module_name: str, mod_type: str, visibility: str) -> str:
    """Generate template content for a new module."""
    pascal = to_pascal_case(module_name)
    vis = "" if visibility == "private" else visibility + " "

    if mod_type == "dir":
        return f"""\
//! Module: {module_name}

{vis}mod tests;

/// Main struct for {module_name}
{vis}struct {pascal} {{
    // TODO: add fields
}}

impl {pascal} {{
    /// Create a new {pascal} instance
    {vis}fn new() -> Self {{
        Self {{
            // TODO: initialize fields
        }}
    }}
}}

#[cfg(test)]
mod tests {{
    use super::*;

    #[test]
    fn test_{module_name}_creation() {{
        // TODO: add tests
    }}
}}
"""
    else:
        return f"""\
//! Module: {module_name}

/// Main struct for {module_name}
{vis}struct {pascal} {{
    // TODO: add fields
}}

impl {pascal} {{
    /// Create a new {pascal} instance
    {vis}fn new() -> Self {{
        Self {{
            // TODO: initialize fields
        }}
    }}
}}

#[cfg(test)]
mod tests {{
    use super::*;

    #[test]
    fn test_{module_name}_creation() {{
        // TODO: add tests
    }}
}}
"""


def inject_mod_declaration(
    parent_file: Path, module_name: str, visibility: str
) -> bool:
    """Add `mod module_name;` to the parent file."""
    if not parent_file.exists():
        return False

    content = parent_file.read_text()
    vis = "" if visibility == "private" else visibility + " "
    mod_decl = f"{vis}mod {module_name};"

    # Don't add if already declared
    if re.search(
        rf"^(pub\s+|pub\(crate\)\s+)?mod\s+{re.escape(module_name)}\s*;",
        content,
        re.MULTILINE,
    ):
        return False  # already exists

    lines = content.splitlines()
    new_lines = []
    inserted = False

    # Try to insert after the last existing `mod` declaration
    last_mod_idx = -1
    for i, line in enumerate(lines):
        if re.match(r"^(pub\s+|pub\(crate\)\s+)?mod\s+\w+\s*;", line.strip()):
            last_mod_idx = i

    if last_mod_idx >= 0:
        for i, line in enumerate(lines):
            new_lines.append(line)
            if i == last_mod_idx and not inserted:
                new_lines.append(mod_decl)
                inserted = True
    else:
        # No existing mod declarations — find end of use statements
        last_use_idx = -1
        for i, line in enumerate(lines):
            if re.match(r"^use\s+", line.strip()):
                last_use_idx = i

        if last_use_idx >= 0:
            for i, line in enumerate(lines):
                new_lines.append(line)
                if i == last_use_idx and not inserted:
                    new_lines.append("")
                    new_lines.append(mod_decl)
                    inserted = True
        else:
            # Prepend after any doc comments / attributes at the top
            header_end = 0
            for i, line in enumerate(lines):
                stripped = line.strip()
                if (
                    stripped.startswith("//!")
                    or stripped.startswith("#![")
                    or stripped == ""
                ):
                    header_end = i + 1
                else:
                    break
            new_lines = lines[:header_end] + [mod_decl, ""] + lines[header_end:]
            inserted = True

    if not inserted:
        new_lines.append(mod_decl)

    parent_file.write_text("\n".join(new_lines) + "\n")
    return True


def find_parent_file(src: Path, parent: str) -> Path | None:
    """Resolve the parent module file."""
    if parent in ("lib", "lib.rs"):
        return src / "lib.rs"
    elif parent in ("main", "main.rs"):
        return src / "main.rs"
    elif parent.endswith(".rs"):
        return src / parent
    else:
        # It could be a mod.rs inside a directory
        dir_mod = src / parent / "mod.rs"
        if dir_mod.exists():
            return dir_mod
        direct = src / (parent + ".rs")
        if direct.exists():
            return direct
    return None


def create_module(args) -> dict:
    src = Path(args.src)
    name = to_snake_case(args.name)
    visibility = args.visibility
    mod_type = args.type

    if not src.exists():
        return {"success": False, "error": f"src directory not found: {src}"}

    # ── Resolve parent file ────────────────────────────────
    parent_file = find_parent_file(src, args.parent)

    # ── Create module ──────────────────────────────────────
    if mod_type == "file":
        # Create src/name.rs
        target_file = src / (name + ".rs")
        if target_file.exists():
            return {
                "success": False,
                "error": f"Module file already exists: {target_file}",
            }

        target_file.write_text(get_module_template(name, "file", visibility))
        created_files = [str(target_file)]

    elif mod_type == "dir":
        # Create src/name/mod.rs (old style) or src/name.rs + src/name/ (new style)
        if args.new_style:
            # Rust 2018+ style: src/name.rs as the module root
            module_dir = src / name
            module_root = src / (name + ".rs")
        else:
            # Classic style: src/name/mod.rs
            module_dir = src / name
            module_root = module_dir / "mod.rs"

        if module_dir.exists() and module_root.exists():
            return {"success": False, "error": f"Module already exists: {module_dir}"}

        module_dir.mkdir(parents=True, exist_ok=True)
        module_root.write_text(get_module_template(name, "dir", visibility))
        created_files = [str(module_root), str(module_dir)]
    else:
        return {"success": False, "error": f"Unknown module type: {mod_type}"}

    # ── Inject mod declaration into parent ─────────────────
    injected_parent = None
    if parent_file:
        injected = inject_mod_declaration(parent_file, name, visibility)
        if injected:
            injected_parent = str(parent_file)

    return {
        "success": True,
        "module_name": name,
        "type": mod_type,
        "created_files": created_files,
        "injected_into": injected_parent,
        "main_file": created_files[0],
    }


def main():
    parser = argparse.ArgumentParser(description="Create a new Rust module")
    parser.add_argument("--name", required=True, help="Module name (snake_case)")
    parser.add_argument("--src", required=True, help="Path to src/ directory")
    parser.add_argument("--type", default="file", choices=["file", "dir"])
    parser.add_argument(
        "--parent", default="lib", help="Parent module (lib, main, or path)"
    )
    parser.add_argument(
        "--visibility", default="pub", choices=["pub", "pub(crate)", "private"]
    )
    parser.add_argument(
        "--new-style", action="store_true", help="Use Rust 2018+ module style"
    )
    parser.add_argument("--json", action="store_true", help="Output result as JSON")

    args = parser.parse_args()
    result = create_module(args)

    if args.json:
        print(json.dumps(result))
    else:
        if result["success"]:
            print(f"✅ Created module '{result['module_name']}' ({result['type']})")
            for f in result["created_files"]:
                print(f"   📄 {f}")
            if result["injected_into"]:
                print(
                    f"   ✏️  Added `mod {result['module_name']};` to {result['injected_into']}"
                )
        else:
            print(f"❌ {result['error']}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
