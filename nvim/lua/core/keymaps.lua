-- ============================================================
--  core/keymaps.lua  ·  Base keymaps (plugin-free)
--  NOTE: Plugin keymaps live in each plugin spec (keys = {})
-- ============================================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ── Leader ────────────────────────────────────────────────
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- ── Better Escape ─────────────────────────────────────────
map("i", "jk", "<ESC>",     opts)
map("i", "kj", "<ESC>",     opts)

-- ── Window Navigation ─────────────────────────────────────
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- ── Window Resize ─────────────────────────────────────────
map("n", "<C-Up>",    ":resize -2<CR>",          opts)
map("n", "<C-Down>",  ":resize +2<CR>",          opts)
map("n", "<C-Left>",  ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- ── Buffer Navigation ─────────────────────────────────────
map("n", "<S-l>", ":bnext<CR>",     opts)
map("n", "<S-h>", ":bprevious<CR>", opts)
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- ── Indentation (keep visual selection) ───────────────────
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- ── Move Lines ────────────────────────────────────────────
map("n", "<A-j>", ":m .+1<CR>==",       opts)
map("n", "<A-k>", ":m .-2<CR>==",       opts)
map("v", "<A-j>", ":m '>+1<CR>gv=gv",  opts)
map("v", "<A-k>", ":m '<-2<CR>gv=gv",  opts)

-- ── Search ────────────────────────────────────────────────
map("n", "<leader>nh", ":nohl<CR>",  { desc = "Clear search highlights" })
map("n", "n", "nzzzv", opts)   -- keep search result centered
map("n", "N", "Nzzzv", opts)

-- ── Clipboard ─────────────────────────────────────────────
map("x", "<leader>p", [["_dP]],  { desc = "Paste without losing register" })
map("n", "<leader>y", [["+y]],   { desc = "Yank to clipboard" })
map("v", "<leader>y", [["+y]],   { desc = "Yank to clipboard" })
map("n", "<leader>Y", [["+Y]],   { desc = "Yank line to clipboard" })

-- ── Quick Fix List ────────────────────────────────────────
map("n", "<leader>qo", ":copen<CR>",  { desc = "Open quickfix" })
map("n", "<leader>qc", ":cclose<CR>", { desc = "Close quickfix" })
map("n", "[q", ":cprev<CR>",          { desc = "Prev quickfix" })
map("n", "]q", ":cnext<CR>",          { desc = "Next quickfix" })

-- ── Splits ────────────────────────────────────────────────
map("n", "<leader>sv", "<C-w>v",     { desc = "Split vertical" })
map("n", "<leader>sh", "<C-w>s",     { desc = "Split horizontal" })
map("n", "<leader>se", "<C-w>=",     { desc = "Equal splits" })
map("n", "<leader>sx", ":close<CR>", { desc = "Close split" })

-- ── Misc ──────────────────────────────────────────────────
map("n", "<leader>w", ":w<CR>",    { desc = "Save file" })
map("n", "<leader>q", ":q<CR>",    { desc = "Quit" })
map("n", "<leader>Q", ":qa!<CR>",  { desc = "Force quit all" })
map("n", "Q", "<nop>", opts)       -- disable Ex mode