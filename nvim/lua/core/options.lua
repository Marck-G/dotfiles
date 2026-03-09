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