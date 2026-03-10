-- ============================================================
--  core/syscheck.lua  ·  Check system dependencies on startup
--  Shows a one-time warning if required tools are missing.
--  Run :SysCheck at any time to re-check.
-- ============================================================

local M = {}

-- ── Dependencies table ────────────────────────────────────
-- { bin, label, install_hint, required }
local DEPS = {
  -- ── Clipboard ─────────────────────────────────────────
  {
    check = function()
      return vim.env.WAYLAND_DISPLAY ~= nil and vim.fn.executable("wl-copy") == 1
          or vim.env.DISPLAY ~= nil
             and (vim.fn.executable("xclip") == 1 or vim.fn.executable("xsel") == 1)
          or vim.fn.has("mac") == 1
          or vim.fn.has("wsl") == 1
          or vim.env.TMUX ~= nil
    end,
    label   = "Clipboard provider",
    hint    = table.concat({
      "Install ONE of the following for your environment:",
      "  Wayland : sudo apt install wl-clipboard",
      "  X11     : sudo apt install xclip   (or xsel)",
      "  macOS   : built-in (pbcopy / pbpaste)",
      "  WSL     : install win32yank.exe and add to PATH",
      "  tmux    : already handled if $TMUX is set",
    }, "\n"),
    required = true,
  },

  -- ── Build tools ───────────────────────────────────────
  { bin = "git",    label = "git",       hint = "sudo apt install git",         required = true  },
  { bin = "make",   label = "make",      hint = "sudo apt install build-essential", required = true },
  { bin = "gcc",    label = "gcc / cc",  hint = "sudo apt install build-essential", required = true },

  -- ── Node / npm (LSP servers, prettier, markdown-preview) ──
  { bin = "node",   label = "Node.js",   hint = "https://nodejs.org  or: nvm install --lts", required = true  },
  { bin = "npm",    label = "npm",       hint = "comes with Node.js",           required = true  },

  -- ── Python (DAP, rust-tools scripts) ──────────────────
  { bin = "python3", label = "Python 3", hint = "sudo apt install python3",     required = true  },
  { bin = "pip3",    label = "pip3",     hint = "sudo apt install python3-pip", required = false },

  -- ── Rust toolchain ────────────────────────────────────
  { bin = "cargo",   label = "cargo",    hint = "curl https://sh.rustup.rs | sh", required = false },
  { bin = "rustc",   label = "rustc",    hint = "curl https://sh.rustup.rs | sh", required = false },

  -- ── Java ──────────────────────────────────────────────
  { bin = "java",    label = "Java JDK", hint = "sudo apt install openjdk-21-jdk", required = false },

  -- ── Clipboard (direct binaries) ───────────────────────
  { bin = "rg",      label = "ripgrep",  hint = "sudo apt install ripgrep  (telescope live_grep)", required = true },
  { bin = "fd",      label = "fd-find",  hint = "sudo apt install fd-find  (telescope find_files)", required = false },

  -- ── Optional but highly recommended ───────────────────
  { bin = "lazygit", label = "lazygit",  hint = "https://github.com/jesseduffield/lazygit#installation", required = false },
}

-- ── Run the check ─────────────────────────────────────────
function M.check()
  local missing_required = {}
  local missing_optional = {}

  for _, dep in ipairs(DEPS) do
    local ok
    if dep.check then
      ok = dep.check()
    else
      ok = vim.fn.executable(dep.bin) == 1
    end

    if not ok then
      if dep.required then
        table.insert(missing_required, dep)
      else
        table.insert(missing_optional, dep)
      end
    end
  end

  if #missing_required == 0 and #missing_optional == 0 then
    vim.notify("✅ All system dependencies found.", vim.log.levels.INFO)
    return
  end

  local lines = {}

  if #missing_required > 0 then
    table.insert(lines, "❌ MISSING REQUIRED dependencies:\n")
    for _, dep in ipairs(missing_required) do
      table.insert(lines, "  • " .. dep.label)
      table.insert(lines, "    " .. dep.hint)
    end
  end

  if #missing_optional > 0 then
    table.insert(lines, "\n⚠️  Missing optional dependencies:\n")
    for _, dep in ipairs(missing_optional) do
      table.insert(lines, "  • " .. dep.label)
      table.insert(lines, "    " .. dep.hint)
    end
  end

  table.insert(lines, "\nRun :SysCheck anytime to see this again.")

  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN, {
    title   = "🔧 System Dependencies",
    timeout = 10000,
  })
end

-- ── :SysCheck command ─────────────────────────────────────
function M.setup()
  vim.api.nvim_create_user_command("SysCheck", function()
    M.check()
  end, { desc = "Check system dependencies for Neovim IDE" })

  -- Run once on startup, but only if notify is ready (VimEnter)
  vim.api.nvim_create_autocmd("VimEnter", {
    once     = true,
    callback = function()
      -- Small delay so the dashboard loads first
      vim.defer_fn(M.check, 1500)
    end,
  })
end

return M
