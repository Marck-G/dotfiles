-- ============================================================
--  plugins/lang/webdev.lua
--  LAZY TRIGGER: ft = js, ts, jsx, tsx, html, css, json
--  TypeScript Tools · TSX autotag · Template strings
-- ============================================================

local WEB_FT = {
  "javascript", "javascriptreact",
  "typescript", "typescriptreact",
}

return {

  -- ────────────────────────────────────────────────────────
  --  TYPESCRIPT TOOLS  ·  faster tsserver integration
  --  (replaces ts_ls for .ts / .tsx files)
  -- ────────────────────────────────────────────────────────
  {
    "pmizio/typescript-tools.nvim",
    ft           = WEB_FT,         -- ← LAZY
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    config       = function()
      require("typescript-tools").setup({
        settings = {
          -- Spawn separate tsserver for each project
          separate_diagnostic_server = true,
          publish_diagnostic_on      = "insert_leave",
          expose_as_code_action      = { "fix_all", "add_missing_imports", "remove_unused" },
          tsserver_file_preferences  = {
            includeInlayParameterNameHints     = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints          = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            importModuleSpecifierPreference  = "non-relative",
          },
        },
        on_attach = function(client, bufnr)
          local map = function(k, f, desc)
            vim.keymap.set("n", k, f, { buffer = bufnr, desc = desc })
          end

          -- TypeScript specific actions
          map("<leader>ti", "<cmd>TSToolsAddMissingImports<CR>",     "Add missing imports")
          map("<leader>to", "<cmd>TSToolsOrganizeImports<CR>",       "Organize imports")
          map("<leader>tu", "<cmd>TSToolsRemoveUnused<CR>",          "Remove unused")
          map("<leader>tf", "<cmd>TSToolsFixAll<CR>",                "Fix all")
          map("<leader>tR", "<cmd>TSToolsRenameFile<CR>",            "Rename file (update imports)")
          map("<leader>tr", "<cmd>TSToolsFileReferences<CR>",        "File references")
          map("<leader>ts", "<cmd>TSToolsSortImports<CR>",           "Sort imports")
          map("gd",         "<cmd>TSToolsGoToSourceDefinition<CR>",  "Go to source definition")
        end,
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  AUTO-TAG  ·  auto-close / rename JSX & HTML tags
  -- ────────────────────────────────────────────────────────
  {
    "windwp/nvim-ts-autotag",
    ft     = { "html", "xml", "javascript", "javascriptreact",
               "typescript", "typescriptreact", "svelte", "vue" },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close         = true,   -- auto-close tags
          enable_rename        = true,   -- auto-rename matching tag
          enable_close_on_slash = false,
        },
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  TEMPLATE STRINGS  ·  auto-convert '' to `` when needed
  -- ────────────────────────────────────────────────────────
  {
    "axelvc/template-string.nvim",
    ft     = WEB_FT,
    config = function()
      require("template-string").setup({
        filetypes              = WEB_FT,
        jsx_brackets           = true,
        remove_template_string = true,  -- revert to '' when $ is removed
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  PACKAGE.JSON  ·  npm package info inline
  -- ────────────────────────────────────────────────────────
  {
    "vuki656/package-info.nvim",
    ft           = "json",           -- ← LAZY: package.json
    dependencies = { "MunifTanjim/nui.nvim" },
    config       = function()
      require("package-info").setup({
        colors = {
          up_to_date = "#3C4048",
          outdated   = "#d19a66",
        },
        icons = {
          enable   = true,
          style    = { up_to_date = "|  ", outdated = "|  " },
        },
        autostart            = true,
        hide_up_to_date      = true,
        hide_unstable_versions = true,
      })
    end,
    keys = {
      { "<leader>np",  function() require("package-info").toggle() end,          ft = "json", desc = "Package versions" },
      { "<leader>ni",  function() require("package-info").install() end,         ft = "json", desc = "Install package" },
      { "<leader>nu",  function() require("package-info").update() end,          ft = "json", desc = "Update package" },
      { "<leader>nd",  function() require("package-info").delete() end,          ft = "json", desc = "Delete package" },
      { "<leader>nc",  function() require("package-info").change_version() end,  ft = "json", desc = "Change version" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  CSS / SCSS  ·  color preview already in tools/colorizer
  --  Add CSS-specific completions
  -- ────────────────────────────────────────────────────────
  {
    "roobert/tailwindcss-colorizer-cmp.nvim",
    ft     = { "html", "css", "scss", "javascript", "typescript",
               "javascriptreact", "typescriptreact" },
    config = function()
      require("tailwindcss-colorizer-cmp").setup({ color_square_width = 2 })
      -- Patch cmp formatting to include Tailwind colors
      local cmp = require("cmp")
      local orig = cmp.config.formatting or {}
      orig.format = require("tailwindcss-colorizer-cmp").formatter
      cmp.config.formatting = orig
    end,
  },
}
