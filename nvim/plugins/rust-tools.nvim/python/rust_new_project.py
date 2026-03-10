#!/usr/bin/env python3
"""
rust_new_project.py  ·  Create a new Rust project with templates
Called by rust-tools.nvim with JSON args via stdin or argv.

Usage:
    python3 rust_new_project.py --name my-app --type bin --path /home/user/projects
                                --vcs git --edition 2021 --template cli|web|lib|empty
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

# ── Project templates ──────────────────────────────────────────────────────────

TEMPLATES = {
    "empty": {
        "description": "Minimal project (just cargo new)",
        "deps": [],
        "extra_files": {},
    },
    "cli": {
        "description": "CLI application (clap + anyhow)",
        "deps": [
            'clap = { version = "4", features = ["derive"] }',
            'anyhow = "1"',
            'env_logger = "0.11"',
            'log = "0.4"',
        ],
        "dev_deps": [],
        "extra_files": {
            "src/main.rs": """\
use clap::Parser;
use anyhow::Result;

/// {name} - CLI Application
#[derive(Parser, Debug)]
#[command(name = "{name}", version, about, long_about = None)]
struct Args {{
    /// Verbose output
    #[arg(short, long)]
    verbose: bool,

    /// Input value
    #[arg(short, long)]
    input: Option<String>,
}}

fn main() -> Result<()> {{
    env_logger::init();
    let args = Args::parse();

    if args.verbose {{
        log::info!("Running in verbose mode");
    }}

    println!("Hello from {name}!");

    if let Some(input) = args.input {{
        println!("Input: {{input}}");
    }}

    Ok(())
}}
""",
        },
    },
    "web": {
        "description": "Web service (axum + tokio + serde)",
        "deps": [
            'axum = "0.7"',
            'tokio = { version = "1", features = ["full"] }',
            'serde = { version = "1", features = ["derive"] }',
            'serde_json = "1"',
            'tower = "0.4"',
            'tower-http = { version = "0.5", features = ["trace", "cors"] }',
            'tracing = "0.1"',
            'tracing-subscriber = { version = "0.3", features = ["env-filter"] }',
            'anyhow = "1"',
        ],
        "extra_files": {
            "src/main.rs": """\
use axum::{{
    routing::{{get, post}},
    Router, Json,
    extract::State,
    http::StatusCode,
}};
use serde::{{Deserialize, Serialize}};
use std::sync::Arc;
use tokio::net::TcpListener;

#[derive(Clone)]
struct AppState {{
    // Add your shared state here
}}

#[derive(Serialize)]
struct HealthResponse {{
    status: String,
    version: String,
}}

#[derive(Deserialize, Serialize)]
struct EchoRequest {{
    message: String,
}}

async fn health() -> Json<HealthResponse> {{
    Json(HealthResponse {{
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    }})
}}

async fn echo(Json(payload): Json<EchoRequest>) -> (StatusCode, Json<EchoRequest>) {{
    (StatusCode::OK, Json(payload))
}}

#[tokio::main]
async fn main() -> anyhow::Result<()> {{
    tracing_subscriber::fmt()
        .with_env_filter("info")
        .init();

    let state = Arc::new(AppState {{}});

    let app = Router::new()
        .route("/health", get(health))
        .route("/echo",   post(echo))
        .with_state(state);

    let addr = "0.0.0.0:3000";
    tracing::info!("Listening on {{}}", addr);
    let listener = TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}}
""",
        },
    },
    "lib": {
        "description": "Library crate with tests and docs",
        "deps": [
            'thiserror = "1"',
            'log = "0.4"',
        ],
        "dev_deps": [
            'env_logger = "0.11"',
        ],
        "extra_files": {
            "src/lib.rs": """\
//! # {name}
//!
//! A Rust library.
//!
//! ## Example
//!
//! ```rust
//! use {name_snake}::add;
//! assert_eq!(add(2, 3), 5);
//! ```

use thiserror::Error;

/// Errors for {name}
#[derive(Error, Debug)]
pub enum {name_pascal}Error {{
    #[error("invalid input: {{0}}")]
    InvalidInput(String),

    #[error("io error: {{0}}")]
    Io(#[from] std::io::Error),
}}

pub type Result<T> = std::result::Result<T, {name_pascal}Error>;

/// Add two numbers together.
///
/// # Examples
///
/// ```
/// use {name_snake}::add;
/// assert_eq!(add(2, 3), 5);
/// ```
pub fn add(a: i32, b: i32) -> i32 {{
    a + b
}}

#[cfg(test)]
mod tests {{
    use super::*;

    #[test]
    fn test_add() {{
        assert_eq!(add(2, 3), 5);
        assert_eq!(add(-1, 1), 0);
    }}
}}
""",
        },
    },
}


def to_pascal_case(name: str) -> str:
    return "".join(w.capitalize() for w in name.replace("-", "_").split("_"))


def to_snake_case(name: str) -> str:
    return name.replace("-", "_")


def run(cmd: list, cwd: str = None) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def create_project(args) -> dict:
    project_path = Path(args.path) / args.name

    if project_path.exists():
        return {"success": False, "error": f"Directory already exists: {project_path}"}

    # ── Run cargo new / cargo init ─────────────────────────
    cargo_cmd = ["cargo", "new", str(project_path)]
    if args.type == "lib":
        cargo_cmd.append("--lib")
    if args.vcs != "git":
        cargo_cmd.extend(["--vcs", args.vcs])
    if args.edition:
        cargo_cmd.extend(["--edition", args.edition])

    result = run(cargo_cmd)
    if result.returncode != 0:
        return {"success": False, "error": result.stderr}

    # ── Apply template ─────────────────────────────────────
    template = TEMPLATES.get(args.template, TEMPLATES["empty"])
    pascal = to_pascal_case(args.name)
    snake = to_snake_case(args.name)

    # Add dependencies to Cargo.toml
    deps = template.get("deps", [])
    dev_deps = template.get("dev_deps", [])

    if deps or dev_deps:
        cargo_toml = project_path / "Cargo.toml"
        content = cargo_toml.read_text()

        if deps:
            dep_block = "\n".join(deps)
            content += f"\n[dependencies]\n{dep_block}\n"
        if dev_deps:
            dev_block = "\n".join(dev_deps)
            content += f"\n[dev-dependencies]\n{dev_block}\n"

        cargo_toml.write_text(content)

    # Write template source files
    for rel_path, file_content in template.get("extra_files", {}).items():
        target = project_path / rel_path
        target.parent.mkdir(parents=True, exist_ok=True)
        rendered = file_content.format(
            name=args.name,
            name_pascal=pascal,
            name_snake=snake,
        )
        target.write_text(rendered)

    # ── Create standard directories ────────────────────────
    extra_dirs = ["tests", "examples", "benches", "docs"]
    for d in extra_dirs:
        (project_path / d).mkdir(exist_ok=True)
        (project_path / d / ".gitkeep").touch()

    # ── Create .env.example ───────────────────────────────
    env_example = project_path / ".env.example"
    env_example.write_text("# Environment variables\nRUST_LOG=info\n")

    # ── Create README.md ──────────────────────────────────
    readme = project_path / "README.md"
    readme.write_text(f"""# {args.name}

{template['description']}

## Getting Started

```bash
cargo build
cargo run
cargo test
```

## Project Structure

```
{args.name}/
├── src/
│   └── {'main' if args.type == 'bin' else 'lib'}.rs
├── tests/
├── examples/
├── Cargo.toml
└── README.md
```
""")

    # ── Initial cargo fetch (download deps) ───────────────
    if deps:
        run(["cargo", "fetch"], cwd=str(project_path))

    return {
        "success": True,
        "path": str(project_path),
        "name": args.name,
        "template": args.template,
        "type": args.type,
    }


def main():
    parser = argparse.ArgumentParser(description="Create a new Rust project")
    parser.add_argument("--name", required=True, help="Project name")
    parser.add_argument(
        "--type", default="bin", choices=["bin", "lib"], help="Project type"
    )
    parser.add_argument(
        "--path", required=True, help="Parent directory for new project"
    )
    parser.add_argument(
        "--vcs", default="git", choices=["git", "hg", "pijul", "fossil", "none"]
    )
    parser.add_argument("--edition", default="2021", choices=["2015", "2018", "2021"])
    parser.add_argument("--template", default="empty", choices=list(TEMPLATES.keys()))
    parser.add_argument("--json", action="store_true", help="Output result as JSON")

    args = parser.parse_args()
    result = create_project(args)

    if args.json:
        print(json.dumps(result))
    else:
        if result["success"]:
            print(f"✅ Created {result['name']} at {result['path']}")
        else:
            print(f"❌ Error: {result['error']}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
