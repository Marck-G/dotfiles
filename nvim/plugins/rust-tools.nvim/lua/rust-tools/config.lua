-- ============================================================
--  rust-tools/config.lua  ·  Default config + user overrides
-- ============================================================

local M = {}

M.defaults = {
  -- Python interpreter (used for complex scripts)
  python = "python3",

  -- Terminal to use for interactive commands (cargo run, etc.)
  -- "toggleterm" | "split" | "float" | "tab"
  terminal = "float",

  -- Default cargo features to enable (e.g. { "feature1", "feature2" })
  features = {},

  -- Default project type for new projects
  -- "bin" | "lib"
  default_project_type = "bin",

  -- Path where new projects are created (nil = prompt user)
  projects_dir = nil,

  -- Automatically open new project in nvim-tree
  open_in_tree = true,

  -- Build profile used for "run"
  -- "debug" | "release"
  run_profile = "debug",

  -- Window config for floating terminal
  float_term = {
    width  = 0.85,
    height = 0.80,
    border = "rounded",
    title  = " 🦀 Cargo ",
  },

  -- Keymaps (set to false to disable a keymap)
  keymaps = {
    new_project    = "<leader>Rn",
    run            = "<leader>Rr",
    build_debug    = "<leader>Rb",
    build_release  = "<leader>RB",
    test           = "<leader>Rt",
    test_current   = "<leader>RT",
    check          = "<leader>Rc",
    clippy         = "<leader>Rl",
    add_dep        = "<leader>Ra",
    new_module     = "<leader>Rm",
    new_mod_dir    = "<leader>RM",
    open_cargo     = "<leader>Ro",
    doc            = "<leader>Rd",
    clean          = "<leader>Rx",
    fmt            = "<leader>Rf",
    bench          = "<leader>Re",
    update_deps    = "<leader>Ru",
    features_menu  = "<leader>RF",
    tree           = "<leader>Ri",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get()
  return M.options
end

return M
