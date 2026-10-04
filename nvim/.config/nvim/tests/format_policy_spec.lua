package.path = table.concat({
  vim.fn.getcwd() .. '/lua/?.lua',
  vim.fn.getcwd() .. '/lua/?/init.lua',
  package.path,
}, ';')

local format = require 'custom.format'

local function context(path, files, executables, filetype)
  return {
    path = path,
    root = '/workspace',
    filetype = filetype,
    exists = function(file)
      return files[file] ~= nil
    end,
    read = function(file)
      return files[file]
    end,
    executable = function(command)
      return executables[command] == true
    end,
  }
end

local nested = context('/workspace/services/api/app.py', {
  ['/workspace/services/api/ruff.toml'] = '',
}, { ruff = true })
nested.roots = { '/workspace/services/api', '/workspace/services', '/workspace' }

local function assert_formatters(expected, actual)
  assert(vim.deep_equal(expected, actual), 'expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual))
end

assert_formatters({ 'ruff_format' }, format.save_formatters(nested))

-- Pure formatters save only in opted-in repositories with their executable.
assert_formatters(
  { 'stylua' },
  format.save_formatters(context('/workspace/init.lua', {
    ['/workspace/.stylua.toml'] = '',
  }, { stylua = true }))
)
assert_formatters({}, format.save_formatters(context('/workspace/init.lua', {}, { stylua = true })))

assert_formatters(
  { 'ruff_format' },
  format.save_formatters(context('/workspace/app.py', {
    ['/workspace/pyproject.toml'] = '[tool.ruff]\nline-length = 88',
  }, { ruff = true }))
)
assert_formatters(
  {},
  format.save_formatters(context('/workspace/app.py', {
    ['/workspace/pyproject.toml'] = '[project]\nname = "app"',
  }, { ruff = true }))
)

assert_formatters(
  { 'gofmt' },
  format.save_formatters(context('/workspace/main.go', {
    ['/workspace/go.mod'] = 'module example.com/app',
  }, { gofmt = true }))
)

local odin_nested = context('/workspace/apps/demo/src/main.odin', {
  ['/workspace/apps/demo/odinfmt.json'] = '{}',
}, { odinfmt = true })
odin_nested.roots = { '/workspace/apps/demo/src', '/workspace/apps/demo', '/workspace/apps', '/workspace' }
assert_formatters({ 'odinfmt' }, format.save_formatters(odin_nested))
assert_formatters({ 'odinfmt' }, format.manual_formatters(odin_nested))
assert_formatters({}, format.save_formatters(context('/workspace/main.odin', {}, { odinfmt = true })))
assert_formatters(
  {},
  format.save_formatters(context('/workspace/main.odin', {
    ['/workspace/odinfmt.json'] = '{}',
  }, {}))
)
assert_formatters(
  {},
  format.manual_formatters(context('/workspace/main.odin', {
    ['/workspace/odinfmt.json'] = '{}',
  }, {}))
)

assert_formatters(
  { 'prettier' },
  format.save_formatters(context('/workspace/page.md', {
    ['/workspace/.prettierrc'] = '{}',
  }, { ['/workspace/node_modules/.bin/prettier'] = true }))
)
assert_formatters(
  {},
  format.save_formatters(context('/workspace/page.md', {
    ['/workspace/.prettierrc'] = '{}',
  }, { prettier = true }))
)

-- Mutating and opt-in-only tools remain available through the manual policy.
assert_formatters(
  { 'ruff_fix', 'ruff_organize_imports', 'ruff_format' },
  format.manual_formatters(context('/workspace/app.py', {
    ['/workspace/ruff.toml'] = '',
  }, { ruff = true }))
)
assert_formatters(
  { 'sqlfluff' },
  format.manual_formatters(context('/workspace/query.sql', {
    ['/workspace/.sqlfluff'] = '[sqlfluff]',
  }, { sqlfluff = true }))
)
assert_formatters(
  { 'prettier' },
  format.manual_formatters(context('/workspace/page.md', {
    ['/workspace/.prettierrc'] = '{}',
  }, { ['/workspace/node_modules/.bin/prettier'] = true }))
)
assert_formatters(
  { 'ansible_lint' },
  format.manual_formatters(context('/workspace/playbook.yml', {
    ['/workspace/.ansible-lint'] = 'skip_list: []',
  }, { ['ansible-lint'] = true }, 'yaml.ansible'))
)

print 'format policy tests passed'
