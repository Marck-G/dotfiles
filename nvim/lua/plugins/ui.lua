-- ============================================================
--  plugins/ui.lua  ·  Visual / UI plugins
--  All load at startup (VimEnter / ColorScheme events)
-- ============================================================

return {

  -- ────────────────────────────────────────────────────────
  --  THEMES  (pick one — rest are commented out)
  -- ────────────────────────────────────────────────────────

  -- 🏆 Catppuccin Mocha (default — VSCode dark feel)
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,       -- load before everything else
    lazy     = false,
    config   = function()
      require("catppuccin").setup({
        flavour            = "mocha",  -- latte | frappe | macchiato | mocha
        background         = { light = "latte", dark = "mocha" },
        transparent_background = false,
        show_end_of_buffer = false,
        term_colors        = true,
        dim_inactive = { enabled = true, shade = "dark", percentage = 0.15 },
        integrations = {
          cmp            = true,
          gitsigns       = true,
          nvimtree       = true,
          treesitter     = true,
          telescope      = { enabled = true },
          which_key      = true,
          bufferline     = true,
          dap            = { enabled = true, enable_ui = true },
          lsp_trouble    = true,
          mason          = true,
          noice          = true,
          notify         = true,
          illuminate     = { enabled = true },
          indent_blankline = { enabled = true },
          native_lsp = {
            enabled    = true,
            virtual_text = {
              errors      = { "italic" },
              hints       = { "italic" },
              warnings    = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors      = { "underline" },
              hints       = { "underline" },
              warnings    = { "underline" },
              information = { "underline" },
            },
          },
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Tokyo Night (uncomment to use instead)
  -- { "folke/tokyonight.nvim", priority = 1000, lazy = false,
  --   config = function() vim.cmd.colorscheme("tokyonight-night") end },

  -- Kanagawa (uncomment to use instead)
  -- { "rebelot/kanagawa.nvim", priority = 1000, lazy = false,
  --   config = function() vim.cmd.colorscheme("kanagawa-wave") end },

  -- Rose Pine (uncomment to use instead)
  -- { "rose-pine/neovim", name = "rose-pine", priority = 1000, lazy = false,
  --   config = function() vim.cmd.colorscheme("rose-pine") end },

  -- ────────────────────────────────────────────────────────
  --  STATUS LINE  ·  lualine
  -- ────────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    lazy         = false,
    dependencies = { "nvim-web-devicons" },
    config       = function()
      -- LSP progress for statusline
      local lsp_progress = function()
        local clients = vim.lsp.get_active_clients({ bufnr = 0 })
        if #clients == 0 then return "" end
        return " LSP: " .. clients[1].name
      end

      require("lualine").setup({
        options = {
          theme                = "catppuccin",
          globalstatus         = true,
          disabled_filetypes   = { statusline = { "alpha", "NvimTree" } },
          component_separators = { left = "", right = "" },
          section_separators   = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },  -- relative path
          lualine_x = { lsp_progress, "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  BUFFER TABS  ·  bufferline
  -- ────────────────────────────────────────────────────────
  {
    "akinsho/bufferline.nvim",
    lazy         = false,
    dependencies = { "nvim-web-devicons" },
    version      = "*",
    config       = function()
      require("bufferline").setup({
        options = {
          mode               = "buffers",
          separator_style    = "slant",
          always_show_bufferline = false,
          show_buffer_close_icons = true,
          show_close_icon    = true,
          color_icons        = true,
          diagnostics        = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icons = { error = " ", warning = " " }
            return (icons[level] or "") .. count
          end,
          offsets = {{
            filetype   = "NvimTree",
            text       = " File Explorer",
            highlight  = "Directory",
            separator  = true,
          }},
        },
      })
    end,
    keys = {
      { "<S-l>",        "<cmd>BufferLineCycleNext<CR>",    desc = "Next buffer" },
      { "<S-h>",        "<cmd>BufferLineCyclePrev<CR>",    desc = "Prev buffer" },
      { "<leader>bp",   "<cmd>BufferLinePick<CR>",         desc = "Pick buffer" },
      { "<leader>bD",   "<cmd>BufferLinePickClose<CR>",    desc = "Pick close buffer" },
      { "<leader>b[",   "<cmd>BufferLineMovePrev<CR>",     desc = "Move buffer left" },
      { "<leader>b]",   "<cmd>BufferLineMoveNext<CR>",     desc = "Move buffer right" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  FILE ICONS
  -- ────────────────────────────────────────────────────────
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- ────────────────────────────────────────────────────────
  --  DASHBOARD  ·  alpha-nvim
  -- ────────────────────────────────────────────────────────
  {
    "goolord/alpha-nvim",
    event        = "VimEnter",
    dependencies = { "nvim-web-devicons" },
    config       = function()
      local alpha   = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        "                                                     ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
        "                                                     ",
      }

      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file",       "<cmd>Telescope find_files<CR>"),
        dashboard.button("r", "  Recent files",    "<cmd>Telescope oldfiles<CR>"),
        dashboard.button("g", "  Find text",       "<cmd>Telescope live_grep<CR>"),
        dashboard.button("s", "  Restore session", "<cmd>SessionRestore<CR>"),
        dashboard.button("l", "󰒲  Lazy",            "<cmd>Lazy<CR>"),
        dashboard.button("m", "  Mason",           "<cmd>Mason<CR>"),
        dashboard.button("q", "  Quit",            "<cmd>qa<CR>"),
      }

      dashboard.section.footer.val = "  IDE — Java · Rust · Node · React · Python · SQL"
      alpha.setup(dashboard.opts)
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  NOTIFICATIONS + COMMAND LINE  ·  noice + notify
  -- ────────────────────────────────────────────────────────
  {
    "rcarriga/nvim-notify",
    lazy   = false,
    config = function()
      require("notify").setup({
        background_colour = "#000000",
        render   = "compact",
        stages   = "fade_in_slide_out",
        timeout  = 3000,
        max_width = 60,
      })
      vim.notify = require("notify")  -- override default vim.notify
    end,
  },

  {
    "folke/noice.nvim",
    event        = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    config       = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"]                = true,
            ["cmp.entry.get_documentation"]                  = true,
          },
          progress = { enabled = true },
          hover    = { enabled = true },
          signature = { enabled = true },
        },
        routes = {
          -- Suppress noisy messages
          { filter = { event = "msg_show", any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
          }}, view = "mini" },
        },
        presets = {
          bottom_search         = true,   -- classic bottom search bar
          command_palette       = true,   -- position cmdline and popupmenu together
          long_message_to_split = true,   -- long messages in a split
          inc_rename            = false,
          lsp_doc_border        = true,   -- border for :LspInfo
        },
      })
    end,
    keys = {
      { "<leader>nd", "<cmd>NoiceDismiss<CR>", desc = "Dismiss notifications" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  INDENT GUIDES  ·  indent-blankline
  -- ────────────────────────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    event  = { "BufReadPost", "BufNewFile" },
    main   = "ibl",
    config = function()
      require("ibl").setup({
        indent  = { char = "│", tab_char = "│" },
        scope   = { enabled = true, show_start = true },
        exclude = { filetypes = { "help", "alpha", "NvimTree", "Lazy", "Mason" } },
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  WHICH-KEY  ·  keybinding hints
  -- ────────────────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event  = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({ window = { border = "rounded" } })
      -- Register group names
      wk.register({
        ["<leader>b"]  = { name = "󰓩 Buffer" },
        ["<leader>f"]  = { name = " Find (Telescope)" },
        ["<leader>g"]  = { name = " Git" },
        ["<leader>l"]  = { name = " LSP" },
        ["<leader>d"]  = { name = " Debug (DAP)" },
        ["<leader>t"]  = { name = " Test" },
        ["<leader>s"]  = { name = " Split" },
        ["<leader>x"]  = { name = " Trouble" },
        ["<leader>n"]  = { name = " Notifications" },
        ["<leader>r"]  = { name = " Run / Rust" },
        ["<leader>j"]  = { name = "☕ Java" },
        ["<leader>p"]  = { name = " Python" },
        ["<leader>db"] = { name = " Database" },
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  COLOR PREVIEW  ·  nvim-colorizer
  -- ────────────────────────────────────────────────────────
  {
    "norcalli/nvim-colorizer.lua",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("colorizer").setup({ "css", "scss", "html", "javascript",
        "typescript", "lua", "vim" })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  SYMBOL OUTLINE  ·  aerial.nvim
  -- ────────────────────────────────────────────────────────
  {
    "stevearc/aerial.nvim",
    event        = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-web-devicons" },
    config       = function()
      require("aerial").setup({
        backends         = { "treesitter", "lsp", "markdown", "man" },
        layout           = { default_direction = "prefer_right" },
        show_guides      = true,
        attach_mode      = "global",
        filter_kind      = false,
      })
    end,
    keys = {
      { "<leader>lo", "<cmd>AerialToggle!<CR>", desc = "Symbol outline" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  SESSION MANAGEMENT  ·  auto-session
  -- ────────────────────────────────────────────────────────
  {
    "rmagatti/auto-session",
    lazy   = false,
    config = function()
      require("auto-session").setup({
        log_level         = "error",
        auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
      })
    end,
    keys = {
      { "<leader>ss", "<cmd>SessionSave<CR>",    desc = "Save session" },
      { "<leader>sr", "<cmd>SessionRestore<CR>", desc = "Restore session" },
      { "<leader>sd", "<cmd>SessionDelete<CR>",  desc = "Delete session" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  MARKDOWN PREVIEW
  -- ────────────────────────────────────────────────────────
  {
    "iamcco/markdown-preview.nvim",
    ft      = { "markdown" },
    build   = "cd app && npm install",
    config  = function() vim.g.mkdp_auto_close = 1 end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Markdown preview" },
    },
  },

}