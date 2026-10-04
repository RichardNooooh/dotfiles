local candidate = assert(vim.env.NOTEBOOK_CANDIDATE, "NOTEBOOK_CANDIDATE is required")
local mode = assert(vim.env.NOTEBOOK_PROBE_MODE, "NOTEBOOK_PROBE_MODE is required")
local workdir = assert(vim.env.NOTEBOOK_WORKDIR, "NOTEBOOK_WORKDIR is required")
local shared_python = assert(vim.env.NOTEBOOK_SHARED_PYTHON, "NOTEBOOK_SHARED_PYTHON is required")

local function fail(message)
  vim.api.nvim_err_writeln("notebook probe: " .. message)
  vim.cmd("cquit 1")
end

local function wait_for(label, predicate)
  if not vim.wait(20_000, predicate, 50) then
    fail("timed out waiting for " .. label)
  end
end

local function write_and_quit()
  local ok, error_message = pcall(vim.cmd, "write")
  if not ok then fail("write failed: " .. tostring(error_message)) end
  vim.cmd("qa!")
end

local function has_expected_environment_output(outputs)
  local output = vim.inspect(outputs)
  return output:find("python executable: " .. shared_python, 1, true)
    and output:find("pandas version: 2.3.2", 1, true)
end

local function edit_probe()
  -- jupynvim makes its rendered buffer non-modifiable until interactive
  -- editing begins. The probe enables the same buffer briefly and verifies
  -- its normal write handler persists the edit.
  vim.bo.modifiable = true
  local target
  for index, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line == "import sys" then target = index break end
  end
  if not target then fail("could not locate environment-report source for persisted edit") end
  local ok, error_message = pcall(vim.api.nvim_buf_set_lines, 0, target, target, false, {
    "# notebook trial persisted edit",
  })
  if not ok then fail("could not apply persisted edit: " .. tostring(error_message)) end
  write_and_quit()
end

if candidate == "jupynvim" then
  local api = require("jupynvim")
  local notebook_api = require("jupynvim.notebook")
  wait_for("jupynvim notebook buffer", function()
    local value = notebook_api.get(0)
    return value and value.session_id ~= nil
  end)
  local notebook = notebook_api.get(0)
  wait_for("jupynvim kernel", function()
    return notebook.kernel_started or notebook.kernel_error ~= nil
  end)
  if notebook.kernel_error then fail("kernel start failed: " .. notebook.kernel_error) end

  if mode == "strict" then
    write_and_quit()
  elseif mode == "edit" then
    edit_probe()
  elseif mode == "reopen" then
    local cell = notebook:get_cell("environment-report")
    if not cell or not has_expected_environment_output(cell.outputs) then
      fail("saved environment-report output is missing the shared interpreter or pandas report after reopen")
    end
    vim.cmd("qa!")
  elseif mode == "execute" then
    local _, ranges = notebook:to_lines()
    local target
    for _, range in ipairs(ranges) do
      if range.id == "environment-report" then target = range break end
    end
    if not target then fail("environment-report cell is missing") end
    vim.api.nvim_win_set_cursor(0, { target.start + 1, 0 })
    api.run_cell(0, { advance = false })
    local cell = notebook:get_cell("environment-report")
    wait_for("jupynvim environment-report output", function()
      for _, output in ipairs(cell.outputs or {}) do
        if tostring(output.text or ""):find("python executable:", 1, true) then return true end
      end
      return false
    end)
    write_and_quit()
  else
    fail("unknown jupynvim probe mode: " .. mode)
  end
elseif candidate == "molten-jupytext" then
  local initialized = false
  vim.api.nvim_create_autocmd("User", {
    pattern = "MoltenInitPost",
    once = true,
    callback = function() initialized = true end,
  })
  local ok, error_message = pcall(vim.cmd, "MoltenInit python3")
  if not ok then fail("MoltenInit failed: " .. tostring(error_message)) end
  wait_for("MoltenInitPost", function() return initialized end)

  if mode == "strict" then
    write_and_quit()
  elseif mode == "edit" then
    edit_probe()
  elseif mode == "reopen" then
    local notebook = vim.fn.expand("%:p")
    ok, error_message = pcall(vim.cmd, "MoltenImportOutput " .. vim.fn.fnameescape(notebook))
    if not ok then fail("MoltenImportOutput failed: " .. tostring(error_message)) end
    local state_path = workdir .. "/molten-reopen-output.json"
    ok, error_message = pcall(vim.cmd, "MoltenSave " .. vim.fn.fnameescape(state_path))
    if not ok then fail("MoltenSave after import failed: " .. tostring(error_message)) end
    local file = io.open(state_path, "r")
    if not file then fail("MoltenImportOutput did not create a readable saved state") end
    local contents = file:read("*a")
    file:close()
    if not contents:find("python executable: " .. shared_python, 1, true)
      or not contents:find("pandas version: 2.3.2", 1, true) then
      fail("imported environment-report output is missing the shared interpreter or pandas report: " .. contents)
    end
    vim.cmd("qa!")
  elseif mode == "execute" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local start_line
    local end_line
    for index, line in ipairs(lines) do
      if line:find("import sys", 1, true) then start_line = index end
      if start_line and line:find("pandas version:", 1, true) then end_line = index break end
    end
    if not start_line or not end_line then fail("could not locate environment-report source in Jupytext buffer") end
    -- MoltenInitPost precedes runtime readiness. Let its upstream timer poll
    -- the IOPub channel before submitting the test range.
    vim.wait(2_000, function() return false end, 50)
    local state_path = workdir .. "/molten-output.json"
    local next_snapshot_at = 0
    local last_snapshot = "no Molten state file"
    -- Supplying the known kernel ID avoids Molten's interactive/re-entrant
    -- kernel-selection path, which is unsuitable for a headless probe.
    local evaluated, evaluate_error = pcall(vim.fn.MoltenEvaluateRange, "python3", start_line, end_line)
    if not evaluated then fail("MoltenEvaluateRange failed: " .. tostring(evaluate_error)) end
    local observed = vim.wait(20_000, function()
      local now = vim.uv.hrtime()
      if now < next_snapshot_at then return false end
      next_snapshot_at = now + 1_000_000_000
      local notify = vim.notify
      vim.notify = function() end
      pcall(vim.cmd, "silent MoltenSave " .. vim.fn.fnameescape(state_path))
      vim.notify = notify
      local file = io.open(state_path, "r")
      if not file then return false end
      local contents = file:read("*a")
      file:close()
      last_snapshot = contents
      return contents:find("python executable:", 1, true) ~= nil
    end, 50)
    if not observed then
      fail("timed out waiting for Molten execution output; last state: " .. last_snapshot)
    end
    local notebook = vim.fn.expand("%:r") .. ".ipynb"
    ok, error_message = pcall(vim.cmd, "MoltenExportOutput! " .. vim.fn.fnameescape(notebook))
    if not ok then fail("MoltenExportOutput failed: " .. tostring(error_message)) end
    write_and_quit()
  else
    fail("unknown molten probe mode: " .. mode)
  end
else
  fail("unknown candidate: " .. candidate)
end
