local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- usar versión estable
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Configurar plugins
require("lazy").setup({
  -- Aquí irán vuestros plugins, por ejemplo:
  "folke/tokyonight.nvim", -- Un tema de colores
  "nvim-lualine/lualine.nvim", -- Barra de estado
  
  -- Herramientas base de LSP
{
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim", -- Auto-instala lo que falte
    },
    config = function()
      require("mason").setup()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "bash-language-server", -- Bash LSP
          "shfmt",                -- Bash Formatter
          "shellcheck",           -- Bash Linter
          "pyright",              -- Python LSP
          "black",                -- Python Formatter
          "isort",                -- Python Import Sorter
          -- Nota: Rust se gestiona aparte con rustaceanvim, no poner aquí
        },
      })
    end
},
-- Rust LSP
{
  'mrcjkb/rustaceanvim',
  version = '^4', -- Recomendado anclar versión
  ft = { 'rust' }, -- Lazy load: solo se carga al abrir un .rs
},
{
  "linux-cultist/venv-selector.nvim",
  dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
  config = true,
  event = "VeryLazy", -- Cargar bajo demanda
},
{
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    format_on_save = { timeout_ms = 500, lsp_fallback = true },
    formatters_by_ft = {
      python = { "isort", "black" },
      sh = { "shfmt" },
      -- Rust usa su propio lsp para formatear, no hace falta ponerlo aquí
    },
  },
},
{
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function () 
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "python", "bash" },
        auto_install = true,
        highlight = { enable = true },
      })
    end
},
{
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- Optional: for file icons
  },
  config = function()
    require("nvim-tree").setup({
      -- Customize the setup as needed
      view = {
        width = 30, -- Set the width of the file tree
      },
      renderer = {
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
          },
        },
      },
    })
  end,
},
{
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end,
}
})

-- Remapping for toogle
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>s", ":w<CR>", { desc = "Save" })
vim.opt.number	= true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4     -- Number of spaces for each indentation level
vim.opt.softtabstop = 4    -- Number of spaces inserted when tab is pressed
vim.keymap.set("n", "<leader>i", vim.diagnostic.open_float, { desc = "Show LSP diagnostics" })   
