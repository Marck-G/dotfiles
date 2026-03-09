-- ============================================================
--  plugins/lsp.lua  ·  LSP + Completion + DAP + Lint + Format
--  Neovim 0.11+ native vim.lsp.config API
--
--  Languages covered:
--    Rust · Java · PHP · Lua · Python
--    Web: Node/JS/TS/HTML/CSS/SASS
--
--  Mason installs:
--    LSP servers · DAP adapters · Linters · Formatters
-- ============================================================

return {

  -- ────────────────────────────────────────────────────────
  --  MASON CORE  ·  the package manager UI
  -- ────────────────────────────────────────────────────────
  {
    "williamboman/mason.nvim",
    lazy   = false,
    config = function()
      require("mason").setup({
        ui = {
          border  = "rounded",
          width   = 0.8,
          height  = 0.8,
          icons   = {
            package_installed   = "✓",
            package_pending     = "➜",
            package_uninstalled = "✗",
          },
        },
        -- Mason install dir: ~/.local/share/nvim/mason
      })
    end,
    keys = { { "<leader>lm", "<cmd>Mason<CR>", desc = "Mason installer" } },
  },

  -- ────────────────────────────────────────────────────────
  --  MASON-LSPCONFIG  ·  LSP servers via Mason
  -- ────────────────────────────────────────────────────────
  {
    "williamboman/mason-lspconfig.nvim",
    lazy         = false,
    dependencies = { "mason.nvim" },
    config       = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- ── Rust ──────────────────────────────────────
          "rust_analyzer",      -- LSP (rustaceanvim manages config)

          -- ── Java ──────────────────────────────────────
          -- jdtls handled in lang/java.lua (needs special setup)

          -- ── PHP ───────────────────────────────────────
          "phpactor",           -- LSP (refactoring, completion)
          "intelephense",       -- LSP (better for large projects)

          -- ── Lua ───────────────────────────────────────
          "lua_ls",             -- LSP

          -- ── Python ────────────────────────────────────
          "pyright",            -- LSP (type checking)
          "ruff",               -- LSP + linter + formatter

          -- ── Web: JS / TS / Node ───────────────────────
          "ts_ls",              -- LSP TypeScript/JavaScript
          "eslint",             -- LSP linter
          "jsonls",             -- LSP JSON
          "html",               -- LSP HTML
          "cssls",              -- LSP CSS/SCSS/LESS

          -- ── Web: extra ────────────────────────────────
          "tailwindcss",        -- LSP Tailwind class completion
          "emmet_ls",           -- LSP Emmet (HTML/CSS expansion)

          -- ── Shell / Config ────────────────────────────
          "bashls",
          "yamlls",
          "dockerls",
          "marksman",           -- Markdown
        },
        automatic_installation = true,
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  MASON-TOOL-INSTALLER  ·  DAP + Linters + Formatters
  --  mason-lspconfig only handles LSP servers.
  --  For DAP adapters, linters, formatters we use this.
  -- ────────────────────────────────────────────────────────
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy         = false,
    dependencies = { "mason.nvim" },
    config       = function()
      require("mason-tool-installer").setup({
        ensure_installed = {

          -- ════════════════════════════════════════════
          --  DAP ADAPTERS
          -- ════════════════════════════════════════════

          -- Rust / C / C++ (codelldb)
          "codelldb",

          -- Java (handled by mason in lang/java.lua)
          "java-debug-adapter",
          "java-test",

          -- PHP
          "php-debug-adapter",

          -- Python
          "debugpy",

          -- JavaScript / TypeScript / Node
          "js-debug-adapter",

          -- ════════════════════════════════════════════
          --  LINTERS
          -- ════════════════════════════════════════════

          -- Lua
          "luacheck",

          -- Python
          "pylint",
          "mypy",               -- type checking linter
          "bandit",             -- security linter

          -- PHP
          "phpstan",            -- static analysis
          "phpcs",              -- coding standards (PSR-2/PSR-12)

          -- JavaScript / TypeScript
          -- eslint-lsp already above; this adds standalone CLI
          "eslint_d",           -- fast eslint daemon

          -- HTML
          "htmlhint",

          -- CSS / SASS
          "stylelint",

          -- Shell
          "shellcheck",

          -- ════════════════════════════════════════════
          --  FORMATTERS
          -- ════════════════════════════════════════════

          -- Rust: rustfmt is bundled with rustup, not Mason
          -- (rustaceanvim calls it automatically)

          -- Java
          "google-java-format",

          -- Lua
          "stylua",

          -- Python
          "black",              -- opinionated formatter
          "isort",              -- import sorter
          "autopep8",           -- PEP8 formatter (alternative)

          -- PHP
          "php-cs-fixer",       -- PSR-12 / custom rules

          -- JavaScript / TypeScript / HTML / CSS / JSON / YAML / MD
          "prettier",           -- handles all web formats
          "prettierd",          -- faster prettier daemon

          -- CSS / SASS
          -- prettier handles these too, but stylelint-prettier
          -- gives more control

          -- Shell
          "shfmt",

          -- SQL
          "sql-formatter",

        },
        auto_update       = false,   -- don't auto-update (run :MasonToolsUpdate manually)
        run_on_config     = true,    -- install missing tools on startup
        start_delay       = 3000,    -- delay (ms) to not slow down startup
        debounce_hours    = 5,       -- only check once every 5 hours
      })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  NVIM-LSPCONFIG  ·  configure LSP servers (0.11+ API)
  -- ────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    lazy         = false,
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/schemastore.nvim",
      "SmiteshP/nvim-navic",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local navic        = require("nvim-navic")

      -- ── Shared on_attach ──────────────────────────────
      local on_attach = function(client, bufnr)
        if client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end

        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end
        local tb = require("telescope.builtin")

        map("gd",         vim.lsp.buf.definition,         "Go to definition")
        map("gD",         vim.lsp.buf.declaration,        "Go to declaration")
        map("gr",         tb.lsp_references,              "References")
        map("gi",         vim.lsp.buf.implementation,     "Go to implementation")
        map("gt",         vim.lsp.buf.type_definition,    "Type definition")
        map("K",          vim.lsp.buf.hover,              "Hover docs")
        map("<C-k>",      vim.lsp.buf.signature_help,     "Signature help")
        map("<leader>lr", vim.lsp.buf.rename,             "Rename symbol")
        map("<leader>la", vim.lsp.buf.code_action,        "Code action")
        map("<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end,                                              "Format buffer")
        map("<leader>ld", vim.diagnostic.open_float,      "Diagnostic float")
        map("<leader>lD", tb.diagnostics,                 "All diagnostics")
        map("[d",         vim.diagnostic.goto_prev,       "Prev diagnostic")
        map("]d",         vim.diagnostic.goto_next,       "Next diagnostic")
        map("<leader>ls", tb.lsp_document_symbols,        "Document symbols")
        map("<leader>lS", tb.lsp_workspace_symbols,       "Workspace symbols")
        map("<leader>li", "<cmd>LspInfo<CR>",             "LSP info")
      end

      -- ── Hover/signature borders ───────────────────────
      vim.lsp.handlers["textDocument/hover"] =
        vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

      -- ── Server configurations ─────────────────────────
      local servers = {

        -- ── Rust (rustaceanvim manages the real config) ──
        rust_analyzer = {
          capabilities = capabilities,
          on_attach    = on_attach,
        },

        -- ── PHP ──────────────────────────────────────────
        -- Use intelephense (comment out phpactor if not needed)
        intelephense = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            intelephense = {
              stubs = {
                "apache", "bcmath", "bz2", "calendar", "com_dotnet",
                "Core", "curl", "date", "dba", "dom", "enchant",
                "exif", "FFI", "fileinfo", "filter", "fpm", "ftp",
                "gd", "gettext", "gmp", "hash", "iconv", "imap",
                "intl", "json", "ldap", "libxml", "mbstring",
                "meta", "mysqli", "oci8", "odbc", "openssl",
                "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql",
                "pdo_pgsql", "pdo_sqlite", "pgsql", "Phar",
                "posix", "pspell", "random", "readline", "Reflection",
                "session", "shmop", "SimpleXML", "snmp", "soap",
                "sockets", "sodium", "SPL", "sqlite3", "standard",
                "superglobals", "sysvmsg", "sysvsem", "sysvshm",
                "tidy", "tokenizer", "xml", "xmlreader", "xmlrpc",
                "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib",
                -- Frameworks (add/remove as needed)
                "wordpress", "phpunit",
              },
              files = {
                maxSize = 5000000,
              },
              environment = {
                phpVersion = "8.2",
              },
              format = { enable = true },
            },
          },
        },

        -- phpactor as alternative (lighter, uncomment if preferred)
        -- phpactor = {
        --   capabilities = capabilities,
        --   on_attach    = on_attach,
        --   init_options = { ["language_server_phpstan.enabled"] = true },
        -- },

        -- ── Lua ──────────────────────────────────────────
        lua_ls = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            Lua = {
              runtime     = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace   = {
                library         = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
              format    = { enable = false },  -- stylua handles this
              hint      = { enable = true },   -- inlay hints
            },
          },
        },

        -- ── Python ───────────────────────────────────────
        pyright = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            python = {
              analysis = {
                typeCheckingMode         = "basic",
                autoImportCompletions    = true,
                autoSearchPaths          = true,
                diagnosticMode           = "workspace",
                useLibraryCodeForTypes   = true,
              },
            },
          },
        },

        ruff = {
          capabilities = capabilities,
          on_attach    = function(client, bufnr)
            on_attach(client, bufnr)
            -- pyright handles hover; ruff handles lint/format
            client.server_capabilities.hoverProvider = false
          end,
        },

        -- ── JavaScript / TypeScript ───────────────────────
        ts_ls = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints         = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints          = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints        = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints         = "all",
                includeInlayVariableTypeHints          = true,
                includeInlayFunctionLikeReturnTypeHints = true,
              },
            },
          },
        },

        eslint = {
          capabilities = capabilities,
          on_attach    = function(client, bufnr)
            on_attach(client, bufnr)
            -- Auto-fix all eslint issues on save
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer  = bufnr,
              command = "EslintFixAll",
            })
          end,
        },

        -- ── HTML ─────────────────────────────────────────
        html = {
          capabilities = capabilities,
          on_attach    = on_attach,
          filetypes    = { "html", "htmldjango", "jinja", "php" },
        },

        -- ── CSS / SCSS / SASS / LESS ─────────────────────
        cssls = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            css  = { validate = true, lint = { unknownAtRules = "ignore" } },
            scss = { validate = true, lint = { unknownAtRules = "ignore" } },
            less = { validate = true },
          },
        },

        tailwindcss = {
          capabilities = capabilities,
          on_attach    = on_attach,
          filetypes    = {
            "html", "css", "scss", "sass", "less",
            "javascript", "typescript",
            "javascriptreact", "typescriptreact",
            "svelte", "vue", "php",
          },
        },

        emmet_ls = {
          capabilities = capabilities,
          on_attach    = on_attach,
          filetypes    = {
            "html", "css", "scss", "sass", "less",
            "javascript", "javascriptreact",
            "typescript", "typescriptreact",
            "php", "vue", "svelte",
          },
          init_options = {
            html = {
              options = { ["bem.enabled"] = true },
            },
          },
        },

        -- ── JSON ─────────────────────────────────────────
        jsonls = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            json = {
              schemas  = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },

        -- ── YAML ─────────────────────────────────────────
        yamlls = {
          capabilities = capabilities,
          on_attach    = on_attach,
          settings     = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas     = require("schemastore").yaml.schemas(),
            },
          },
        },

        -- ── Other ─────────────────────────────────────────
        bashls   = { capabilities = capabilities, on_attach = on_attach },
        dockerls = { capabilities = capabilities, on_attach = on_attach },
        marksman = { capabilities = capabilities, on_attach = on_attach },
      }

      -- ── Apply via Neovim 0.11+ native API ─────────────
      for name, cfg in pairs(servers) do
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
      end
    end,
  },

  { "SmiteshP/nvim-navic",  lazy = true },
  { "b0o/schemastore.nvim", lazy = true },

  -- ────────────────────────────────────────────────────────
  --  CONFORM.NVIM  ·  formatter runner (replaces none-ls fmt)
  --  Faster and more reliable than null-ls for formatting
  -- ────────────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          -- Lua
          lua = { "stylua" },

          -- Python
          python = { "isort", "black" },    -- isort first, then black

          -- Rust: rustfmt via rustaceanvim (not conform)
          -- rust = { "rustfmt" },           -- uncomment if not using rustaceanvim

          -- Java
          java = { "google-java-format" },

          -- PHP
          php = { "php-cs-fixer" },

          -- JavaScript / TypeScript
          javascript      = { "prettierd", "prettier", stop_after_first = true },
          typescript      = { "prettierd", "prettier", stop_after_first = true },
          javascriptreact = { "prettierd", "prettier", stop_after_first = true },
          typescriptreact = { "prettierd", "prettier", stop_after_first = true },

          -- Web
          html = { "prettierd", "prettier", stop_after_first = true },
          css  = { "prettierd", "stylelint", stop_after_first = true },
          scss = { "prettierd", "stylelint", stop_after_first = true },
          sass = { "prettierd", "stylelint", stop_after_first = true },
          less = { "prettierd", "prettier", stop_after_first = true },

          -- Data / Config
          json  = { "prettierd", "prettier", stop_after_first = true },
          jsonc = { "prettierd", "prettier", stop_after_first = true },
          yaml  = { "prettierd", "prettier", stop_after_first = true },
          toml  = { "prettierd", "prettier", stop_after_first = true },

          -- Markdown
          markdown = { "prettierd", "prettier", stop_after_first = true },

          -- Shell
          sh   = { "shfmt" },
          bash = { "shfmt" },
          zsh  = { "shfmt" },

          -- SQL
          sql = { "sql-formatter" },

          -- Fallback: format anything with prettier if possible
          ["*"] = { "trim_whitespace" },
        },

        -- Format on save
        format_on_save = {
          timeout_ms = 3000,
          lsp_format = "fallback",   -- use LSP if no conform formatter
        },

        formatters = {
          -- Custom shfmt options
          shfmt = {
            prepend_args = { "-i", "2", "-ci" },  -- 2-space indent, switch indent
          },
          -- Custom black options
          black = {
            prepend_args = { "--line-length", "88" },
          },
          -- Custom isort options
          isort = {
            prepend_args = { "--profile", "black" },
          },
          -- php-cs-fixer config
          ["php-cs-fixer"] = {
            prepend_args = { "--rules=@PSR12" },
          },
          -- sql-formatter dialect
          ["sql-formatter"] = {
            prepend_args = { "--language", "sql" },
          },
        },
      })

      -- Format keymap (override LSP format)
      vim.keymap.set({ "n", "v" }, "<leader>lf", function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end, { desc = "Format buffer (conform)" })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  NVIM-LINT  ·  linter runner
  --  Runs linters on save / insert leave
  -- ────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- Lua
        lua = { "luacheck" },

        -- Python
        python = { "pylint", "mypy" },

        -- PHP
        php = { "phpstan", "phpcs" },

        -- JavaScript / TypeScript
        javascript      = { "eslint_d" },
        typescript      = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },

        -- HTML
        html = { "htmlhint" },

        -- CSS / SCSS
        css  = { "stylelint" },
        scss = { "stylelint" },
        sass = { "stylelint" },

        -- Shell
        sh   = { "shellcheck" },
        bash = { "shellcheck" },
      }

      -- Lint on save and when leaving insert mode
      local lint_augroup = vim.api.nvim_create_augroup("NvimLint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufReadPost" }, {
        group    = lint_augroup,
        callback = function()
          -- Only lint if a linter is configured for this filetype
          local ft = vim.bo.filetype
          if lint.linters_by_ft[ft] then
            lint.try_lint()
          end
        end,
      })

      vim.keymap.set("n", "<leader>ll", function()
        lint.try_lint()
      end, { desc = "Run linter" })
    end,
  },

  -- ────────────────────────────────────────────────────────
  --  DAP CORE  ·  Debug Adapter Protocol
  -- ────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    lazy         = true,
    dependencies = {
      -- UI
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup({
            icons = { expanded = "", collapsed = "", current_frame = "" },
            controls = {
              icons = {
                pause       = "",
                play        = "",
                step_into   = "",
                step_over   = "",
                step_out    = "",
                step_back   = "",
                run_last    = "",
                terminate   = "",
                disconnect  = "",
              },
            },
          })
          -- Auto open/close DAP UI with debug session
          dap.listeners.after.event_initialized["dapui_config"]  = dapui.open
          dap.listeners.before.event_terminated["dapui_config"]  = dapui.close
          dap.listeners.before.event_exited["dapui_config"]      = dapui.close
        end,
      },
      -- Inline variable values while debugging
      {
        "theHamsta/nvim-dap-virtual-text",
        config = function()
          require("nvim-dap-virtual-text").setup({
            commented        = true,   -- show as comment
            display_callback = function(variable, _, _, _, options)
              if options.virt_text_pos == "inline" then
                return " = " .. variable.value
              else
                return variable.name .. " = " .. variable.value
              end
            end,
          })
        end,
      },
    },

    config = function()
      local dap         = require("dap")
      local mason_path  = vim.fn.stdpath("data") .. "/mason"

      -- ── DAP signs ──────────────────────────────────────
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DapBreakpoint",          linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DapBreakpointRejected",  linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint",            { text = "◎", texthl = "DapLogPoint",            linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DapStopped",             linehl = "DapStopped", numhl = "DapStopped" })

      -- ════════════════════════════════════════════════════
      --  RUST DAP  ·  codelldb
      -- ════════════════════════════════════════════════════
      local codelldb   = mason_path .. "/bin/codelldb"
      local liblldb    = mason_path .. "/packages/codelldb/extension/lldb/lib/liblldb"
      liblldb = liblldb .. (vim.fn.has("mac") == 1 and ".dylib" or ".so")

      dap.adapters.codelldb = {
        type    = "server",
        port    = "${port}",
        executable = {
          command = codelldb,
          args    = { "--port", "${port}" },
        },
      }
      -- Rust uses codelldb (rustaceanvim sets this up too, this is a fallback)
      dap.configurations.rust = {
        {
          name    = "Launch (codelldb)",
          type    = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
          end,
          cwd     = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- ════════════════════════════════════════════════════
      --  JAVA DAP  ·  java-debug-adapter (set up in lang/java.lua)
      -- ════════════════════════════════════════════════════
      -- java-debug-adapter is a bundle loaded by jdtls.
      -- See lua/plugins/lang/java.lua for the full config.

      -- ════════════════════════════════════════════════════
      --  PHP DAP  ·  php-debug-adapter (XDebug)
      -- ════════════════════════════════════════════════════
      dap.adapters.php = {
        type = "executable",
        command = "node",
        args    = {
          mason_path .. "/packages/php-debug-adapter/extension/out/phpDebug.js",
        },
      }
      dap.configurations.php = {
        {
          name       = "Listen for XDebug",
          type       = "php",
          request    = "launch",
          port       = 9003,
          pathMappings = {
            ["/var/www/html"] = "${workspaceFolder}",
          },
        },
        {
          name    = "Launch current file (CLI)",
          type    = "php",
          request = "launch",
          port    = 9003,
          program = "${file}",
          cwd     = "${fileDirname}",
          runtimeArgs = { "-dxdebug.start_with_request=1" },
          env     = {
            XDEBUG_MODE    = "debug",
            XDEBUG_CONFIG  = "client_host=127.0.0.1 client_port=9003",
          },
        },
      }

      -- ════════════════════════════════════════════════════
      --  PYTHON DAP  ·  debugpy
      -- ════════════════════════════════════════════════════
      dap.adapters.python = {
        type    = "executable",
        command = mason_path .. "/packages/debugpy/venv/bin/python",
        args    = { "-m", "debugpy.adapter" },
      }
      dap.configurations.python = {
        {
          name    = "Launch file",
          type    = "python",
          request = "launch",
          program = "${file}",
          pythonPath = function()
            -- Use active venv if available
            local venv = os.getenv("VIRTUAL_ENV")
            if venv then return venv .. "/bin/python" end
            return mason_path .. "/packages/debugpy/venv/bin/python"
          end,
        },
        {
          name    = "Launch file with arguments",
          type    = "python",
          request = "launch",
          program = "${file}",
          args    = function()
            local args = vim.fn.input("Args: ")
            return vim.split(args, " ")
          end,
          pythonPath = function()
            local venv = os.getenv("VIRTUAL_ENV")
            if venv then return venv .. "/bin/python" end
            return mason_path .. "/packages/debugpy/venv/bin/python"
          end,
        },
        {
          name    = "Django / Flask",
          type    = "python",
          request = "launch",
          program = "${workspaceFolder}/manage.py",
          args    = { "runserver", "--noreload" },
          django  = true,
          pythonPath = function()
            local venv = os.getenv("VIRTUAL_ENV")
            if venv then return venv .. "/bin/python" end
            return "python"
          end,
        },
      }

      -- ════════════════════════════════════════════════════
      --  JAVASCRIPT / TYPESCRIPT / NODE DAP  ·  js-debug-adapter
      -- ════════════════════════════════════════════════════
      local js_debug = mason_path .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args    = { js_debug, "${port}" },
        },
      }
      dap.adapters["pwa-chrome"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args    = { js_debug, "${port}" },
        },
      }

      -- Shared JS/TS configurations
      local js_config = {
        {
          name    = "Launch Node file",
          type    = "pwa-node",
          request = "launch",
          program = "${file}",
          cwd     = "${workspaceFolder}",
        },
        {
          name    = "Attach to Node process",
          type    = "pwa-node",
          request = "attach",
          processId = require("dap.utils").pick_process,
          cwd     = "${workspaceFolder}",
        },
        {
          name    = "Launch Chrome (React/Vite/Next)",
          type    = "pwa-chrome",
          request = "launch",
          url     = function()
            return vim.fn.input("URL: ", "http://localhost:3000")
          end,
          webRoot = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          name    = "Jest (current file)",
          type    = "pwa-node",
          request = "launch",
          runtimeExecutable = "node",
          runtimeArgs       = { "--inspect-brk", "${workspaceFolder}/node_modules/.bin/jest",
                                "--testTimeout=60000", "--runInBand" },
          console           = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          cwd               = "${workspaceFolder}",
        },
      }
      dap.configurations.javascript      = js_config
      dap.configurations.typescript      = js_config
      dap.configurations.javascriptreact = js_config
      dap.configurations.typescriptreact = js_config
    end,

    keys = {
      { "<leader>db",  function() require("dap").toggle_breakpoint() end,   desc = "Toggle breakpoint" },
      { "<leader>dB",  function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end,                                                                  desc = "Conditional breakpoint" },
      { "<leader>dl",  function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log: "))
        end,                                                                  desc = "Log point" },
      { "<leader>dc",  function() require("dap").continue() end,            desc = "Continue / Start" },
      { "<leader>di",  function() require("dap").step_into() end,           desc = "Step into" },
      { "<leader>do",  function() require("dap").step_over() end,           desc = "Step over" },
      { "<leader>dO",  function() require("dap").step_out() end,            desc = "Step out" },
      { "<leader>dr",  function() require("dap").repl.toggle() end,         desc = "REPL" },
      { "<leader>dL",  function() require("dap").run_last() end,            desc = "Run last" },
      { "<leader>du",  function() require("dapui").toggle() end,            desc = "DAP UI" },
      { "<leader>dx",  function() require("dap").terminate() end,           desc = "Terminate" },
      { "<leader>dh",  function() require("dap.ui.widgets").hover() end,    desc = "Hover value" },
      { "<leader>dp",  function() require("dap.ui.widgets").preview() end,  desc = "Preview" },
    },
  },

  -- ────────────────────────────────────────────────────────
  --  COMPLETION  ·  nvim-cmp
  -- ────────────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event        = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "onsails/lspkind.nvim",
      {
        "L3MON4D3/LuaSnip",
        version      = "v2.*",
        build        = "make install_jsregexp",
        dependencies = { "rafamadriz/friendly-snippets" },
        config       = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = lspkind.cmp_format({
            mode          = "symbol_text",
            maxwidth      = 50,
            ellipsis_char = "...",
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp",                priority = 1000 },
          { name = "nvim_lsp_signature_help", priority = 900  },
          { name = "luasnip",                 priority = 750  },
          { name = "path",                    priority = 500  },
          { name = "buffer",                  priority = 250, keyword_length = 3 },
        }),
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources(
          { { name = "path" } },
          { { name = "cmdline" } }
        ),
      })
    end,
  },
}