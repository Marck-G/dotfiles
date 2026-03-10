-- ============================================================
--  rust-tools.nvim  ·  Custom Rust project manager
--  Commands: new project, run, build, test, modules, deps...
-- ============================================================

local M = {}

-- Lazy-load submodules
local function get(mod)
	return require("rust-tools." .. mod)
end

-- ── Setup ─────────────────────────────────────────────────
function M.setup(opts)
	opts = opts or {}

	-- Store user config globally for submodules
	require("rust-tools.config").setup(opts)

	-- Register all :Rust* user commands
	require("rust-tools.commands").register()

	-- Register which-key groups if available
	local ok, wk = pcall(require, "which-key")
	if ok then
		wk.register({
			["<leader>R"] = { name = "🦀 Rust Tools" },
		})
	end

	vim.notify("🦀 rust-tools.nvim loaded", vim.log.levels.DEBUG)
end

return M
