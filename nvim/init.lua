-- ============================================================
--  NEOVIM IDE CONFIG  ·  init.lua
--  Stack: Java · Rust · Node/React · Python · SQL · Makefile
-- ============================================================

-- Core options & keymaps load first (no plugins required)
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Bootstrap lazy.nvim (auto-installs on first run)
require("core.lazy")
