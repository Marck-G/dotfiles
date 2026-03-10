-- ============================================================
--  core/autocmds.lua  ·  Autocommands
-- ============================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ── Highlight on yank ─────────────────────────────────────
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group    = "YankHighlight",
  callback = function() vim.hl.on_yank({ higroup = "Visual", timeout = 200 }) end,
})

-- ── Remove trailing whitespace on save ────────────────────
augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
  group   = "TrimWhitespace",
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- ── Restore cursor position ───────────────────────────────
augroup("RestoreCursor", { clear = true })
autocmd("BufReadPost", {
  group    = "RestoreCursor",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ── Auto-resize splits on window resize ───────────────────
augroup("AutoResize", { clear = true })
autocmd("VimResized", {
  group    = "AutoResize",
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- ── Close certain filetypes with just 'q' ─────────────────
augroup("CloseWithQ", { clear = true })
autocmd("FileType", {
  group   = "CloseWithQ",
  pattern = { "help", "lspinfo", "man", "notify", "qf", "startuptime",
              "checkhealth", "fugitive", "git", "spectre_panel" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- ── Per-language indent settings ──────────────────────────
augroup("LangIndent", { clear = true })

-- Java: 4 spaces
autocmd("FileType", {
  group   = "LangIndent",
  pattern = "java",
  callback = function()
    vim.opt_local.tabstop    = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Python: 4 spaces (PEP8)
autocmd("FileType", {
  group   = "LangIndent",
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop    = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.colorcolumn = "88"  -- black formatter default
  end,
})

-- Rust: 4 spaces
autocmd("FileType", {
  group   = "LangIndent",
  pattern = "rust",
  callback = function()
    vim.opt_local.tabstop    = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.colorcolumn = "100"
  end,
})

-- Makefile: MUST use real tabs
autocmd("FileType", {
  group   = "LangIndent",
  pattern = { "make", "makefile" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop   = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- JS/TS/JSX/TSX/JSON: 2 spaces
autocmd("FileType", {
  group   = "LangIndent",
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact",
              "json", "jsonc", "html", "css", "scss" },
  callback = function()
    vim.opt_local.tabstop    = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- SQL: 2 spaces
autocmd("FileType", {
  group   = "LangIndent",
  pattern = "sql",
  callback = function()
    vim.opt_local.tabstop    = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- ── Format on save (LSP) ──────────────────────────────────
-- NOTE: Languages that have dedicated formatters will override this
augroup("LspFormatOnSave", { clear = true })
autocmd("BufWritePre", {
  group    = "LspFormatOnSave",
  pattern  = { "*.rs", "*.go" },  -- Rust/Go: LSP format is the standard
  callback = function()
    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
  end,
})

-- ── Detect Makefile variants ──────────────────────────────
augroup("MakefileDetect", { clear = true })
autocmd({ "BufRead", "BufNewFile" }, {
  group   = "MakefileDetect",
  pattern = { "Makefile", "makefile", "GNUmakefile", "*.mk", "*.mak" },
  command = "set filetype=make",
})