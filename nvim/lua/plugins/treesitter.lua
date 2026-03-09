-- ============================================================
--  plugins/treesitter.lua  ·  Syntax & code understanding
--  Loads at startup — treesitter is the foundation for LSP,
--  folding, indent, and most other plugins.
-- ============================================================

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build  = ":TSUpdate",
    event  = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",  -- select/move by function/class
      "nvim-treesitter/nvim-treesitter-context",      -- sticky context header
      "windwp/nvim-ts-autotag",                       -- auto-close JSX tags
    },
    config = function()
      require("nvim-treesitter.configs").setup({

        -- Install ALL grammars for our stack (+ extras that are useful)
        ensure_installed = {
          -- Languages
          "java", "rust", "python",
          "javascript", "typescript", "tsx", "jsx",
          "sql",
          "make",
          -- Web
          "html", "css", "scss", "json", "jsonc", "yaml", "toml",
          -- Infrastructure / config
          "dockerfile", "bash", "lua", "vim", "vimdoc",
          "markdown", "markdown_inline",
          -- Build / misc
          "xml", "regex", "comment",
        },

        auto_install  = true,   -- install missing grammars automatically
        highlight     = {
          enable  = true,
          additional_vim_regex_highlighting = false,
        },
        indent        = { enable = true },

        -- ── Text objects (select by function, class, etc.) ──
        textobjects = {
          select = {
            enable    = true,
            lookahead = true,  -- jump forward to the next text object
            keymaps   = {
              ["af"] = "@function.outer",  -- outer function
              ["if"] = "@function.inner",  -- inner function
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
            },
          },
          move = {
            enable              = true,
            set_jumps           = true,
            goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
            goto_next_end       = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
            goto_previous_end   = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
          },
          swap = {
            enable = true,
            swap_next     = { ["<leader>a"] = "@parameter.inner" },
            swap_previous = { ["<leader>A"] = "@parameter.inner" },
          },
        },

        -- ── Auto-tag (JSX/HTML) ─────────────────────────────
        autotag = { enable = true },

      })

      -- ── Treesitter context (sticky function header) ──────
      require("treesitter-context").setup({
        enable          = true,
        max_lines       = 3,
        min_window_height = 20,
        trim_scope      = "outer",
        mode            = "cursor",
      })
    end,
  },
}