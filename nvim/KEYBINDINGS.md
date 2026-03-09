# ⌨️ Neovim IDE — Keybindings Reference

> **Leader key** = `Space`
> Notation: `<leader>` = Space · `<C-x>` = Ctrl+x · `<A-x>` = Alt+x · `<S-x>` = Shift+x

---

## 📋 Table of Contents

- [General](#-general)
- [Navigation](#-navigation)
- [Windows & Splits](#-windows--splits)
- [Buffers & Tabs](#-buffers--tabs)
- [Search & Motion](#-search--motion)
- [Editing](#-editing)
- [File Explorer](#-file-explorer)
- [Telescope (Fuzzy Finder)](#-telescope-fuzzy-finder)
- [LSP — Code Intelligence](#-lsp--code-intelligence)
- [Formatting & Linting](#-formatting--linting)
- [Diagnostics & Trouble](#-diagnostics--trouble)
- [Debug (DAP)](#-debug-dap)
- [Git](#-git)
- [Sessions](#-sessions)
- [UI & Utilities](#-ui--utilities)
- [Language: Rust](#-language-rust)
- [Language: Java](#-language-java)
- [Language: Python](#-language-python)
- [Language: Web (JS/TS/Node)](#-language-web-jstsnodehtml)
- [Language: SQL](#-language-sql)
- [Language: Makefile](#-language-makefile)
- [Treesitter Text Objects](#-treesitter-text-objects)
- [Surround](#-surround)
- [Comment](#-comment)

---

## 🔧 General

| Key          | Mode   | Description             |
| ------------ | ------ | ----------------------- |
| `<leader>w`  | Normal | Save file               |
| `<leader>q`  | Normal | Quit                    |
| `<leader>Q`  | Normal | Force quit all          |
| `jk` / `kj`  | Insert | Exit insert mode        |
| `<leader>nh` | Normal | Clear search highlights |
| `<leader>st` | Normal | Startup time profiler   |

---

## 🧭 Navigation

| Key     | Mode   | Description                   |
| ------- | ------ | ----------------------------- |
| `<C-h>` | Normal | Move to left window           |
| `<C-j>` | Normal | Move to lower window          |
| `<C-k>` | Normal | Move to upper window          |
| `<C-l>` | Normal | Move to right window          |
| `n`     | Normal | Next search result (centered) |
| `N`     | Normal | Prev search result (centered) |
| `]]`    | Normal | Next reference (illuminate)   |
| `[[`    | Normal | Prev reference (illuminate)   |
| `]f`    | Normal | Next function (treesitter)    |
| `[f`    | Normal | Prev function (treesitter)    |
| `]c`    | Normal | Next class (treesitter)       |
| `[c`    | Normal | Prev class (treesitter)       |
| `]h`    | Normal | Next git hunk                 |
| `[h`    | Normal | Prev git hunk                 |
| `]d`    | Normal | Next diagnostic               |
| `[d`    | Normal | Prev diagnostic               |
| `]t`    | Normal | Next TODO comment             |
| `[t`    | Normal | Prev TODO comment             |
| `[q`    | Normal | Prev quickfix item            |
| `]q`    | Normal | Next quickfix item            |

---

## 🪟 Windows & Splits

| Key          | Mode   | Description          |
| ------------ | ------ | -------------------- |
| `<leader>sv` | Normal | Split vertical       |
| `<leader>sh` | Normal | Split horizontal     |
| `<leader>se` | Normal | Equalize split sizes |
| `<leader>sx` | Normal | Close current split  |
| `<C-Up>`     | Normal | Resize split up      |
| `<C-Down>`   | Normal | Resize split down    |
| `<C-Left>`   | Normal | Resize split left    |
| `<C-Right>`  | Normal | Resize split right   |

---

## 📑 Buffers & Tabs

| Key          | Mode   | Description                 |
| ------------ | ------ | --------------------------- |
| `<S-l>`      | Normal | Next buffer                 |
| `<S-h>`      | Normal | Previous buffer             |
| `<leader>bd` | Normal | Delete (close) buffer       |
| `<leader>bp` | Normal | Pick buffer (visual picker) |
| `<leader>bD` | Normal | Pick buffer to close        |
| `<leader>b[` | Normal | Move buffer left            |
| `<leader>b]` | Normal | Move buffer right           |

---

## 🔍 Search & Motion

| Key         | Mode             | Description                  |
| ----------- | ---------------- | ---------------------------- |
| `<leader>/` | Normal           | Fuzzy find in current buffer |
| `s`         | Normal/Visual/Op | Flash jump (type 2 chars)    |
| `S`         | Normal/Visual/Op | Flash treesitter select      |
| `r`         | Operator         | Flash remote action          |
| `R`         | Operator/Visual  | Flash treesitter search      |
| `<C-s>`     | Command          | Toggle flash in search       |

---

## ✏️ Editing

| Key         | Mode          | Description                        |
| ----------- | ------------- | ---------------------------------- |
| `<A-j>`     | Normal/Visual | Move line/selection down           |
| `<A-k>`     | Normal/Visual | Move line/selection up             |
| `<`         | Visual        | Indent left (keep selection)       |
| `>`         | Visual        | Indent right (keep selection)      |
| `<leader>y` | Normal/Visual | Yank to system clipboard           |
| `<leader>Y` | Normal        | Yank line to system clipboard      |
| `<leader>p` | Visual        | Paste without overwriting register |
| `gcc`       | Normal        | Toggle line comment                |
| `gc`        | Visual        | Toggle comment on selection        |
| `gbc`       | Normal        | Toggle block comment               |

---

## 📁 File Explorer

| Key          | Mode      | Description                     |
| ------------ | --------- | ------------------------------- |
| `<leader>e`  | Normal    | Toggle file explorer            |
| `<leader>fe` | Normal    | Focus file explorer             |
| `<leader>fE` | Normal    | Reveal current file in explorer |
| `?`          | (in tree) | Show nvim-tree help             |

### Inside nvim-tree

| Key           | Description               |
| ------------- | ------------------------- |
| `Enter` / `o` | Open file / expand folder |
| `v`           | Open in vertical split    |
| `s`           | Open in horizontal split  |
| `t`           | Open in new tab           |
| `a`           | Create new file/directory |
| `d`           | Delete file               |
| `r`           | Rename file               |
| `x`           | Cut file                  |
| `c`           | Copy file                 |
| `p`           | Paste file                |
| `R`           | Refresh tree              |
| `H`           | Toggle hidden files       |
| `q`           | Close tree                |

---

## 🔭 Telescope (Fuzzy Finder)

| Key          | Mode   | Description             |
| ------------ | ------ | ----------------------- |
| `<leader>ff` | Normal | Find files              |
| `<leader>fg` | Normal | Live grep (search text) |
| `<leader>fb` | Normal | Browse open buffers     |
| `<leader>fr` | Normal | Recent files            |
| `<leader>fh` | Normal | Help tags               |
| `<leader>fk` | Normal | Browse keymaps          |
| `<leader>fc` | Normal | Command history         |
| `<leader>fs` | Normal | Grep word under cursor  |
| `<leader>ft` | Normal | Treesitter symbols      |
| `<leader>fd` | Normal | All diagnostics         |

### Inside Telescope

| Key               | Description              |
| ----------------- | ------------------------ |
| `<C-j>` / `<C-k>` | Move selection down/up   |
| `<C-q>`           | Send results to quickfix |
| `<Esc>`           | Close telescope          |
| `<CR>`            | Open selection           |
| `<C-v>`           | Open in vertical split   |
| `<C-x>`           | Open in horizontal split |
| `<C-t>`           | Open in new tab          |

---

## 🧠 LSP — Code Intelligence

> These keymaps are active when an LSP server is attached to the buffer.

| Key          | Mode   | Description                    |
| ------------ | ------ | ------------------------------ |
| `gd`         | Normal | Go to definition               |
| `gD`         | Normal | Go to declaration              |
| `gr`         | Normal | Find references (Telescope)    |
| `gi`         | Normal | Go to implementation           |
| `gt`         | Normal | Go to type definition          |
| `K`          | Normal | Hover documentation            |
| `<C-k>`      | Normal | Signature help                 |
| `<leader>lr` | Normal | Rename symbol                  |
| `<leader>la` | Normal | Code action                    |
| `<leader>lf` | Normal | Format buffer                  |
| `<leader>ld` | Normal | Show diagnostic float          |
| `<leader>lD` | Normal | All diagnostics (Telescope)    |
| `<leader>ls` | Normal | Document symbols (Telescope)   |
| `<leader>lS` | Normal | Workspace symbols (Telescope)  |
| `<leader>li` | Normal | LSP info                       |
| `<leader>lm` | Normal | Open Mason installer           |
| `<leader>lo` | Normal | Toggle symbol outline (Aerial) |

---

## 🎨 Formatting & Linting

| Key          | Mode          | Description                     |
| ------------ | ------------- | ------------------------------- |
| `<leader>lf` | Normal/Visual | Format buffer (conform.nvim)    |
| `<leader>ll` | Normal        | Run linter manually (nvim-lint) |

> Format-on-save is enabled automatically for all languages.

---

## 🔴 Diagnostics & Trouble

| Key          | Mode   | Description            |
| ------------ | ------ | ---------------------- |
| `<leader>xx` | Normal | Toggle Trouble panel   |
| `<leader>xw` | Normal | Workspace diagnostics  |
| `<leader>xd` | Normal | Document diagnostics   |
| `<leader>xl` | Normal | Location list          |
| `<leader>xq` | Normal | Quickfix list          |
| `<leader>xt` | Normal | TODO list in Trouble   |
| `<leader>ft` | Normal | Find TODOs (Telescope) |
| `<leader>qo` | Normal | Open quickfix list     |
| `<leader>qc` | Normal | Close quickfix list    |

---

## 🐛 Debug (DAP)

| Key          | Mode   | Description                |
| ------------ | ------ | -------------------------- |
| `<leader>dc` | Normal | Continue / Start debugging |
| `<leader>db` | Normal | Toggle breakpoint          |
| `<leader>dB` | Normal | Set conditional breakpoint |
| `<leader>dl` | Normal | Set log point              |
| `<leader>di` | Normal | Step into                  |
| `<leader>do` | Normal | Step over                  |
| `<leader>dO` | Normal | Step out                   |
| `<leader>dr` | Normal | Toggle REPL                |
| `<leader>dL` | Normal | Run last debug config      |
| `<leader>du` | Normal | Toggle DAP UI              |
| `<leader>dx` | Normal | Terminate debug session    |
| `<leader>dh` | Normal | Hover variable value       |
| `<leader>dp` | Normal | Preview variable           |

### DAP adapters by language

| Language   | Adapter              | Notes                |
| ---------- | -------------------- | -------------------- |
| Rust       | `codelldb`           | via Mason            |
| Java       | `java-debug-adapter` | via jdtls bundles    |
| PHP        | `php-debug-adapter`  | XDebug on port 9003  |
| Python     | `debugpy`            | auto-detects venv    |
| JS/TS/Node | `js-debug-adapter`   | also supports Chrome |

---

## 🌿 Git

| Key          | Mode   | Description               |
| ------------ | ------ | ------------------------- |
| `<leader>gg` | Normal | Git status (fugitive)     |
| `<leader>gc` | Normal | Git commit                |
| `<leader>gP` | Normal | Git push                  |
| `<leader>gF` | Normal | Git pull                  |
| `<leader>gl` | Normal | Git log                   |
| `<leader>gs` | Normal | Stage hunk                |
| `<leader>gs` | Visual | Stage selected hunk       |
| `<leader>gr` | Normal | Reset hunk                |
| `<leader>gS` | Normal | Stage entire buffer       |
| `<leader>gu` | Normal | Undo stage hunk           |
| `<leader>gR` | Normal | Reset entire buffer       |
| `<leader>gp` | Normal | Preview hunk              |
| `<leader>gb` | Normal | Blame current line (full) |
| `<leader>gd` | Normal | Diff this file            |
| `<leader>gD` | Normal | Diff against last commit  |

---

## 💾 Sessions

| Key          | Mode   | Description     |
| ------------ | ------ | --------------- |
| `<leader>ss` | Normal | Save session    |
| `<leader>sr` | Normal | Restore session |
| `<leader>sd` | Normal | Delete session  |

---

## 🎛️ UI & Utilities

| Key          | Mode   | Description              |
| ------------ | ------ | ------------------------ |
| `<leader>lz` | Normal | Open Lazy plugin manager |
| `<leader>nd` | Normal | Dismiss notifications    |
| `<leader>mp` | Normal | Toggle Markdown preview  |
| `<leader>st` | Normal | Startup time profiler    |

---

## 🦀 Language: Rust

> Active in `.rs` files and `Cargo.toml`

| Key          | Mode   | Description                     |
| ------------ | ------ | ------------------------------- |
| `<leader>rr` | Normal | Runnables (cargo run targets)   |
| `<leader>rd` | Normal | Debuggables                     |
| `<leader>rt` | Normal | Testables                       |
| `<leader>re` | Normal | Expand macro inline             |
| `<leader>rc` | Normal | Open Cargo.toml                 |
| `<leader>rp` | Normal | Go to parent module             |
| `<leader>rj` | Normal | Move item down                  |
| `<leader>rk` | Normal | Move item up                    |
| `<leader>rh` | Normal | Hover actions (Rust-specific)   |
| `<leader>ra` | Normal | Code action (Rust-specific)     |
| `K`          | Normal | Hover docs / Rust hover actions |

### Cargo.toml (crates.nvim)

| Key          | Description                   |
| ------------ | ----------------------------- |
| `<leader>ct` | Toggle crate info inline      |
| `<leader>cr` | Reload crates                 |
| `<leader>cv` | Show available versions popup |
| `<leader>cf` | Show crate features popup     |
| `<leader>cd` | Show crate dependencies popup |
| `<leader>cu` | Upgrade crate under cursor    |
| `<leader>cU` | Upgrade all crates            |

---

## ☕ Language: Java

> Active in `.java` files

| Key          | Mode   | Description             |
| ------------ | ------ | ----------------------- |
| `<leader>jo` | Normal | Organize imports        |
| `<leader>jv` | Normal | Extract variable        |
| `<leader>jc` | Normal | Extract constant        |
| `<leader>jm` | Visual | Extract method          |
| `<leader>jt` | Normal | Run nearest test method |
| `<leader>jT` | Normal | Run all tests in class  |
| `<leader>ju` | Normal | Update jdtls config     |

> Java DAP is configured automatically through jdtls bundles (`java-debug-adapter` + `java-test`).

---

## 🐍 Language: Python

> Active in `.py` files

| Key          | Mode   | Description                       |
| ------------ | ------ | --------------------------------- |
| `<leader>pv` | Normal | Select virtual environment        |
| `<leader>pc` | Normal | Select cached venv                |
| `<leader>pd` | Normal | Generate docstring (Google style) |
| `<leader>pf` | Normal | Generate function docstring       |
| `<leader>pF` | Normal | Generate file docstring           |
| `<leader>pc` | Normal | Generate class docstring          |

### Jupyter-style cells (IPython)

| Key          | Description                          |
| ------------ | ------------------------------------ |
| `<leader>pc` | Execute current cell (`# %%` blocks) |
| `<leader>pC` | Execute cell and jump to next        |
| `<leader>pr` | Run entire file                      |
| `<leader>pt` | Run file and show timing             |

---

## 🌐 Language: Web (JS/TS/Node/HTML)

> Active in `.js`, `.ts`, `.jsx`, `.tsx` files

| Key          | Mode   | Description                           |
| ------------ | ------ | ------------------------------------- |
| `<leader>ti` | Normal | Add missing imports (TypeScript)      |
| `<leader>to` | Normal | Organize imports                      |
| `<leader>tu` | Normal | Remove unused imports                 |
| `<leader>tf` | Normal | Fix all TS errors                     |
| `<leader>tR` | Normal | Rename file (updates all imports)     |
| `<leader>tr` | Normal | File references                       |
| `<leader>ts` | Normal | Sort imports                          |
| `gd`         | Normal | Go to source definition (not `.d.ts`) |

### package.json (package-info)

| Key          | Description                        |
| ------------ | ---------------------------------- |
| `<leader>np` | Toggle package version info inline |
| `<leader>ni` | Install new package                |
| `<leader>nu` | Update package under cursor        |
| `<leader>nd` | Delete package under cursor        |
| `<leader>nc` | Change package version             |

---

## 🗄️ Language: SQL

> Active in `.sql` files

| Key           | Mode   | Description               |
| ------------- | ------ | ------------------------- |
| `<leader>dbt` | Normal | Toggle DB UI              |
| `<leader>dba` | Normal | Add new DB connection     |
| `<leader>dbf` | Normal | Find associated DB buffer |
| `<leader>dbr` | Normal | Rename DB buffer          |

### Inside DB UI

| Key     | Description                   |
| ------- | ----------------------------- |
| `Enter` | Expand connection / run query |
| `o`     | Open table                    |
| `R`     | Refresh                       |
| `d`     | Delete connection             |
| `A`     | Add connection                |
| `<C-s>` | Execute query (in SQL buffer) |

---

## 🔨 Language: Makefile

> Active in `Makefile`, `*.mk` files

| Key          | Mode   | Description                  |
| ------------ | ------ | ---------------------------- |
| `<leader>mm` | Normal | Run `make <target>` (prompt) |
| `<leader>mb` | Normal | `make build`                 |
| `<leader>mc` | Normal | `make clean`                 |
| `<leader>mt` | Normal | `make test`                  |
| `<leader>mr` | Normal | `make run`                   |
| `<leader>mi` | Normal | `make install`               |
| `<leader>ms` | Normal | Stop running async job       |
| `<leader>mk` | Normal | Pick make target (Telescope) |

---

## 🌳 Treesitter Text Objects

> Work with `d`, `c`, `y`, `v` operators

| Key         | Mode      | Description                  |
| ----------- | --------- | ---------------------------- |
| `af`        | Visual/Op | Outer function               |
| `if`        | Visual/Op | Inner function               |
| `ac`        | Visual/Op | Outer class                  |
| `ic`        | Visual/Op | Inner class                  |
| `aa`        | Visual/Op | Outer parameter              |
| `ia`        | Visual/Op | Inner parameter              |
| `ab`        | Visual/Op | Outer block                  |
| `ib`        | Visual/Op | Inner block                  |
| `<leader>a` | Normal    | Swap parameter with next     |
| `<leader>A` | Normal    | Swap parameter with previous |

---

## 🔲 Surround

> `nvim-surround` — works with any text object

| Key     | Description                        |
| ------- | ---------------------------------- |
| `ysiw"` | Surround word with `"`             |
| `ysiw)` | Surround word with `()`            |
| `yss"`  | Surround line with `"`             |
| `ds"`   | Delete surrounding `"`             |
| `cs"'`  | Change surrounding `"` to `'`      |
| `S"`    | Surround visual selection with `"` |

---

## 💬 Comment

| Key   | Mode   | Description                       |
| ----- | ------ | --------------------------------- |
| `gcc` | Normal | Toggle line comment               |
| `gbc` | Normal | Toggle block comment              |
| `gc`  | Visual | Toggle comment on selection       |
| `gb`  | Visual | Toggle block comment on selection |
| `gcO` | Normal | Add comment above                 |
| `gco` | Normal | Add comment below                 |
| `gcA` | Normal | Add comment at end of line        |

---

## 🗂️ Leader Key Map

```
Space (leader)
├── b  →  Buffer management
├── c  →  Cargo / Crates (Rust)
├── d  →  Debug (DAP) + Database
│   └── db →  Database UI
├── e  →  File explorer
├── f  →  Find (Telescope) + File ops
├── g  →  Git
├── j  →  Java
├── l  →  LSP + lazy.nvim + Mason
├── m  →  Makefile
├── n  →  Notifications + npm
├── p  →  Python
├── q  →  Quickfix
├── r  →  Rust runnables
├── s  →  Splits + Sessions
├── t  →  TypeScript
├── w  →  Save
├── x  →  Trouble diagnostics
└── /  →  Fuzzy search in buffer
```

---

_Generated for Neovim IDE config — Stack: Java · Rust · PHP · Node · React · Python · SQL · Makefile_
