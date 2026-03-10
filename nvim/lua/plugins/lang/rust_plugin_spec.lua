-- ============================================================
--  plugins/lang/rust.lua
--  LAZY TRIGGER: ft = "rust"  (*.rs files)
--  Uses rustaceanvim (modern replacement for rust-tools.nvim)
--  + our custom rust-tools plugin
-- ============================================================

return {
	-- ── Our custom Rust project manager ───────────────────
	{
		-- Load from local path (lives inside your nvim config)
		dir = vim.fn.stdpath("config") .. "/plugins/rust-tools.nvim",
		name = "rust-tools",
		ft = { "rust" },
		event = { "BufRead Cargo.toml" },
		-- RustNewProject works from anywhere, so also register on VimEnter
		lazy = false,
		config = function()
			require("rust-tools").setup({
				-- Change terminal style: "float" | "split" | "tab"
				terminal = "float",

				-- Default run profile
				run_profile = "debug",

				-- Where new projects get created (nil = ask each time)
				projects_dir = vim.fn.expand("~/projects"),

				-- Python interpreter
				python = "python3",

				-- Keymaps (customize as you like)
				keymaps = {
					new_project = "<leader>Rn",
					run = "<leader>Rr",
					build_debug = "<leader>Rb",
					build_release = "<leader>RB",
					test = "<leader>Rt",
					test_current = "<leader>RT",
					check = "<leader>Rc",
					clippy = "<leader>Rl",
					add_dep = "<leader>Ra",
					new_module = "<leader>Rm",
					new_mod_dir = "<leader>RM",
					open_cargo = "<leader>Ro",
					doc = "<leader>Rd",
					clean = "<leader>Rx",
					fmt = "<leader>Rf",
					bench = "<leader>Re",
					update_deps = "<leader>Ru",
					features_menu = "<leader>RF",
					tree = "<leader>Ri",
				},
			})
		end,
	},

	-- ────────────────────────────────────────────────────────
	--  RUSTACEANVIM  ·  LSP + hover actions + runnables
	-- ────────────────────────────────────────────────────────
	{
		"mrcjkb/rustaceanvim",
		version = "^4",
		ft = { "rust" },
		dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim" },
		init = function()
			local mason_registry = require("mason-registry")
			for _, tool in ipairs({ "rust-analyzer", "codelldb" }) do
				if not mason_registry.is_installed(tool) then
					vim.cmd("MasonInstall " .. tool)
				end
			end
		end,
		config = function()
			local mason_path = vim.fn.stdpath("data") .. "/mason"
			local codelldb = mason_path .. "/bin/codelldb"
			local liblldb = mason_path .. "/packages/codelldb/extension/lldb/lib/liblldb"
			liblldb = liblldb .. (vim.fn.has("mac") == 1 and ".dylib" or ".so")

			vim.g.rustaceanvim = {
				tools = {
					float_win_config = { border = "rounded" },
					hover_actions = { replace_builtin_hover = true },
					code_actions = { ui_select_fallback = true },
				},
				server = {
					on_attach = function(_, bufnr)
						local map = function(k, f, desc)
							vim.keymap.set("n", k, f, { buffer = bufnr, desc = desc })
						end
						-- rustaceanvim-specific (LSP layer)
						map("K", function()
							vim.cmd.RustLsp({ "hover", "actions" })
						end, "Hover actions")
						map("<leader>rh", function()
							vim.cmd.RustLsp({ "hover", "actions" })
						end, "Hover actions")
						map("<leader>ra", function()
							vim.cmd.RustLsp("codeAction")
						end, "Code action (Rust)")
						map("<leader>re", function()
							vim.cmd.RustLsp("expandMacro")
						end, "Expand macro")
						map("<leader>rp", function()
							vim.cmd.RustLsp("parentModule")
						end, "Parent module")
					end,
					default_settings = {
						["rust-analyzer"] = {
							cargo = { allFeatures = true, loadOutDirsFromCheck = true },
							checkOnSave = { command = "clippy", allFeatures = true },
							procMacro = { enable = true },
							inlayHints = {
								chainingHints = { enable = true },
								parameterHints = { enable = true },
								typeHints = { enable = true },
							},
						},
					},
				},
				dap = {
					adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, liblldb),
				},
			}
		end,
	},

	-- ── Cargo.toml dependency helper ──────────────────────
	{
		"saecki/crates.nvim",
		ft = { "toml", "rust" },
		event = { "BufRead Cargo.toml" },
		config = function()
			require("crates").setup({
				popup = { border = "rounded" },
				null_ls = { enabled = true, name = "crates.nvim" },
			})
		end,
		keys = {
			{
				"<leader>ct",
				function()
					require("crates").toggle()
				end,
				ft = "toml",
				desc = "Toggle crate info",
			},
			{
				"<leader>cr",
				function()
					require("crates").reload()
				end,
				ft = "toml",
				desc = "Reload crates",
			},
			{
				"<leader>cv",
				function()
					require("crates").show_versions_popup()
				end,
				ft = "toml",
				desc = "Crate versions",
			},
			{
				"<leader>cf",
				function()
					require("crates").show_features_popup()
				end,
				ft = "toml",
				desc = "Crate features",
			},
			{
				"<leader>cd",
				function()
					require("crates").show_dependencies_popup()
				end,
				ft = "toml",
				desc = "Crate deps",
			},
			{
				"<leader>cu",
				function()
					require("crates").upgrade_crate()
				end,
				ft = "toml",
				desc = "Upgrade crate",
			},
			{
				"<leader>cU",
				function()
					require("crates").upgrade_all_crates()
				end,
				ft = "toml",
				desc = "Upgrade all crates",
			},
		},
	},
}
