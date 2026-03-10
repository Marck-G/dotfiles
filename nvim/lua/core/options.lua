-- ============================================================
--  core/options.lua  ·  Vim options (no plugins needed)
-- ============================================================

local opt = vim.opt

-- ── Editor ────────────────────────────────────────────────
opt.number         = true           -- line numbers
opt.relativenumber = true           -- relative line numbers (great for motions)
opt.cursorline     = true           -- highlight current line
opt.signcolumn     = "yes"          -- always show sign column (no layout shifts)
opt.scrolloff      = 8              -- keep 8 lines above/below cursor
opt.sidescrolloff  = 8
opt.wrap           = false          -- no line wrapping
opt.colorcolumn    = "100"          -- ruler at 100 chars

-- ── Indentation ───────────────────────────────────────────
opt.tabstop        = 2              -- 2-space tabs (overridden per language)
opt.shiftwidth     = 2
opt.softtabstop    = 2
opt.expandtab      = true           -- spaces instead of tabs
opt.smartindent    = true
opt.autoindent     = true

-- ── Search ────────────────────────────────────────────────
opt.ignorecase     = true           -- case-insensitive search ...
opt.smartcase      = true           -- ... unless uppercase used
opt.hlsearch       = true
opt.incsearch      = true

-- ── Files ─────────────────────────────────────────────────
opt.encoding       = "utf-8"
opt.fileencoding   = "utf-8"
opt.backup         = false
opt.swapfile       = false
opt.undofile       = true           -- persistent undo across sessions
opt.undodir        = vim.fn.stdpath("data") .. "/undo"

-- ── UI ────────────────────────────────────────────────────
opt.termguicolors  = true           -- 24-bit color
opt.showmode       = false          -- lualine shows mode instead
opt.laststatus     = 3              -- global statusline
opt.pumheight      = 12             -- max items in completion popup
opt.pumblend       = 10             -- completion popup transparency
opt.winblend       = 10             -- floating window transparency
opt.splitbelow     = true           -- horizontal splits go below
opt.splitright     = true           -- vertical splits go right
opt.conceallevel   = 0              -- show all characters in markdown

-- ── Performance ───────────────────────────────────────────
opt.updatetime     = 200            -- faster CursorHold (gitsigns, illuminate)
opt.timeoutlen     = 300            -- faster which-key popup
opt.redrawtime     = 1500
opt.lazyredraw     = false          -- must be false for noice.nvim


-- ── Clipboard ─────────────────────────────────────────────
-- Detect the best available clipboard provider and configure accordingly.
-- Priority: tmux → wayland (wl-copy) → X11 (xclip/xsel) → macOS (pbcopy) → WSL
local function setup_clipboard()
  -- tmux: works inside any terminal multiplexer session
  if vim.env.TMUX ~= nil then
    vim.g.clipboard = {
      name = "tmux",
      copy  = { ["+"] = { "tmux", "load-buffer", "-" },
                ["*"] = { "tmux", "load-buffer", "-" } },
      paste = { ["+"] = { "tmux", "save-buffer", "-" },
                ["*"] = { "tmux", "save-buffer", "-" } },
      cache_enabled = 0,
    }
    return
  end

  -- Wayland
  if vim.env.WAYLAND_DISPLAY ~= nil then
    if vim.fn.executable("wl-copy") == 1 then
      vim.g.clipboard = {
        name  = "wl-clipboard",
        copy  = { ["+"] = { "wl-copy" },          ["*"] = { "wl-copy", "--primary" } },
        paste = { ["+"] = { "wl-paste", "--no-newline" },
                  ["*"] = { "wl-paste", "--no-newline", "--primary" } },
        cache_enabled = 0,
      }
      return
    end
  end

  -- X11 — prefer xclip, fall back to xsel
  if vim.env.DISPLAY ~= nil then
    if vim.fn.executable("xclip") == 1 then
      vim.g.clipboard = {
        name  = "xclip",
        copy  = { ["+"] = { "xclip", "-selection", "clipboard" },
                  ["*"] = { "xclip", "-selection", "primary"   } },
        paste = { ["+"] = { "xclip", "-selection", "clipboard", "-o" },
                  ["*"] = { "xclip", "-selection", "primary",   "-o" } },
        cache_enabled = 0,
      }
      return
    end
    if vim.fn.executable("xsel") == 1 then
      vim.g.clipboard = {
        name  = "xsel",
        copy  = { ["+"] = { "xsel", "--clipboard", "--input" },
                  ["*"] = { "xsel", "--primary",   "--input" } },
        paste = { ["+"] = { "xsel", "--clipboard", "--output" },
                  ["*"] = { "xsel", "--primary",   "--output" } },
        cache_enabled = 0,
      }
      return
    end
  end

  -- macOS
  if vim.fn.has("mac") == 1 then
    -- pbcopy/pbpaste are always available on macOS, nothing to do —
    -- Neovim detects them automatically via unnamedplus.
    return
  end

  -- WSL (Windows Subsystem for Linux)
  if vim.fn.has("wsl") == 1 then
    vim.g.clipboard = {
      name  = "win32yank-wsl",
      copy  = { ["+"] = { "win32yank.exe", "-i", "--crlf" },
                ["*"] = { "win32yank.exe", "-i", "--crlf" } },
      paste = { ["+"] = { "win32yank.exe", "-o", "--lf"   },
                ["*"] = { "win32yank.exe", "-o", "--lf"   } },
      cache_enabled = 0,
    }
    return
  end
end

setup_clipboard()

-- ── Clipboard ─────────────────────────────────────────────
opt.clipboard      = "unnamedplus"  -- sync with system clipboard

-- ── Completion ────────────────────────────────────────────
opt.completeopt    = { "menu", "menuone", "noselect" }

-- ── Folds (using treesitter) ──────────────────────────────
opt.foldmethod     = "expr"
opt.foldexpr       = "nvim_treesitter#foldexpr()"
opt.foldlevel      = 99             -- open all folds by default

-- ── Mouse ─────────────────────────────────────────────────
opt.mouse          = "a"            -- enable mouse in all modes

-- ── Diagnostics ───────────────────────────────────────────
vim.diagnostic.config({
  virtual_text    = { prefix = "●" },
  signs           = true,
  underline       = true,
  update_in_insert = false,
  severity_sort   = true,
  float = {
    focusable = false,
    style     = "minimal",
    border    = "rounded",
    source    = "always",
    header    = "",
    prefix    = "",
  },
})

-- ── Diagnostic signs ──────────────────────────────────────
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end