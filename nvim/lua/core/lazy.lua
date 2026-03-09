-- ============================================================
--  core/lazy.lua  ·  Bootstrap lazy.nvim + load all specs
-- ============================================================

-- ── Bootstrap: auto-install lazy.nvim if missing ──────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.notify("Installing lazy.nvim...", vim.log.levels.INFO)
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Merge all plugin spec tables into one flat list ───────
local function load(module)
  return require(module)
end

local specs = {}
-- Core plugins (always loaded)
vim.list_extend(specs, load("plugins.ui"))
vim.list_extend(specs, load("plugins.treesitter"))
vim.list_extend(specs, load("plugins.lsp"))
vim.list_extend(specs, load("plugins.tools"))
-- Language plugins (lazy by filetype)
vim.list_extend(specs, load("plugins.lang.java"))
vim.list_extend(specs, load("plugins.lang.rust"))
vim.list_extend(specs, load("plugins.lang.webdev"))
vim.list_extend(specs, load("plugins.lang.python"))
vim.list_extend(specs, load("plugins.lang.sql"))
vim.list_extend(specs, load("plugins.lang.makefile"))
vim.list_extend(specs, load("plugins.lang.php"))

-- ── Load lazy.nvim with all plugin specs ──────────────────
require("lazy").setup(specs, {
  -- ── lazy.nvim options ───────────────────────────────────
  defaults = {
    lazy    = false,   -- plugins load on startup unless they define event/ft/cmd/keys
    version = false,   -- always use latest commit (use "*" for releases only)
  },

  install = {
    colorscheme = { "catppuccin", "habamax" },  -- fallback colorscheme during install
  },

  checker = {
    enabled = true,    -- auto-check for plugin updates
    notify  = false,   -- don't notify on startup, check with :Lazy
    frequency = 3600,  -- check every hour
  },

  change_detection = {
    enabled = true,    -- auto-reload config when changed
    notify  = false,
  },

  performance = {
    rtp = {
      -- Disable built-in plugins we don't need (speeds up startup)
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },

  ui = {
    border = "rounded",
    icons  = {
      cmd     = " ",
      config  = "",
      event   = "",
      ft      = " ",
      init    = " ",
      keys    = " ",
      plugin  = " ",
      runtime = " ",
      source  = " ",
      start   = "",
      task    = "✔ ",
      lazy    = "󰒲 ",
    },
  },
})

-- ── Open lazy UI with <leader>lz ──────────────────────────
vim.keymap.set("n", "<leader>lz", "<cmd>Lazy<cr>", { desc = "Lazy plugin manager" })