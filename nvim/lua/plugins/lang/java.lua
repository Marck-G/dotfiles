-- ============================================================
--  plugins/lang/java.lua
--  LAZY TRIGGER: ft = "java"  (*.java files)
--  Uses nvim-jdtls for Eclipse JDT LSP
--  (richer than plain lspconfig for Java)
-- ============================================================

return {
  {
    "mfussenegger/nvim-jdtls",
    ft           = { "java" },   -- ← LAZY: only loads for .java files
    dependencies = {
      "mfussenegger/nvim-dap",   -- DAP for Java debugging
      "williamboman/mason.nvim",
    },
    config       = function()
      -- jdtls is managed per-project via an ftplugin-style setup.
      -- The actual jdtls.start() call lives in after/ftplugin/java.lua
      -- (created below via autocmd). This plugin just ensures jdtls
      -- is installed by Mason.

      -- Ensure jdtls is installed via Mason
      local mason_registry = require("mason-registry")
      if not mason_registry.is_installed("jdtls") then
        vim.cmd("MasonInstall jdtls")
      end
      if not mason_registry.is_installed("java-debug-adapter") then
        vim.cmd("MasonInstall java-debug-adapter")
      end
      if not mason_registry.is_installed("java-test") then
        vim.cmd("MasonInstall java-test")
      end
    end,
  },

  -- ── jdtls autocmd: start LSP when a .java file opens ────
  {
    "mfussenegger/nvim-jdtls",
    ft   = { "java" },
    -- The real configuration is in the autocmd below
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern  = "java",
        callback = function()
          local jdtls      = require("jdtls")
          local mason_path = vim.fn.stdpath("data") .. "/mason"

          -- ── Paths ───────────────────────────────────────
          local jdtls_path   = mason_path .. "/packages/jdtls"
          local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
          local os_config    = vim.fn.has("mac") == 1 and "mac"
                            or vim.fn.has("win32") == 1 and "win"
                            or "linux"
          local config_dir   = jdtls_path .. "/config_" .. os_config

          -- Project-specific workspace (keeps each project isolated)
          local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
          local workspace    = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

          -- Java debug adapter
          local bundles = {}
          local debug_jar = vim.fn.glob(
            mason_path .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
          )
          if debug_jar ~= "" then
            vim.list_extend(bundles, { debug_jar })
          end
          -- Java test adapter
          vim.list_extend(bundles, vim.split(
            vim.fn.glob(mason_path .. "/packages/java-test/extension/server/*.jar"),
            "\n", { trimempty = true }
          ))

          -- ── JDTLS config ────────────────────────────────
          local config = {
            cmd = {
              "java",
              "-Declipse.application=org.eclipse.jdt.ls.core.id1",
              "-Dosgi.bundles.defaultStartLevel=4",
              "-Declipse.product=org.eclipse.jdt.ls.core.product",
              "-Dlog.level=ALL",
              "-noverify",
              "-Xmx2G",
              "--add-modules=ALL-SYSTEM",
              "--add-opens", "java.base/java.util=ALL-UNNAMED",
              "--add-opens", "java.base/java.lang=ALL-UNNAMED",
              "-jar", launcher_jar,
              "-configuration", config_dir,
              "-data", workspace,
            },
            root_dir = jdtls.setup.find_root({
              ".git", "mvnw", "gradlew", "pom.xml", "build.gradle",
            }),
            settings = {
              java = {
                eclipse      = { downloadSources = true },
                configuration = { updateBuildConfiguration = "interactive" },
                maven        = { downloadSources = true },
                implementationsCodeLens = { enabled = true },
                referencesCodeLens      = { enabled = true },
                format = {
                  enabled  = true,
                  settings = {
                    url    = vim.fn.stdpath("config") .. "/lang-settings/java-google-style.xml",
                    profile = "GoogleStyle",
                  },
                },
                signatureHelp = { enabled = true },
                contentProvider = { preferred = "fernflower" },
                completion = {
                  favoriteStaticMembers = {
                    "org.junit.Assert.*", "org.junit.jupiter.api.Assertions.*",
                    "java.util.Objects.requireNonNull",
                    "org.mockito.Mockito.*",
                  },
                },
                sources = {
                  organizeImports = {
                    starThreshold         = 9999,
                    staticStarThreshold   = 9999,
                  },
                },
                codeGeneration = {
                  toString  = { template = "${object.className}{${member.name()}=${member.value}, }" },
                  useBlocks = true,
                },
              },
            },

            init_options = {
              bundles = bundles,
            },

            on_attach = function(client, bufnr)
              -- Enable DAP
              jdtls.setup_dap({ hotcodereplace = "auto" })
              jdtls.setup.add_commands()

              -- Java-specific keymaps
              local map = function(k, f, desc)
                vim.keymap.set("n", k, f, { buffer = bufnr, desc = desc })
              end
              map("<leader>jo",  jdtls.organize_imports,          "Organize imports")
              map("<leader>jv",  jdtls.extract_variable,          "Extract variable")
              map("<leader>jc",  jdtls.extract_constant,          "Extract constant")
              map("<leader>jt",  jdtls.test_nearest_method,       "Test nearest method")
              map("<leader>jT",  jdtls.test_class,                "Test class")
              map("<leader>ju",  "<cmd>JdtUpdateConfig<CR>",       "Update config")
              vim.keymap.set("v", "<leader>jm", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
                { buffer = bufnr, desc = "Extract method" })
            end,
          }

          jdtls.start_or_attach(config)
        end,
      })
    end,
  },
}
