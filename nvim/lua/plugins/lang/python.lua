-- ============================================================
--  plugins/lang/python.lua
--  LAZY TRIGGER: ft = "python"  (*.py files)
--  Virtual env selector · DAP · Jupyter-style cells
-- ============================================================

return {

  -- ────────────────────────────────────────────────────────
  --  VENV SELECTOR  ·  switch virtual envs (critical for
  --  pytorch / tensorflow / multiple projects)
  -- ────────────────────────────────────────────────────────
  {
    "linux-cultist/venv-selector.nvim",
    ft           = { "python" },   -- ← LAZY
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    config       = function()
      require("venv-selector").setup({
        -- Search paths for virtual environments
        search_venv_managers = true,   -- detect conda, pyenv, poetry, pipenv
        search_workspace     = true,   -- search in current project
        parents              = 2,      -- levels up to search for .venv
        name                 = { "venv", ".venv", "env", ".env" },
        -- Automatically activate when .venv found in project
        auto_refresh         = false,
        -- Notify which venv was activated
        notify_user_on_activate = true,
        -- Update DAP python path on venv change
        dap_enabled          = true,
      })
    end,
    keys = {
      { "<leader>pv",  "<cmd>VenvSelect<CR>",        ft = "python", desc = "Select venv" },
      { "<leader>pc",  "<cmd>VenvSelectCached<CR>",  ft = "python", desc = "Select cached venv" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  PYTHON EXTRAS  ·  useful for data science / ML
  -- ────────────────────────────────────────────────────────

  -- Jupyter-style code cells (run blocks with Alt+Enter like VS Code)
  {
    "hanschen/vim-ipython-cell",
    ft  = { "python" },            -- ← LAZY
    cmd = {
      "IPythonCellExecuteCell", "IPythonCellExecuteCellJump",
      "IPythonCellRun", "IPythonCellRunTime",
    },
    config = function()
      vim.g.ipython_cell_delimit_cells_by = "tags"  -- use # %% markers
      vim.g.ipython_cell_tag              = "# %%"
    end,
    keys = {
      { "<leader>pc", "<cmd>IPythonCellExecuteCell<CR>",     ft = "python", desc = "Execute cell" },
      { "<leader>pC", "<cmd>IPythonCellExecuteCellJump<CR>", ft = "python", desc = "Execute cell & jump" },
      { "<leader>pr", "<cmd>IPythonCellRun<CR>",             ft = "python", desc = "Run file" },
      { "<leader>pt", "<cmd>IPythonCellRunTime<CR>",         ft = "python", desc = "Run & time" },
    },
  },

  -- Python docstring generator (Google / NumPy / Sphinx style)
  {
    "danymat/neogen",
    ft           = { "python", "java", "rust", "javascript", "typescript",
                     "javascriptreact", "typescriptreact", "lua" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config       = function()
      require("neogen").setup({
        enabled  = true,
        snippet_engine = "luasnip",
        languages = {
          python = { template = { annotation_convention = "google" } },
          java   = { template = { annotation_convention = "javadoc" } },
          rust   = { template = { annotation_convention = "rustdoc" } },
        },
      })
    end,
    keys = {
      { "<leader>pd", function() require("neogen").generate() end,                           desc = "Generate docstring" },
      { "<leader>pf", function() require("neogen").generate({ type = "func" }) end,          desc = "Generate func doc" },
      { "<leader>pF", function() require("neogen").generate({ type = "file" }) end,          desc = "Generate file doc" },
      { "<leader>pc", function() require("neogen").generate({ type = "class" }) end,         desc = "Generate class doc" },
    },
  },
}
