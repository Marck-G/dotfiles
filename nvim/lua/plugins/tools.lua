-- ============================================================
--  plugins/tools.lua  ·  Core IDE tools
--  Telescope · NvimTree · Git · DAP · Autopairs · Comment
--  Flash · Illuminate · Trouble · Startuptime
-- ============================================================

return {

  -- ────────────────────────────────────────────────────────
  --  FILE EXPLORER  ·  nvim-tree
  -- ────────────────────────────────────────────────────────
  {
    "nvim-tree/nvim-tree.lua",
    lazy         = false,
    dependencies = { "nvim-web-devicons" },
    config       = function()
      -- Disable netrw (nvim-tree replaces it)
      vim.g.loaded_netrw       = 1
      vim.g.loaded_netrwPlugin = 1

      require("nvim-tree").setup({
        view = { width = 35, side = "left" },
        renderer = {
          group_empty     = true,
          highlight_git   = true,
          icons = {
            show = { file = true, folder = true, folder_arrow = true, git = true },
          },
        },
        filters   = { dotfiles = false },
        git       = { enable = true, ignore = false },
        actions   = {
          open_file = {
            quit_on_open  = false,
            window_picker = { enable = true },
          },
        },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          local opts = function(desc)
            return { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = desc }
          end
          -- Default mappings
          api.config.mappings.default_on_attach(bufnr)
          -- Extra
          vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
        end,
      })
    end,
    keys = {
      { "<leader>e",  "<cmd>NvimTreeToggle<CR>",   desc = "Toggle file explorer" },
      { "<leader>fe", "<cmd>NvimTreeFocus<CR>",    desc = "Focus file explorer" },
      { "<leader>fE", "<cmd>NvimTreeFindFile<CR>", desc = "Reveal current file" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  FUZZY FINDER  ·  telescope
  -- ────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    cmd          = "Telescope",
    event        = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond  = function() return vim.fn.executable("make") == 1 end,
      },
      "nvim-telescope/telescope-ui-select.nvim",  -- use telescope for vim.ui.select
    },
    config       = function()
      local telescope = require("telescope")
      local actions   = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix   = "  ",
          selection_caret = " ",
          path_display    = { "smart" },
          sorting_strategy = "ascending",
          layout_config   = { horizontal = { preview_width = 0.55 } },
          mappings = {
            i = {
              ["<C-j>"]    = actions.move_selection_next,
              ["<C-k>"]    = actions.move_selection_previous,
              ["<C-q>"]    = actions.send_to_qflist + actions.open_qflist,
              ["<Esc>"]    = actions.close,
              ["<C-u>"]    = false,  -- clear prompt (default ctrl-u scrolls)
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy                   = true,
            override_generic_sorter = true,
            override_file_sorter    = true,
            case_mode               = "smart_case",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>",                    desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>",                     desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>",                       desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>",                     desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>",                      desc = "Recent files" },
      { "<leader>fc", "<cmd>Telescope command_history<CR>",               desc = "Command history" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>",                       desc = "Keymaps" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>",                   desc = "Grep word under cursor" },
      { "<leader>ft", "<cmd>Telescope treesitter<CR>",                    desc = "Treesitter symbols" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>",                   desc = "Diagnostics" },
      { "<leader>/",  "<cmd>Telescope current_buffer_fuzzy_find<CR>",     desc = "Fuzzy find in buffer" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  GIT  ·  gitsigns + fugitive
  -- ────────────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "" },
          topdelete    = { text = "" },
          changedelete = { text = "▎" },
          untracked    = { text = "▎" },
        },
        current_line_blame = true,
        current_line_blame_opts = { delay = 500 },
        on_attach = function(bufnr)
          local gs   = package.loaded.gitsigns
          local map  = function(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          -- Navigation
          map("n", "]h", gs.next_hunk,                    { desc = "Next hunk" })
          map("n", "[h", gs.prev_hunk,                    { desc = "Prev hunk" })
          -- Actions
          map("n", "<leader>gs", gs.stage_hunk,           { desc = "Stage hunk" })
          map("n", "<leader>gr", gs.reset_hunk,           { desc = "Reset hunk" })
          map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage hunk (visual)" })
          map("n", "<leader>gS", gs.stage_buffer,         { desc = "Stage buffer" })
          map("n", "<leader>gu", gs.undo_stage_hunk,      { desc = "Undo stage hunk" })
          map("n", "<leader>gR", gs.reset_buffer,         { desc = "Reset buffer" })
          map("n", "<leader>gp", gs.preview_hunk,         { desc = "Preview hunk" })
          map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
          map("n", "<leader>gd", gs.diffthis,             { desc = "Diff this" })
          map("n", "<leader>gD", function() gs.diffthis("~") end, { desc = "Diff ~" })
        end,
      })
    end,
  },

  {
    "tpope/vim-fugitive",
    cmd  = { "Git", "G" },
    keys = {
      { "<leader>gg", "<cmd>Git<CR>",          desc = "Git status" },
      { "<leader>gl", "<cmd>Git log<CR>",      desc = "Git log" },
      { "<leader>gP", "<cmd>Git push<CR>",     desc = "Git push" },
      { "<leader>gF", "<cmd>Git pull<CR>",     desc = "Git pull" },
      { "<leader>gc", "<cmd>Git commit<CR>",   desc = "Git commit" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  DEBUGGING  ·  nvim-dap
  -- ────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    lazy         = true,
    dependencies = {
      { "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup()
          -- Auto-open/close DAP UI
          dap.listeners.after.event_initialized["dapui_config"]  = dapui.open
          dap.listeners.before.event_terminated["dapui_config"]  = dapui.close
          dap.listeners.before.event_exited["dapui_config"]      = dapui.close
        end,
      },
      { "theHamsta/nvim-dap-virtual-text",
        config = function()
          require("nvim-dap-virtual-text").setup({ commented = true })
        end,
      },
      -- Python DAP
      { "mfussenegger/nvim-dap-python",
        ft     = "python",
        config = function()
          require("dap-python").setup("python")  -- uses active venv
        end,
      },
    },
    keys = {
      { "<leader>db",  function() require("dap").toggle_breakpoint() end,  desc = "Toggle breakpoint" },
      { "<leader>dB",  function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc",  function() require("dap").continue() end,           desc = "Continue / Start" },
      { "<leader>di",  function() require("dap").step_into() end,          desc = "Step into" },
      { "<leader>do",  function() require("dap").step_over() end,          desc = "Step over" },
      { "<leader>dO",  function() require("dap").step_out() end,           desc = "Step out" },
      { "<leader>dr",  function() require("dap").repl.toggle() end,        desc = "REPL toggle" },
      { "<leader>dl",  function() require("dap").run_last() end,           desc = "Run last" },
      { "<leader>du",  function() require("dapui").toggle() end,           desc = "DAP UI toggle" },
      { "<leader>dx",  function() require("dap").terminate() end,          desc = "Terminate" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  TROUBLE  ·  diagnostics panel
  -- ────────────────────────────────────────────────────────
  {
    "folke/trouble.nvim",
    cmd          = { "TroubleToggle", "Trouble" },
    dependencies = { "nvim-web-devicons" },
    config       = function()
      require("trouble").setup({ use_diagnostic_signs = true })
    end,
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle<CR>",                    desc = "Toggle Trouble" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<CR>", desc = "Workspace diagnostics" },
      { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>",  desc = "Document diagnostics" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<CR>",            desc = "Location list" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<CR>",           desc = "Quickfix list" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  AUTOPAIRS  ·  auto close brackets/quotes
  -- ────────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event  = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({ check_ts = true })
      -- Integration with nvim-cmp
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp           = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  COMMENTING  ·  Comment.nvim
  -- ────────────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  },

  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },

  -- ────────────────────────────────────────────────────────
  --  FLASH  ·  fast cursor movement (s, S, f, t)
  -- ────────────────────────────────────────────────────────
  {
    "folke/flash.nvim",
    event  = "VeryLazy",
    config = function() require("flash").setup() end,
    keys   = {
      { "s",     function() require("flash").jump() end,              mode = { "n", "x", "o" }, desc = "Flash jump" },
      { "S",     function() require("flash").treesitter() end,        mode = { "n", "x", "o" }, desc = "Flash treesitter" },
      { "r",     function() require("flash").remote() end,            mode = "o",               desc = "Remote flash" },
      { "R",     function() require("flash").treesitter_search() end, mode = { "o", "x" },      desc = "Treesitter search" },
      { "<C-s>", function() require("flash").toggle() end,            mode = "c",               desc = "Toggle flash search" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  ILLUMINATE  ·  highlight word under cursor
  -- ────────────────────────────────────────────────────────
  {
    "RRethy/vim-illuminate",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        providers = { "lsp", "treesitter", "regex" },
        delay     = 200,
        filetypes_denylist = { "NvimTree", "alpha", "Telescope" },
      })
    end,
    keys = {
      { "]]", function() require("illuminate").goto_next_reference() end, desc = "Next reference" },
      { "[[", function() require("illuminate").goto_prev_reference() end, desc = "Prev reference" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  SURROUND  ·  ys, ds, cs motions
  -- ────────────────────────────────────────────────────────
  {
    "kylechui/nvim-surround",
    event   = { "BufReadPost", "BufNewFile" },
    version = "*",
    config  = function() require("nvim-surround").setup() end,
  },

  -- ────────────────────────────────────────────────────────
  --  TODO COMMENTS  ·  highlight TODO/FIXME/HACK/NOTE
  -- ────────────────────────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    event        = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config       = function() require("todo-comments").setup() end,
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<CR>",   desc = "Find TODOs" },
      { "<leader>xt", "<cmd>TodoTrouble<CR>",     desc = "TODO in Trouble" },
      { "]t",  function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t",  function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  STARTUP TIME  ·  profiler
  -- ────────────────────────────────────────────────────────
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    keys = { { "<leader>st", "<cmd>StartupTime<CR>", desc = "Startup time profile" } },
  },
}
