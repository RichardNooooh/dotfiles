local M = {}

local function roots(context)
  return context.roots or { context.root }
end

local function exists(context, name)
  for _, root in ipairs(roots(context)) do
    if context.exists(root .. '/' .. name) then
      return true
    end
  end
  return false
end

local function contains(context, name, pattern)
  for _, root in ipairs(roots(context)) do
    local contents = context.read(root .. '/' .. name)
    if contents ~= nil and contents:find(pattern) ~= nil then
      return true
    end
  end
  return false
end

local function has_executable(context, command, local_paths)
  for _, root in ipairs(roots(context)) do
    for _, path in ipairs(local_paths or {}) do
      if context.executable(root .. '/' .. path) then
        return true
      end
    end
  end
  return context.executable(command)
end

local function has_local_executable(context, path)
  for _, root in ipairs(roots(context)) do
    if context.executable(root .. '/' .. path) then
      return true
    end
  end
  return false
end

local function hook_mentions(context, tool)
  for _, name in ipairs { '.pre-commit-config.yaml', '.pre-commit-config.yml', '.lefthook.yml', 'lefthook.yml', '.githooks/pre-commit' } do
    if contains(context, name, tool) then
      return true
    end
  end
  return false
end

local function stylua_enabled(context)
  for _, name in ipairs { '.stylua.toml', 'stylua.toml', '.stylua.yaml', '.stylua.yml' } do
    if exists(context, name) then
      return true
    end
  end
  return hook_mentions(context, 'stylua')
end

local function ruff_enabled(context)
  return exists(context, 'ruff.toml') or exists(context, '.ruff.toml') or contains(context, 'pyproject.toml', '%[tool%.ruff%]')
end

local function prettier_enabled(context)
  for _, name in ipairs {
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.yaml',
    '.prettierrc.yml',
    '.prettierrc.js',
    '.prettierrc.cjs',
    'prettier.config.js',
    'prettier.config.cjs',
    'prettier.config.mjs',
  } do
    if exists(context, name) then
      return true
    end
  end
  return contains(context, 'package.json', '"prettier"%s*:')
end

local function sqlfluff_enabled(context)
  return exists(context, '.sqlfluff')
    or exists(context, 'setup.cfg') and contains(context, 'setup.cfg', '%[sqlfluff%]')
    or contains(context, 'pyproject.toml', '%[tool%.sqlfluff%]')
end

local function ansible_enabled(context)
  return exists(context, '.ansible-lint')
    or exists(context, '.ansible-lint.yml')
    or exists(context, '.ansible-lint.yaml')
    or hook_mentions(context, 'ansible%-lint')
end

local function extension(path)
  return path:match '%.([^.]+)$'
end

local function is_prettier_file(context)
  return ({ md = true, markdown = true, json = true, yaml = true, yml = true, js = true, jsx = true, ts = true, tsx = true, css = true, html = true })[extension(
    context.path
  )] == true
end

function M.save_formatters(context)
  local formatter = nil
  local ext = extension(context.path)

  if ext == 'lua' and stylua_enabled(context) and has_executable(context, 'stylua') then
    formatter = 'stylua'
  elseif ext == 'py' and ruff_enabled(context) and has_executable(context, 'ruff', { '.venv/bin/ruff', 'venv/bin/ruff' }) then
    formatter = 'ruff_format'
  elseif ext == 'go' and (exists(context, 'go.mod') or exists(context, 'go.work')) and has_executable(context, 'gofmt') then
    formatter = 'gofmt'
  elseif is_prettier_file(context) and prettier_enabled(context) and has_local_executable(context, 'node_modules/.bin/prettier') then
    formatter = 'prettier'
  end

  return formatter and { formatter } or {}
end

function M.manual_formatters(context)
  local formatters = M.save_formatters(context)
  local ext = extension(context.path)

  if ext == 'py' and ruff_enabled(context) and has_executable(context, 'ruff', { '.venv/bin/ruff', 'venv/bin/ruff' }) then
    return { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' }
  end
  if ext == 'sql' and sqlfluff_enabled(context) and has_executable(context, 'sqlfluff', { '.venv/bin/sqlfluff', 'venv/bin/sqlfluff' }) then
    return { 'sqlfluff' }
  end
  if
    context.filetype == 'yaml.ansible'
    and ansible_enabled(context)
    and has_executable(context, 'ansible-lint', { '.venv/bin/ansible-lint', 'venv/bin/ansible-lint' })
  then
    return { 'ansible_lint' }
  end
  return formatters
end

function M.context(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local git_root = vim.fs.root(path, { '.git' })
  if not git_root then
    return nil
  end

  local ancestors = {}
  local directory = vim.fs.dirname(path)
  while directory and directory:sub(1, #git_root) == git_root do
    ancestors[#ancestors + 1] = directory
    if directory == git_root then
      break
    end
    directory = vim.fs.dirname(directory)
  end

  return {
    path = path,
    root = git_root,
    roots = ancestors,
    filetype = vim.bo[bufnr].filetype,
    exists = function(name)
      return vim.uv.fs_stat(name) ~= nil
    end,
    read = function(name)
      if vim.fn.filereadable(name) ~= 1 then
        return nil
      end
      return table.concat(vim.fn.readfile(name), '\n')
    end,
    executable = function(command)
      return vim.fn.executable(command) == 1
    end,
  }
end

return M
