vim.opt.autoread = true

local group = vim.api.nvim_create_augroup('custom-watch', { clear = true })
local uv = vim.uv or vim.loop
local timer = uv.new_timer()

local function is_watchable(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end

  if vim.bo[bufnr].buftype ~= '' or vim.bo[bufnr].modified then
    return false
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= '' and vim.fn.filereadable(name) == 1
end

local function check_buffer(bufnr)
  if not is_watchable(bufnr) then
    return
  end

  pcall(vim.cmd, ('checktime %d'):format(bufnr))
end

local function check_visible_buffers()
  local mode = vim.api.nvim_get_mode().mode
  if mode:match '^[iR]' or mode == 'c' then
    return
  end

  local seen = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if not seen[bufnr] then
      seen[bufnr] = true
      check_buffer(bufnr)
    end
  end
end

vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave', 'BufEnter' }, {
  group = group,
  callback = check_visible_buffers,
})

if timer then
  -- Poll visible buffers so tmux-side agent edits show up without focus changes.
  timer:start(1000, 1000, vim.schedule_wrap(check_visible_buffers))

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if timer:is_active() then
        timer:stop()
      end
      timer:close()
    end,
  })
end
