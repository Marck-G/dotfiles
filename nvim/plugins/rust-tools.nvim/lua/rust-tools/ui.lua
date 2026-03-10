-- ============================================================
--  rust-tools/ui.lua  ·  Input prompts, menus, pickers
--  Uses vim.ui.input / vim.ui.select (works with telescope,
--  dressing.nvim or native)
-- ============================================================

local M = {}

-- ── Simple input prompt ───────────────────────────────────
function M.input(prompt, default, callback)
  vim.ui.input({
    prompt  = "🦀 " .. prompt .. ": ",
    default = default or "",
  }, function(value)
    if value and value ~= "" then
      callback(value)
    end
  end)
end

-- ── Select from a list ────────────────────────────────────
function M.select(prompt, items, callback, opts)
  opts = opts or {}
  vim.ui.select(items, {
    prompt        = "🦀 " .. prompt,
    format_item   = opts.format_item or function(item) return item end,
  }, function(choice)
    if choice then callback(choice) end
  end)
end

-- ── Confirm yes/no ────────────────────────────────────────
function M.confirm(prompt, callback)
  vim.ui.select({ "Yes", "No" }, {
    prompt = "🦀 " .. prompt,
  }, function(choice)
    callback(choice == "Yes")
  end)
end

-- ── Multi-step form (sequential inputs) ───────────────────
-- fields = { { key="name", prompt="Project name", default="my-app" }, ... }
-- callback receives a table of { key = value }
function M.form(fields, callback)
  local results = {}
  local idx     = 1

  local function next_field()
    if idx > #fields then
      callback(results)
      return
    end

    local field = fields[idx]
    idx = idx + 1

    if field.type == "select" then
      vim.ui.select(field.items, {
        prompt      = "🦀 " .. field.prompt,
        format_item = field.format_item,
      }, function(choice)
        if choice == nil then return end  -- user cancelled
        results[field.key] = choice
        vim.schedule(next_field)
      end)
    elseif field.type == "confirm" then
      vim.ui.select({ "Yes", "No" }, {
        prompt = "🦀 " .. field.prompt,
      }, function(choice)
        if choice == nil then return end
        results[field.key] = (choice == "Yes")
        vim.schedule(next_field)
      end)
    else
      vim.ui.input({
        prompt      = "🦀 " .. field.prompt .. ": ",
        default     = field.default or "",
        completion  = field.completion,
      }, function(value)
        if value == nil then return end  -- user cancelled
        results[field.key] = value
        vim.schedule(next_field)
      end)
    end
  end

  next_field()
end

-- ── Notification helpers ──────────────────────────────────
function M.info(msg)    vim.notify("🦀 " .. msg, vim.log.levels.INFO)  end
function M.warn(msg)    vim.notify("🦀 " .. msg, vim.log.levels.WARN)  end
function M.error(msg)   vim.notify("🦀 " .. msg, vim.log.levels.ERROR) end
function M.success(msg) vim.notify("✅ " .. msg, vim.log.levels.INFO)  end

return M
