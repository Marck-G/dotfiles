-- ============================================================
--  plugins/treesitter.lua  ·  Syntax & code understanding
--
--  CRITICAL: Do NOT use `config = function()` with treesitter.
--  Use ONLY `main` + `opts` so lazy.nvim defers the require()
--  until after the plugin is on the runtimepath.
--
--  treesitter-context is a SEPARATE entry so it loads after
--  nvim-treesitter is fully initialized.
-- ============================================================

return {

  -- ── 1. nvim-treesitter (core) ─────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build        = ":TSUpdate",
    lazy         = false,
    main         = "nvim-treesitter.configs",   -- lazy calls require(main).setup(opts)
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "windwp/nvim-ts-autotag",
    },
    -- NO config function — opts is passed directly to main.setup()
    opts = {
      ensure_installed = {
        "java", "rust", "python",
        "javascript", "typescript", "tsx",
        "php", "lua", "sql", "make",
        "html", "css", "scss",
        "json", "jsonc", "yaml", "toml",
        "bash", "dockerfile",
        "vim", "vimdoc",
        "markdown", "markdown_inline", "xml",
        "regex", "comment", "diff",
        "gitcommit", "gitignore", "query",
      },

      auto_install = false,

      highlight = {
        enable  = true,
        disable = function(_, buf)
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          return ok and stats and stats.size > 512 * 1024
        end,
        additional_vim_regex_highlighting = false,
      },

      indent = { enable = true },

      textobjects = {
        select = {
          enable    = true,
          lookahead = true,
          keymaps   = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            ["ab"] = "@block.outer",
            ["ib"] = "@block.inner",
          },
        },
        move = {
          enable    = true,
          set_jumps = true,
          goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end       = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
        swap = {
          enable        = true,
          swap_next     = { ["<leader>a"] = "@parameter.inner" },
          swap_previous = { ["<leader>A"] = "@parameter.inner" },
        },
      },

      autotag = { enable = true },
    },
  },

  -- ── 2. treesitter-context (separate entry) ────────────
  -- Loaded after nvim-treesitter via dependency, uses its own
  -- main + opts so it also never calls require() too early.
  {
    "nvim-treesitter/nvim-treesitter-context",
    lazy         = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    main         = "treesitter-context",
    opts = {
      enable            = true,
      max_lines         = 3,
      min_window_height = 20,
      trim_scope        = "outer",
      mode              = "cursor",
    },
  },
}