-- Mocked checks only: no compositor, apps, or config reloads are used.
local dashboard = assert(loadfile("hypr/.config/hypr/boot-dashboard.lua"))()
local original_time = os.time
local serial = 0

local function fake(windows, options)
  options, serial = options or {}, serial + 1
  local log, timers, handlers = {}, {}, {}
  local active = options.active
  local timer = function(callback, opts)
    local item = { callback = callback, opts = opts, enabled = true }
    function item:set_enabled(value) self.enabled = value end
    table.insert(timers, item)
    return item
  end
  local function dispatcher(kind, value)
    return kind .. ":" .. value
  end
  local hl = {
    get_monitor = function(name)
      if options.no_monitor then return nil end
      if name == "HDMI-A-1" then return { name = name, active_workspace = { name = options.lg_workspace or "7" } } end
      return { name = name or "DP-1", active_workspace = { name = "1" } }
    end,
    get_workspace_windows = function() return windows end,
    get_window = function(selector)
      local wanted = selector:match("^address:(.+)$")
      for _, window in ipairs(windows) do if window.address == wanted then return window end end
      for _, window in ipairs(options.global_windows or {}) do if window.address == wanted then return window end end
    end,
    get_config = function()
      if options.throw_config then error("mocked config failure") end
      return options.gaps or { top = 4, bottom = 4 }
    end,
    get_active_window = function() return active end,
    get_last_window = function() return options.last end,
    get_active_monitor = function() return { name = "DP-1", active_workspace = { name = "1" } } end,
    exec_cmd = function(command) table.insert(log, { "exec", command }) end,
    dispatch = function(command)
      table.insert(log, { "dispatch", command })
      local wanted = command:match("^focus:address:(.+)$")
      if wanted then
        for _, window in ipairs(windows) do if window.address == wanted then active = window end end
      end
    end,
    dsp = {
      focus = function(args) return dispatcher("focus", args.workspace or args.window or args.monitor) end,
      layout = function(message) return dispatcher("layout", message) end,
    },
    timer = timer,
    on = function(event, callback)
      local subscription = { event = event, callback = callback, enabled = true }
      function subscription:remove() self.enabled = false end
      table.insert(handlers, subscription)
      return subscription
    end,
  }
  local o = {
    launch = function(command) return "uwsm-app -- " .. command end,
    launch_webapp = function(url) return "omarchy-launch-webapp " .. url end,
    notify = function(message) return "notify " .. message end,
  }
  local home = "/tmp/opencode/boot-dashboard-review-" .. serial
  os.execute("mkdir -p " .. home .. "/.local/state/hypr")
  os.remove(home .. "/.local/state/hypr/boot-dashboard-boot-id")
  local old_getenv = os.getenv
  os.getenv = function(name) return name == "HOME" and home or old_getenv(name) end
  os.time = function() return 0 end
  local state = dashboard.new({ hl = hl, o = o })
  local function flush()
    local progressed = true
    while progressed do
      progressed = false
      for _, item in ipairs(timers) do
        if item.enabled and item.opts.type == "oneshot" and item.opts.timeout == 1 then
          item.enabled = false; item.callback(); progressed = true
        end
      end
    end
  end
  local function emit(event)
    for _, handler in ipairs(handlers) do if handler.enabled and handler.event == event then handler.callback() end end
    flush()
  end
  return state, log, timers, handlers, emit, flush, function() os.getenv, os.time = old_getenv, original_time end,
    function() return dashboard.new({ hl = hl, o = o }) end
end

local function has(log, value)
  for _, entry in ipairs(log) do if entry[2] == value then return true end end
  return false
end
local function count(log, value)
  local n = 0
  for _, entry in ipairs(log) do if entry[2] == value then n = n + 1 end end
  return n
end
local function layouts(log)
  local out = {}
  for _, entry in ipairs(log) do if entry[2]:sub(1, 7) == "layout:" then table.insert(out, entry[2]:sub(8)) end end
  return out
end
local function valid_split(message)
  local value, exact = message:match("^splitratio ([^ ]+) ([^ ]+)$")
  return value and tonumber(value) and exact == "exact"
end
local function reset_direction_is_unsupported(message)
  local token = message:match("^preselect%s+(%S+)$")
  return token and not token:sub(1, 1):match("[lrutdb]")
end

-- Persistent boot guard and missing-monitor skip consume the attempt.
do
  local state, log, timers, _, _, flush, done, another = fake({})
  state:start(); flush()
  local before = #timers
  another():start()
  assert(count(log, "uwsm-app -- omarchy-launch-webapp https://youtube.com") == 1)
  assert(#timers == before) -- a separate module instance sees the same marker
  done()
  local missing, missing_log, _, _, _, _, missing_done = fake({}, { no_monitor = true })
  missing:start()
  assert(has(missing_log, "notify Boot dashboard skipped: HDMI-A-1 is unavailable."))
  missing_done()
end

-- This is event-driven: startup makes one deferred pass; window events move it
-- through YouTube -> real Discord -> btop.  The updater is not readiness.
do
  local windows = {}
  local user = {
    mapped = true, class = "user", address = "user",
    monitor = { name = "DP-1", active_workspace = { name = "1" } }, workspace = { name = "1" },
  }
  local state, log, timers, handlers, emit, flush, done = fake(windows, {
    active = user, global_windows = { user }, lg_workspace = "7",
  })
  state:start(); flush()
  assert(has(log, "uwsm-app -- omarchy-launch-webapp https://youtube.com"))
  assert(#handlers == 5 and #timers >= 2)
  table.insert(windows, { mapped = true, class = "brave-youtube.com__-Default", address = "y", size = { y = 496 } })
  emit("window.open")
  assert(has(log, "uwsm-app -- discord"))
  table.insert(windows, { mapped = true, class = "discord", initial_title = "Discord Updater", address = "u" })
  emit("window.title")
  assert(not has(log, "uwsm-app -- omarchy launch tui btop"))
  table.remove(windows, 2)
  table.insert(windows, { mapped = true, class = "discord", initial_title = "Discord", address = "d" })
  emit("window.title")
  assert(has(log, "focus:address:d") and has(log, "uwsm-app -- omarchy launch tui btop"))
  table.insert(windows, { mapped = true, class = "org.omarchy.btop", address = "b" })
  emit("window.open")
  for _, message in ipairs(layouts(log)) do
    if message:sub(1, 10) == "splitratio" then assert(valid_split(message)) end
  end
  assert(has(log, "layout:splitratio 1.0059880239521 exact") or has(log, "layout:splitratio 1.0059880239520957 exact"))
  assert(has(log, "layout:splitratio 0.664 exact"))
  assert(has(log, "layout:preselect none"))
  for _, message in ipairs(layouts(log)) do
    if message:sub(1, 9) == "preselect" and message ~= "preselect d" then
      assert(reset_direction_is_unsupported(message))
    end
  end
  assert(has(log, "focus:address:user"))
  assert(has(log, "focus:HDMI-A-1") and has(log, "focus:7"))
  for _, handler in ipairs(handlers) do assert(not handler.enabled) end
  done()
end

-- An unrelated occupant aborts before the first preselect or ratio mutation.
do
  local windows = {
    { mapped = true, class = "brave-youtube.com__-Default", address = "y" },
    { mapped = true, class = "unrelated", initial_title = "Unexpected Window", address = "x" },
  }
  local state, log, _, _, _, flush, done = fake(windows)
  state:start(); flush()
  assert(has(log, "notify Boot dashboard left workspace 6 unchanged because another window is present (class=unrelated, title=Unexpected Window)."))
  assert(not has(log, "layout:preselect d"))
  assert(not has(log, "layout:splitratio 1 exact"))
  done()
end

-- Discord can briefly map a Discord-owned startup window before the real main
-- window has initial_title == "Discord".  It is not readiness, but it must not
-- be treated as an unrelated app and abort the sequential launch.
do
  local windows = {}
  local state, log, _, _, emit, flush, done = fake(windows)
  state:start(); flush()
  table.insert(windows, { mapped = true, class = "brave-youtube.com__-Default", address = "y" })
  emit("window.open")
  assert(has(log, "uwsm-app -- discord"))
  table.insert(windows, { mapped = true, class = "discord", initial_title = "Discord Starting", address = "s" })
  emit("window.title")
  assert(not has(log, "uwsm-app -- omarchy launch tui btop"))
  table.remove(windows, 2)
  table.insert(windows, { mapped = true, class = "discord", initial_title = "Discord", address = "d" })
  emit("window.title")
  assert(has(log, "uwsm-app -- omarchy launch tui btop"))
  done()
end

-- The deadline sees the current workspace even if a window event was missed.
-- An unrelated late occupant keeps its useful class/title diagnostic.
do
  local windows = {}
  local state, log, timers, _, _, flush, done = fake(windows)
  state:start(); flush()
  table.insert(windows, { mapped = true, class = "brave-youtube.com__-Default", address = "y" })
  table.insert(windows, { mapped = true, class = "unrelated", initial_title = "Late Window", address = "x" })
  for _, item in ipairs(timers) do if item.opts.timeout == 60000 then item.callback() end end
  assert(has(log, "notify Boot dashboard left workspace 6 unchanged because another window is present (class=unrelated, title=Late Window)."))
  done()
end

-- A persistent non-updater Discord startup window remains a transient at the
-- deadline: leave workspace 6 unchanged rather than laying out through it.
do
  local windows = {}
  local state, log, timers, _, _, flush, done = fake(windows)
  state:start(); flush()
  table.insert(windows, { mapped = true, class = "brave-youtube.com__-Default", address = "y" })
  table.insert(windows, { mapped = true, class = "discord", initial_title = "Discord Starting", address = "s" })
  for _, item in ipairs(timers) do if item.opts.timeout == 60000 then item.callback() end end
  assert(has(log, "notify Boot dashboard incomplete; workspace 6 was left unchanged."))
  assert(not has(log, "layout:preselect d"))
  assert(not has(log, "layout:splitratio 1 exact"))
  done()
end

-- No active window falls back to monitor/workspace restoration.  An updater is
-- excluded from capture and therefore cannot replace that genuine context.
do
  local updater = { mapped = true, class = "discord", initial_title = "Discord Updater", address = "u" }
  local user = {
    mapped = true, class = "user", address = "user",
    monitor = { name = "DP-1", active_workspace = { name = "1" } }, workspace = { name = "1" },
  }
  local youtube = { mapped = true, class = "brave-youtube.com__-Default", address = "y" }
  local windows = { updater, youtube }
  local state, log, timers, _, _, flush, done = fake(windows, {
    active = updater, last = user, global_windows = { user }, lg_workspace = "8",
  })
  state:start(); flush()
  -- The YouTube focus captures a no-window user context.  The active updater
  -- is ignored, and deadline restoration returns the LG to workspace 8.
  for _, item in ipairs(timers) do if item.opts.timeout == 60000 then item.callback() end end
  for _, entry in ipairs(log) do assert(entry[2] ~= "focus:address:u") end
  assert(has(log, "focus:address:user"))
  assert(has(log, "focus:HDMI-A-1") and has(log, "focus:8"))
  assert(has(log, "notify Boot dashboard incomplete; workspace 6 was left unchanged."))
  done()
end

-- An initially empty genuine workspace has no window address, so restoration
-- falls back to that workspace rather than retaining dashboard workspace 6.
do
  local youtube = { mapped = true, class = "brave-youtube.com__-Default", address = "y" }
  local state, log, timers, _, _, flush, done = fake({ youtube }, { lg_workspace = "7" })
  state:start(); flush()
  for _, item in ipairs(timers) do if item.opts.timeout == 60000 then item.callback() end end
  assert(has(log, "focus:DP-1") and has(log, "focus:1"))
  assert(has(log, "focus:HDMI-A-1") and has(log, "focus:7"))
  done()
end

-- Once a discovered target closes it is not replaced/relaunched; deadline
-- cleanup disables timers and emits a single incomplete notification.
do
  local youtube = { mapped = true, class = "brave-youtube.com__-Default", address = "y" }
  local windows = { youtube }
  local state, log, timers, _, emit, flush, done = fake(windows)
  state:start(); flush(); emit("window.open")
  windows[1] = nil; emit("window.close")
  for _, item in ipairs(timers) do if item.opts.timeout == 60000 then item.callback() end end
  assert(count(log, "uwsm-app -- discord") == 1)
  assert(has(log, "layout:preselect none"))
  assert(has(log, "notify Boot dashboard incomplete; arranged available apps on workspace 6."))
  done()
end

-- A failure while the deadline tries to arrange must still cancel every
-- callback and restore the genuine user window, rather than leaving a live
-- attempt behind.
do
  local user = {
    mapped = true, class = "user", address = "user",
    monitor = { name = "DP-1", active_workspace = { name = "1" } }, workspace = { name = "1" },
  }
  local windows = { { mapped = true, class = "brave-youtube.com__-Default", address = "y", size = { y = 496 } } }
  local options = { active = user, global_windows = { user }, lg_workspace = "7" }
  local state, log, timers, handlers, emit, flush, done = fake(windows, options)
  state:start(); flush()
  table.insert(windows, { mapped = true, class = "discord", initial_title = "Discord", address = "d" })
  emit("window.open")
  table.insert(windows, { mapped = true, class = "org.omarchy.btop", address = "b" })
  options.throw_config = true
  for _, item in ipairs(timers) do if item.opts.timeout == 60000 then item.callback() end end
  assert(has(log, "notify Boot dashboard failed; workspace 6 may be partially arranged."))
  assert(has(log, "focus:address:user"))
  for _, item in ipairs(timers) do assert(not item.enabled) end
  for _, handler in ipairs(handlers) do assert(not handler.enabled) end
  done()
end

print("boot-dashboard mocked checks: ok")
