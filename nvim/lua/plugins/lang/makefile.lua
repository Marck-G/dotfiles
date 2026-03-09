-- ============================================================
--  plugins/lang/makefile.lua
--  LAZY TRIGGER: ft = "make"  (Makefile, *.mk files)
--  AsyncRun  ·  run make targets async + Telescope picker
-- ============================================================

return {

  -- ────────────────────────────────────────────────────────
  --  ASYNCRUN  ·  run shell commands / make targets async
  -- ────────────────────────────────────────────────────────
  {
    "skywind3000/asyncrun.vim",
    ft  = { "make" },              -- ← LAZY: loads with Makefile
    cmd = { "AsyncRun", "AsyncStop" },
    init = function()
      vim.g.asyncrun_open     = 8    -- auto-open quickfix with 8 lines
      vim.g.asyncrun_bell     = 1    -- ring bell when done
      vim.g.asyncrun_rootdir  = ""   -- use cwd
    end,
    keys = {
      -- Run make with target (prompt)
      { "<leader>mm",  ":AsyncRun make ",         ft = "make",  desc = "Run make <target>" },
      -- Common targets
      { "<leader>mb",  "<cmd>AsyncRun make build<CR>",   desc = "make build" },
      { "<leader>mc",  "<cmd>AsyncRun make clean<CR>",   desc = "make clean" },
      { "<leader>mt",  "<cmd>AsyncRun make test<CR>",    desc = "make test" },
      { "<leader>mr",  "<cmd>AsyncRun make run<CR>",     desc = "make run" },
      { "<leader>mi",  "<cmd>AsyncRun make install<CR>", desc = "make install" },
      { "<leader>ms",  "<cmd>AsyncStop<CR>",             desc = "Stop async job" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  MAKE TARGET PICKER  ·  list & run targets via Telescope
  -- ────────────────────────────────────────────────────────
  {
    "ptethng/telescope-makefile",
    ft           = { "make" },      -- ← LAZY
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "skywind3000/asyncrun.vim",
    },
    config       = function()
      require("telescope").load_extension("make")
    end,
    keys = {
      { "<leader>mk",  "<cmd>Telescope make<CR>",  ft = "make", desc = "Pick make target" },
    },
  },
}
