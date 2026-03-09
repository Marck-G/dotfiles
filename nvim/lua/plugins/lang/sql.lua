-- ============================================================
--  plugins/lang/sql.lua
--  LAZY TRIGGER: ft = "sql", "mysql", "plsql"  (*.sql files)
--  vim-dadbod  ·  database UI + query runner
-- ============================================================

return {

  -- ────────────────────────────────────────────────────────
  --  DADBOD  ·  database engine
  -- ────────────────────────────────────────────────────────
  {
    "tpope/vim-dadbod",
    ft  = { "sql", "mysql", "plsql" },  -- ← LAZY
    cmd = { "DB", "DBUI" },
  },

  -- ────────────────────────────────────────────────────────
  --  DADBOD UI  ·  visual explorer (like TablePlus in nvim)
  -- ────────────────────────────────────────────────────────
  {
    "kristijanhusak/vim-dadbod-ui",
    ft           = { "sql", "mysql", "plsql" },   -- ← LAZY
    cmd          = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = {
      "tpope/vim-dadbod",
      "kristijanhusak/vim-dadbod-completion",
    },
    init         = function()
      -- UI settings (set before plugin loads)
      vim.g.db_ui_use_nerd_fonts         = 1
      vim.g.db_ui_show_database_icon     = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_win_position           = "left"
      vim.g.db_ui_winwidth               = 40
      -- Auto-execute selected lines with <leader>S in SQL buffers
      vim.g.db_ui_execute_on_save        = 0
      -- Save connections in standard location
      vim.g.db_ui_save_location          = vim.fn.stdpath("data") .. "/db_ui"
      -- Connections can be defined in env or in the UI
      -- Example: vim.g.dbs = { { name = "dev", url = "postgres://..." } }
    end,
    keys = {
      { "<leader>dbt",  "<cmd>DBUIToggle<CR>",         desc = "Toggle DB UI" },
      { "<leader>dba",  "<cmd>DBUIAddConnection<CR>",  desc = "Add DB connection" },
      { "<leader>dbf",  "<cmd>DBUIFindBuffer<CR>",     desc = "Find DB buffer" },
      { "<leader>dbr",  "<cmd>DBUIRenameBuffer<CR>",   desc = "Rename DB buffer" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  DADBOD COMPLETION  ·  SQL autocomplete (tables, cols)
  -- ────────────────────────────────────────────────────────
  {
    "kristijanhusak/vim-dadbod-completion",
    ft   = { "sql", "mysql", "plsql" },  -- ← LAZY
    config = function()
      -- Register dadbod as a cmp source for SQL filetypes
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = { "sql", "mysql", "plsql" },
        callback = function()
          require("cmp").setup.buffer({
            sources = {
              { name = "vim-dadbod-completion", priority = 1000 },
              { name = "buffer",                priority = 500 },
              { name = "nvim_lsp",              priority = 750 },
            },
          })
        end,
      })
    end,
  },
}
