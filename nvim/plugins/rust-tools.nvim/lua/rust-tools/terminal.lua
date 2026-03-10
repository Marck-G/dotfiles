-- ============================================================
--  rust-tools/terminal.lua  ·  Floating / split terminal
--  Handles running cargo commands with nice output windows
-- ============================================================

local M = {}
local config = require("rust-tools.config")

-- Track open terminal buffers
local term_buf  = nil
local term_win  = nil
local term_chan = nil

-- ── Create a floating window ──────────────────────────────
local function make_float(title)
  local cfg    = config.get().float_term
  local width  = math.floor(vim.o.columns * cfg.width)
  local height = math.floor(vim.o.lines   * cfg.height)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width    = width,
    height   = height,
    row      = row,
    col      = col,
    style    = "minimal",
    border   = cfg.border,
    title    = " " .. (title or cfg.title) .. " ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, "winblend", 5)
  return buf, win
end

-- ── Run a command in a floating terminal ──────────────────
function M.run(cmd, opts)
  opts = opts or {}
  local title = opts.title or "🦀 Cargo"
  local cwd   = opts.cwd   or M.find_cargo_root() or vim.fn.getcwd()

  -- Close previous terminal if still open
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
  end

  local mode = config.get().terminal

  if mode == "float" then
    term_buf, term_win = make_float(title)
  elseif mode == "split" then
    vim.cmd("botright 15split")
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
  elseif mode == "tab" then
    vim.cmd("tabnew")
    term_buf = vim.api.nvim_get_current_buf()
    term_win = vim.api.nvim_get_current_win()
  end

  -- Start terminal with the command
  term_chan = vim.fn.termopen(cmd, {
    cwd = cwd,
    on_exit = function(_, exit_code)
      if opts.on_exit then opts.on_exit(exit_code) end
      if exit_code == 0 then
        vim.notify("✅ " .. title .. " completed successfully", vim.log.levels.INFO)
      else
        vim.notify("❌ " .. title .. " failed (exit " .. exit_code .. ")", vim.log.levels.ERROR)
      end
    end,
  })

  -- Auto-enter insert mode so user can interact if needed
  vim.cmd("startinsert")

  -- Keymaps inside terminal: q or <Esc> to close
  vim.keymap.set("t", "q", function()
    if term_win and vim.api.nvim_win_is_valid(term_win) then
      vim.api.nvim_win_close(term_win, true)
    end
  end, { buffer = term_buf, desc = "Close terminal" })

  vim.keymap.set("t", "<Esc>", function()
    vim.cmd("stopinsert")
  end, { buffer = term_buf, desc = "Exit insert mode" })

  return term_buf, term_win
end

-- ── Run async (output goes to quickfix) ───────────────────
function M.run_async(cmd, opts)
  opts = opts or {}
  local title = opts.title or "Cargo"
  local cwd   = opts.cwd   or M.find_cargo_root() or vim.fn.getcwd()

  vim.notify("⏳ Running: " .. cmd, vim.log.levels.INFO)

  local output = {}
  local job_id = vim.fn.jobstart(cmd, {
    cwd      = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then vim.list_extend(output, data) end
    end,
    on_stderr = function(_, data)
      if data then vim.list_extend(output, data) end
    end,
    on_exit = function(_, exit_code)
      -- Populate quickfix with output
      local qf_items = {}
      for _, line in ipairs(output) do
        if line ~= "" then
          -- Try to parse rustc error format: "  --> src/main.rs:10:5"
          local file, lnum, col = line:match("%-%->`s*(.-)%:(%d+)%:(%d+)")
          if file then
            table.insert(qf_items, {
              filename = cwd .. "/" .. file,
              lnum     = tonumber(lnum),
              col      = tonumber(col),
              text     = line,
            })
          else
            table.insert(qf_items, { text = line })
          end
        end
      end

      vim.fn.setqflist({}, "r", { title = title, items = qf_items })

      if exit_code ~= 0 then
        vim.cmd("copen")
        vim.notify("❌ " .. title .. " failed", vim.log.levels.ERROR)
      else
        vim.notify("✅ " .. title .. " passed!", vim.log.levels.INFO)
        if opts.on_success then opts.on_success() end
      end
    end,
  })

  return job_id
end

-- ── Find the Cargo.toml root of the current project ───────
function M.find_cargo_root(start_path)
  local path = start_path or vim.fn.expand("%:p:h")

  -- Walk up from current file looking for Cargo.toml
  local root = vim.fs.find("Cargo.toml", {
    upward = true,
    path   = path,
    type   = "file",
  })

  if root and #root > 0 then
    return vim.fn.fnamemodify(root[1], ":h")
  end

  -- Fallback: check workspace Cargo.toml
  root = vim.fs.find("Cargo.toml", {
    upward = true,
    path   = vim.fn.getcwd(),
    type   = "file",
  })

  if root and #root > 0 then
    return vim.fn.fnamemodify(root[1], ":h")
  end

  return vim.fn.getcwd()
end

-- ── Get project name from Cargo.toml ──────────────────────
function M.get_project_name(root)
  root = root or M.find_cargo_root()
  local cargo_toml = root .. "/Cargo.toml"

  if vim.fn.filereadable(cargo_toml) == 0 then return nil end

  for line in io.lines(cargo_toml) do
    local name = line:match('^name%s*=%s*"(.-)"')
    if name then return name end
  end

  return vim.fn.fnamemodify(root, ":t")
end

-- ── Parse Cargo.toml dependencies ─────────────────────────
function M.get_dependencies(root)
  root = root or M.find_cargo_root()
  local cargo_toml = root .. "/Cargo.toml"
  if vim.fn.filereadable(cargo_toml) == 0 then return {} end

  local deps    = {}
  local in_deps = false

  for line in io.lines(cargo_toml) do
    if line:match("^%[dependencies%]") or line:match("^%[dev%-dependencies%]") then
      in_deps = true
    elseif line:match("^%[") then
      in_deps = false
    elseif in_deps then
      local name = line:match("^([%w_%-]+)%s*=")
      if name then table.insert(deps, name) end
    end
  end

  return deps
end

return M
