-- ============================================================
--  plugins/lang/rust.lua
--  LAZY TRIGGER: ft = "rust"  (*.rs files)
--  Uses rustaceanvim (modern replacement for rust-tools.nvim)
-- ============================================================

return {
	{
		"mrcjkb/rustaceanvim",
		version = "^4", -- use stable 4.x
		ft = { "rust" }, -- ← LAZY: only loads for .rs files
		dependencies = {
			"mfussenegger/nvim-dap",
			"williamboman/mason.nvim",
		},
		init = function()
			-- Ensure rust-analyzer + codelldb are installed via Mason
			local mason_registry = require("mason-registry")
			for _, tool in ipairs({ "rust-analyzer", "codelldb" }) do
				if not mason_registry.is_installed(tool) then
					vim.cmd("MasonInstall " .. tool)
				end
			end
		end,
		config = function()
			local mason_path = vim.fn.stdpath("data") .. "/mason"

			-- Find codelldb path for DAP
			local codelldb_path = mason_path .. "/bin/codelldb"
			local liblldb_path = mason_path .. "/packages/codelldb/extension/lldb/lib/liblldb"
			liblldb_path = liblldb_path .. (vim.fn.has("mac") == 1 and ".dylib" or ".so")

			vim.g.rustaceanvim = {
				-- ── Tools config ──────────────────────────────────
				tools = {
					float_win_config = { border = "rounded" },
					hover_actions = { replace_builtin_hover = true },
					code_actions = { ui_select_fallback = true },
				},

				-- ── LSP config ────────────────────────────────────
				server = {
					on_attach = function(client, bufnr)
						local map = function(k, f, desc)
							vim.keymap.set("n", k, f, { buffer = bufnr, desc = desc })
						end

						-- Rust-specific actions
						map("<leader>rr", function()
							vim.cmd.RustLsp("runnables")
						end, "Runnables")
						map("<leader>rd", function()
							vim.cmd.RustLsp("debuggables")
						end, "Debuggables")
						map("<leader>rt", function()
							vim.cmd.RustLsp("testables")
						end, "Testables")
						map("<leader>re", function()
							vim.cmd.RustLsp("expandMacro")
						end, "Expand macro")
						map("<leader>rc", function()
							vim.cmd.RustLsp("openCargo")
						end, "Open Cargo.toml")
						map("<leader>rp", function()
							vim.cmd.RustLsp("parentModule")
						end, "Parent module")
						map("<leader>rj", function()
							vim.cmd.RustLsp("moveItem", "down")
						end, "Move item down")
						map("<leader>rk", function()
							vim.cmd.RustLsp("moveItem", "up")
						end, "Move item up")
						map("<leader>rh", function()
							vim.cmd.RustLsp({ "hover", "actions" })
						end, "Hover actions")
						map("<leader>ra", function()
							vim.cmd.RustLsp("codeAction")
						end, "Code action (Rust)")
						map("K", function()
							vim.cmd.RustLsp({ "hover", "actions" })
						end, "Hover / Docs")
					end,

					default_settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								runBuildScripts = true,
							},
							checkOnSave = {
								allFeatures = true,
								command = "clippy", -- use clippy instead of check
								extraArgs = { "--no-deps" },
							},
							procMacro = {
								enable = true,
								ignored = {
									["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
								},
							},
							inlayHints = {
								bindingModeHints = { enable = false },
								chainingHints = { enable = true },
								closingBraceHints = { enable = true, minLines = 25 },
								closureReturnTypeHints = { enable = "never" },
								lifetimeElisionHints = { enable = "never" },
								parameterHints = { enable = true },
								typeHints = { enable = true },
							},
						},
					},
				},

				-- ── DAP config (codelldb) ─────────────────────────
				dap = {
					adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path),
				},
			}
		end,
	},

	-- ── Cargo.toml dependency helper ────────────────────────
	{
		"saecki/crates.nvim",
		ft = { "toml", "rust" }, -- ← LAZY: Cargo.toml / .rs
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
	-- ────────────────────────────────────────────────────────
	--  Our custom Rust project manager
	-- ────────────────────────────────────────────────────────
	{
		dir = vim.fn.stdpath("config") .. "/plugins/rust-tools.nvim",
		name = "rust-tools",
		lazy = false, -- load at startup so :RustNewProject works anywhere
		config = function()
			require("rust-tools").setup({
				terminal = "float", -- "float" | "split" | "tab"
				run_profile = "debug",
				projects_dir = vim.fn.expand("~/projects"),
				python = "python3",
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
}
