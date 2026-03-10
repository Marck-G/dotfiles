-- ============================================================
--  rust-tools/commands.lua  ·  All :Rust* commands + keymaps
-- ============================================================

local M = {}

-- ── Lazy-load everything to avoid circular require issues ─
-- Do NOT require at module top-level — call inside functions
local function ui()     return require("rust-tools.ui")      end
local function term()   return require("rust-tools.terminal") end
local function cfg()    return require("rust-tools.config").get() end

-- ── Resolve python scripts dir at call time (not load time)─
local function python_dir()
  -- Try runtime path first
  local hits = vim.api.nvim_get_runtime_file("lua/rust-tools/init.lua", false)
  if hits and #hits > 0 then
    return vim.fn.fnamemodify(hits[1], ":h:h:h") .. "/python"
  end
  -- Fallback: relative to stdpath config
  return vim.fn.stdpath("config") .. "/plugins/rust-tools.nvim/python"
end

local function python_script(name)
  return python_dir() .. "/" .. name
end

local function python_cmd()
  return cfg().python or "python3"
end

-- ── Run a python helper and return decoded JSON ────────────
local function run_python(script, args, callback)
  local cmd = python_cmd() .. " " .. vim.fn.shellescape(python_script(script))
  for k, v in pairs(args) do
    if type(v) == "boolean" then
      if v then cmd = cmd .. " --" .. k end
    else
      cmd = cmd .. " --" .. k .. " " .. vim.fn.shellescape(tostring(v))
    end
  end
  cmd = cmd .. " --json"

  local output = vim.fn.system(cmd)
  local ok, result = pcall(vim.json.decode, output)

  if not ok then
    ui().error("Python script error:\n" .. output)
    return nil
  end

  if callback then callback(result) end
  return result
end

-- ─────────────────────────────────────────────────────────
--  COMMAND IMPLEMENTATIONS
-- ─────────────────────────────────────────────────────────

-- ── 1. New Project ────────────────────────────────────────
local function cmd_new_project()
  local config = cfg()

  ui().form({
    { key = "name",     prompt = "Project name",    default = "my-project" },
    { key = "type",     prompt = "Project type",    type = "select",
      items = { "bin", "lib" } },
    { key = "template", prompt = "Template",        type = "select",
      items = { "empty", "cli", "web", "lib" } },
    { key = "path",     prompt = "Parent directory",
      default     = config.projects_dir or vim.fn.expand("~"),
      completion  = "dir" },
    { key = "edition",  prompt = "Rust edition",    type = "select",
      items = { "2021", "2018", "2015" } },
  }, function(answers)
    ui().info("Creating project '" .. answers.name .. "'...")

    run_python("rust_new_project.py", {
      name     = answers.name,
      type     = answers.type,
      path     = answers.path,
      template = answers.template,
      edition  = answers.edition,
    }, function(result)
      if result.success then
        ui().success("Project created at " .. result.path)
        if config.open_in_tree then
          vim.schedule(function()
            vim.cmd("cd " .. vim.fn.fnameescape(result.path))
            local ok, ntree = pcall(require, "nvim-tree.api")
            if ok then ntree.tree.open() end
            local main_file = result.path .. "/src/" ..
              (answers.type == "bin" and "main.rs" or "lib.rs")
            vim.cmd("edit " .. vim.fn.fnameescape(main_file))
          end)
        end
      else
        ui().error(result.error or "Failed to create project")
      end
    end)
  end)
end

-- ── 2. Run ────────────────────────────────────────────────
local function cmd_run(extra_args)
  local root     = term().find_cargo_root()
  local config   = cfg()
  local profile  = config.run_profile or "debug"
  local features = config.features or {}

  local cmd = "cargo run"
  if profile == "release" then cmd = cmd .. " --release" end
  if #features > 0 then
    cmd = cmd .. " --features " .. table.concat(features, ",")
  end
  if extra_args and extra_args ~= "" then
    cmd = cmd .. " -- " .. extra_args
  end

  term().run(cmd, { title = "cargo run", cwd = root })
end

local function cmd_run_with_args()
  ui().input("Run arguments (after --)", "", function(args)
    cmd_run(args)
  end)
end

-- ── 3. Build Debug ────────────────────────────────────────
local function cmd_build_debug()
  local root     = term().find_cargo_root()
  local features = cfg().features or {}
  local cmd      = "cargo build"
  if #features > 0 then
    cmd = cmd .. " --features " .. table.concat(features, ",")
  end
  term().run_async(cmd, { title = "cargo build (debug)", cwd = root })
end

-- ── 4. Build Release ──────────────────────────────────────
local function cmd_build_release()
  local root     = term().find_cargo_root()
  local features = cfg().features or {}
  local cmd      = "cargo build --release"
  if #features > 0 then
    cmd = cmd .. " --features " .. table.concat(features, ",")
  end
  ui().info("Building release (this may take a while)...")
  term().run_async(cmd, {
    title      = "cargo build --release",
    cwd        = root,
    on_success = function()
      local name = term().get_project_name(root)
      ui().success("Release binary ready: target/release/" .. (name or "app"))
    end,
  })
end

-- ── 5. Run Tests ──────────────────────────────────────────
local function cmd_test(filter)
  local root = term().find_cargo_root()
  local cmd  = "cargo test"
  if filter and filter ~= "" then
    cmd = cmd .. " " .. vim.fn.shellescape(filter)
  end
  cmd = cmd .. " -- --nocapture"
  term().run(cmd, { title = "cargo test", cwd = root })
end

local function cmd_test_current()
  local node = vim.treesitter.get_node()
  local test_name = nil

  while node do
    if node:type() == "function_item" then
      for child in node:iter_children() do
        if child:type() == "identifier" then
          test_name = vim.treesitter.get_node_text(child, 0)
          break
        end
      end
      break
    end
    node = node:parent()
  end

  if test_name then
    ui().info("Running test: " .. test_name)
    cmd_test(test_name)
  else
    ui().input("Test filter (empty = all)", "", function(filter)
      cmd_test(filter ~= "" and filter or nil)
    end)
  end
end

-- ── 6. Cargo Check ────────────────────────────────────────
local function cmd_check()
  local root = term().find_cargo_root()
  term().run_async("cargo check --all-targets", {
    title = "cargo check", cwd = root,
  })
end

-- ── 7. Clippy ─────────────────────────────────────────────
local function cmd_clippy()
  local root = term().find_cargo_root()
  term().run_async("cargo clippy --all-targets --all-features -- -D warnings", {
    title = "cargo clippy", cwd = root,
  })
end

-- ── 8. Add Dependency ─────────────────────────────────────
local function cmd_add_dep()
  local root       = term().find_cargo_root()
  local cargo_toml = root .. "/Cargo.toml"

  ui().input("Crate name (or search term)", "", function(name)
    ui().info("Searching crates.io for '" .. name .. "'...")

    local results = run_python("rust_add_dep.py", {
      crate          = name,
      ["cargo-toml"] = cargo_toml,
      search         = true,
    })

    if not results or #results == 0 then
      ui().confirm("Crate '" .. name .. "' not found. Add directly?", function(yes)
        if yes then
          run_python("rust_add_dep.py", {
            crate          = name,
            ["cargo-toml"] = cargo_toml,
          }, function(result)
            if result.success then
              ui().success("Added: " .. result.line)
              vim.fn.jobstart("cargo fetch", { cwd = root })
            else
              ui().error(result.error)
            end
          end)
        end
      end)
      return
    end

    local items = {}
    for _, r in ipairs(results) do
      table.insert(items,
        string.format("%-30s %-10s  %s", r.name, r.version, r.description)
      )
    end

    ui().select("Select crate", items, function(choice)
      local chosen_name = vim.trim(choice:match("^(%S+)"))

      ui().info("Fetching info for '" .. chosen_name .. "'...")
      local info = run_python("rust_add_dep.py", {
        crate          = chosen_name,
        ["cargo-toml"] = cargo_toml,
        info           = true,
      })

      if not info or info.error then
        ui().error("Could not get crate info")
        return
      end

      local dep_type         = "dependencies"
      local selected_features = {}

      local function do_add()
        run_python("rust_add_dep.py", {
          crate          = chosen_name,
          ["cargo-toml"] = cargo_toml,
          version        = info.version,
          features       = table.concat(selected_features, ","),
          dev            = dep_type == "dev-dependencies",
        }, function(result)
          if result.success then
            ui().success("Added: " .. result.line)
            -- Reload any open Cargo.toml buffers
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_get_name(buf):match("Cargo%.toml$") then
                vim.api.nvim_buf_call(buf, function() vim.cmd("edit!") end)
              end
            end
            vim.fn.jobstart("cargo fetch", { cwd = root })
          else
            ui().error(result.error)
          end
        end)
      end

      ui().select("Dependency type", { "dependencies", "dev-dependencies" }, function(dt)
        dep_type = dt
        if not info.features or #info.features == 0 then
          do_add()
          return
        end

        ui().confirm(
          "'" .. chosen_name .. "' has features: " ..
          table.concat(info.features, ", ") .. "\nAdd specific features?",
          function(want_features)
            if not want_features then
              do_add()
              return
            end
            ui().input(
              "Features (comma-separated) — available: " ..
              table.concat(info.features, ", "),
              "", function(feat_str)
                for _, f in ipairs(vim.split(feat_str, ",", { trimempty = true })) do
                  table.insert(selected_features, vim.trim(f))
                end
                do_add()
              end
            )
          end
        )
      end)
    end)
  end)
end

-- ── 9. New Module ─────────────────────────────────────────
local function cmd_new_module(is_dir)
  local root = term().find_cargo_root()
  if not root then ui().error("No Cargo.toml found"); return end

  local src            = root .. "/src"
  local default_parent = vim.fn.filereadable(src .. "/lib.rs") == 1 and "lib" or "main"

  ui().form({
    { key = "name",       prompt = "Module name (snake_case)", default = "my_module" },
    { key = "parent",     prompt = "Parent module",            default = default_parent },
    { key = "visibility", prompt = "Visibility",               type = "select",
      items = { "pub", "pub(crate)", "private" } },
  }, function(answers)
    run_python("rust_new_module.py", {
      name       = answers.name,
      src        = src,
      type       = is_dir and "dir" or "file",
      parent     = answers.parent,
      visibility = answers.visibility,
    }, function(result)
      if result.success then
        ui().success("Created module '" .. result.module_name .. "'")
        vim.schedule(function()
          vim.cmd("edit " .. vim.fn.fnameescape(result.main_file))
        end)
        if result.injected_into then
          ui().info("Added `mod " .. result.module_name .. ";` to " ..
            vim.fn.fnamemodify(result.injected_into, ":t"))
        end
      else
        ui().error(result.error)
      end
    end)
  end)
end

-- ── 10. Open Cargo.toml ───────────────────────────────────
local function cmd_open_cargo()
  local root = term().find_cargo_root()
  local toml = root .. "/Cargo.toml"
  if vim.fn.filereadable(toml) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(toml))
  else
    ui().error("Cargo.toml not found")
  end
end

-- ── 11. Cargo Doc ─────────────────────────────────────────
local function cmd_doc(open_browser)
  local root = term().find_cargo_root()
  local cmd  = "cargo doc --no-deps" .. (open_browser and " --open" or "")
  term().run_async(cmd, { title = "cargo doc", cwd = root })
end

-- ── 12. Cargo Clean ───────────────────────────────────────
local function cmd_clean()
  local root = term().find_cargo_root()
  ui().confirm("Clean build artifacts? (target/ will be deleted)", function(yes)
    if yes then
      term().run_async("cargo clean", { title = "cargo clean", cwd = root })
    end
  end)
end

-- ── 13. Cargo Fmt ─────────────────────────────────────────
local function cmd_fmt()
  local root = term().find_cargo_root()
  term().run_async("cargo fmt --all", {
    title      = "cargo fmt",
    cwd        = root,
    on_success = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):match("%.rs$") then
          vim.api.nvim_buf_call(buf, function() vim.cmd("checktime") end)
        end
      end
    end,
  })
end

-- ── 14. Cargo Bench ───────────────────────────────────────
local function cmd_bench(filter)
  local root = term().find_cargo_root()
  local cmd  = "cargo bench"
  if filter and filter ~= "" then
    cmd = cmd .. " " .. vim.fn.shellescape(filter)
  end
  term().run(cmd, { title = "cargo bench", cwd = root })
end

-- ── 15. Update Dependencies ───────────────────────────────
local function cmd_update_deps()
  local root = term().find_cargo_root()
  ui().confirm("Update all dependencies (cargo update)?", function(yes)
    if yes then
      term().run_async("cargo update", { title = "cargo update", cwd = root })
    end
  end)
end

-- ── 16. Features Menu ─────────────────────────────────────
local function cmd_features_menu()
  local root       = term().find_cargo_root()
  local cargo_toml = root .. "/Cargo.toml"
  local features   = {}
  local in_feat    = false

  if vim.fn.filereadable(cargo_toml) == 1 then
    for line in io.lines(cargo_toml) do
      if line:match("^%[features%]") then
        in_feat = true
      elseif line:match("^%[") then
        in_feat = false
      elseif in_feat then
        local feat = line:match("^([%w_%-]+)%s*=")
        if feat and feat ~= "default" then
          table.insert(features, feat)
        end
      end
    end
  end

  if #features == 0 then
    ui().info("No features defined in Cargo.toml")
    return
  end

  local current = cfg().features or {}
  local choices = {}
  for _, f in ipairs(features) do
    table.insert(choices, (vim.tbl_contains(current, f) and "✓ " or "  ") .. f)
  end

  ui().select("Toggle features", choices, function(choice)
    local feat = vim.trim(choice:gsub("^[✓ ] ", ""))
    local opts = require("rust-tools.config").options
    if vim.tbl_contains(opts.features, feat) then
      opts.features = vim.tbl_filter(function(f) return f ~= feat end, opts.features)
      ui().info("Disabled feature: " .. feat)
    else
      table.insert(opts.features, feat)
      ui().info("Enabled feature: " .. feat)
    end
  end)
end

-- ── 17. Dependency Tree ───────────────────────────────────
local function cmd_dep_tree()
  local root = term().find_cargo_root()
  term().run("cargo tree", { title = "cargo tree", cwd = root })
end

-- ── 18. Cargo Audit ───────────────────────────────────────
local function cmd_audit()
  local root = term().find_cargo_root()
  if vim.fn.executable("cargo-audit") == 0 then
    ui().confirm("cargo-audit not found. Install it?", function(yes)
      if yes then
        term().run("cargo install cargo-audit", { title = "Installing cargo-audit" })
      end
    end)
    return
  end
  term().run("cargo audit", { title = "cargo audit", cwd = root })
end

-- ── 19. Cargo Watch ───────────────────────────────────────
local function cmd_watch(mode)
  local root  = term().find_cargo_root()
  local modes = {
    check  = "cargo watch -x check",
    test   = "cargo watch -x test",
    run    = "cargo watch -x run",
    clippy = "cargo watch -x 'clippy -- -D warnings'",
  }

  if vim.fn.executable("cargo-watch") == 0 then
    ui().confirm("cargo-watch not found. Install it?", function(yes)
      if yes then
        term().run("cargo install cargo-watch", { title = "Installing cargo-watch" })
      end
    end)
    return
  end

  if mode and modes[mode] then
    term().run(modes[mode], { title = "cargo watch (" .. mode .. ")", cwd = root })
  else
    ui().select("Watch mode", { "check", "test", "run", "clippy" }, function(choice)
      term().run(modes[choice], { title = "cargo watch (" .. choice .. ")", cwd = root })
    end)
  end
end

-- ─────────────────────────────────────────────────────────
--  REGISTER ALL COMMANDS + KEYMAPS
-- ─────────────────────────────────────────────────────────

function M.register()
  local km = cfg().keymaps or {}

  -- Helper: register a vim user command + optional global keymap
  local function cmd(name, fn, desc, key)
    vim.api.nvim_create_user_command(name, function(opts)
      fn(opts.args ~= "" and opts.args or nil)
    end, { nargs = "?", desc = desc })

    if key and key ~= false then
      vim.keymap.set("n", key, fn, { desc = desc })
    end
  end

  cmd("RustNewProject",   cmd_new_project,                      "Create new Rust project",       km.new_project)
  cmd("RustRun",          cmd_run,                              "Run current project",           km.run)
  cmd("RustRunArgs",      cmd_run_with_args,                    "Run with custom arguments",     false)
  cmd("RustBuild",        cmd_build_debug,                      "Build debug",                   km.build_debug)
  cmd("RustBuildRelease", cmd_build_release,                    "Build release",                 km.build_release)
  cmd("RustTest",         cmd_test,                             "Run tests",                     km.test)
  cmd("RustTestCurrent",  cmd_test_current,                     "Run test under cursor",         km.test_current)
  cmd("RustCheck",        cmd_check,                            "Cargo check",                   km.check)
  cmd("RustClippy",       cmd_clippy,                           "Run clippy",                    km.clippy)
  cmd("RustAddDep",       cmd_add_dep,                          "Add dependency",                km.add_dep)
  cmd("RustNewModule",    function() cmd_new_module(false) end, "New module (file)",             km.new_module)
  cmd("RustNewModuleDir", function() cmd_new_module(true) end,  "New module (directory)",        km.new_mod_dir)
  cmd("RustOpenCargo",    cmd_open_cargo,                       "Open Cargo.toml",               km.open_cargo)
  cmd("RustDoc",          function() cmd_doc(false) end,        "Generate docs",                 km.doc)
  cmd("RustDocOpen",      function() cmd_doc(true) end,         "Generate and open docs",        false)
  cmd("RustClean",        cmd_clean,                            "Clean build artifacts",         km.clean)
  cmd("RustFmt",          cmd_fmt,                              "Format all files",              km.fmt)
  cmd("RustBench",        cmd_bench,                            "Run benchmarks",                km.bench)
  cmd("RustUpdateDeps",   cmd_update_deps,                      "Update dependencies",           km.update_deps)
  cmd("RustFeatures",     cmd_features_menu,                    "Toggle features",               km.features_menu)
  cmd("RustTree",         cmd_dep_tree,                         "Dependency tree",               km.tree)
  cmd("RustAudit",        cmd_audit,                            "Security audit",                false)
  cmd("RustWatch",        cmd_watch,                            "Watch mode",                    false)

  -- ── Buffer-local keymaps: only active in .rs files ────
  vim.api.nvim_create_autocmd("FileType", {
    pattern  = "rust",
    group    = vim.api.nvim_create_augroup("RustToolsFiletype", { clear = true }),
    callback = function()
      local b = { buffer = true }
      local function bmap(key, fn, desc)
        if key and key ~= false then
          vim.keymap.set("n", key, fn, { buffer = true, desc = desc })
        end
      end
      bmap(km.run,           cmd_run,                              "Rust: Run project")
      bmap(km.build_debug,   cmd_build_debug,                      "Rust: Build debug")
      bmap(km.build_release, cmd_build_release,                    "Rust: Build release")
      bmap(km.test,          cmd_test,                             "Rust: Run tests")
      bmap(km.test_current,  cmd_test_current,                     "Rust: Test under cursor")
      bmap(km.check,         cmd_check,                            "Rust: Cargo check")
      bmap(km.clippy,        cmd_clippy,                           "Rust: Clippy")
      bmap(km.add_dep,       cmd_add_dep,                          "Rust: Add dependency")
      bmap(km.new_module,    function() cmd_new_module(false) end, "Rust: New module (file)")
      bmap(km.new_mod_dir,   function() cmd_new_module(true) end,  "Rust: New module (dir)")
      bmap(km.open_cargo,    cmd_open_cargo,                       "Rust: Open Cargo.toml")
      bmap(km.doc,           function() cmd_doc(false) end,        "Rust: Generate docs")
      bmap(km.clean,         cmd_clean,                            "Rust: Clean")
      bmap(km.fmt,           cmd_fmt,                              "Rust: Format")
      bmap(km.bench,         cmd_bench,                            "Rust: Bench")
      bmap(km.update_deps,   cmd_update_deps,                      "Rust: Update deps")
      bmap(km.features_menu, cmd_features_menu,                    "Rust: Features menu")
      bmap(km.tree,          cmd_dep_tree,                         "Rust: Dep tree")
    end,
  })
end

return M
