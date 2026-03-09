-- ============================================================
--  plugins/lang/php.lua
--  LAZY TRIGGER: ft = "php"  (*.php files)
--  intelephense LSP · php-debug-adapter · php-cs-fixer
-- ============================================================

return {

  -- ── Blade template support (Laravel) ──────────────────
  {
    "jwalton512/vim-blade",
    ft = { "blade", "php" },
  },

  -- ── PHP refactoring tools ─────────────────────────────
  {
    "gbprod/php-enhanced-treesitter.nvim",
    ft           = { "php" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config       = function()
      require("php-enhanced-treesitter").setup()
    end,
  },
}
