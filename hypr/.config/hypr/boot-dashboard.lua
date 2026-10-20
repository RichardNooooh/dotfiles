-- Build workspace 6 once per Linux boot.  The marker is written before any
-- dashboard work, so a failed attempt or config reload never retries it.
local M = {}

local WORKSPACE, SECONDARY_OUTPUT, DEADLINE_MS = "6", "HDMI-A-1", 60000

local function consume_boot(home)
  local source = io.open("/proc/sys/kernel/random/boot_id", "r")
  if not source then return false end
  local id = source:read("*l")
  source:close()
  if not id then return false end

  local directory = home .. "/.local/state/hypr"
  local path = directory .. "/boot-dashboard-boot-id"
  local old = io.open(path, "r")
  if old then
    local previous = old:read("*l")
    old:close()
    if previous == id then return false end
  end
  os.execute("mkdir -p " .. string.format("%q", directory))
  local marker = io.open(path, "w")
  if not marker then return false end
  marker:write(id, "\n")
  marker:close()
  return true
end

local function address(window)
  return window and window.address
end

local function is_youtube(window)
  return window.mapped and window.class == "brave-youtube.com__-Default"
end
local function is_discord(window)
  return window.mapped and window.class == "discord" and window.initial_title == "Discord"
end
local function is_discord_owned(window)
  return window.mapped and window.class == "discord"
end
local function is_discord_startup(window)
  return is_discord_owned(window) and not is_discord(window)
end
local function is_btop(window)
  return window.mapped and window.class == "org.omarchy.btop"
end

function M.new(api)
  local hl, o = api.hl, api.o
  local state = { ids = {}, seen = {}, launched = {}, subscriptions = {}, deferred = {}, busy = false, done = false }

  local function windows()
    return hl.get_workspace_windows(WORKSPACE) or {}
  end

  local function by_address(id)
    if not id then return nil end
    for _, window in ipairs(windows()) do
      if window.mapped and window.address == id then return window end
    end
  end

  local function find(match)
    for _, window in ipairs(windows()) do
      if match(window) then return window end
    end
  end

  local function reconcile()
    -- Keep identities only as addresses.  Lua userdata can expire after close.
    local youtube, discord, btop = by_address(state.ids.youtube), by_address(state.ids.discord), by_address(state.ids.btop)
    if not youtube and not state.seen.youtube then youtube = find(is_youtube) end
    if not discord and not state.seen.discord then discord = find(is_discord) end
    if not btop and not state.seen.btop then btop = find(is_btop) end
    if youtube then state.seen.youtube = true end
    if discord then state.seen.discord = true end
    if btop then state.seen.btop = true end
    state.ids.youtube, state.ids.discord, state.ids.btop = address(youtube), address(discord), address(btop)
    return youtube, discord, btop
  end

  local function notify(message)
    hl.exec_cmd(o.notify(message))
  end

  local function dashboard_transient(window)
    return is_youtube(window) or is_discord_owned(window) or is_btop(window)
  end

  local function save_context(window, monitor)
    local lg = hl.get_monitor(SECONDARY_OUTPUT)
    local lg_workspace = lg and lg.active_workspace and lg.active_workspace.name
    -- Our workspace-6 focus changes what the LG displays.  Do not mistake
    -- that internal side effect for a user request and lose the saved LG
    -- workspace while capturing a later genuine Dell-side focus change.
    if state.restore and lg_workspace == WORKSPACE and state.restore.lg_workspace and state.restore.lg_workspace ~= WORKSPACE then
      lg_workspace = state.restore.lg_workspace
    end
    state.restore = {
      window = address(window),
      monitor = monitor and monitor.name,
      workspace = (window and window.workspace and window.workspace.name) or
        (monitor and monitor.active_workspace and monitor.active_workspace.name),
      lg_workspace = lg_workspace,
    }
  end

  local function capture_context()
    local active = hl.get_active_window()
    if active and not dashboard_transient(active) then
      save_context(active, active.monitor or hl.get_active_monitor())
      return
    end

    if active then
      -- A splash/updater is dashboard-owned.  It must never replace a saved
      -- user context; use last only for the initial fallback if it is real.
      local last = hl.get_last_window()
      if not state.restore and last and not dashboard_transient(last) then
        save_context(last, last.monitor or hl.get_active_monitor())
      end
      return
    end

    local monitor = hl.get_active_monitor()
    local workspace = monitor and monitor.active_workspace and monitor.active_workspace.name
    -- An empty non-dashboard workspace is genuine user context.  Once our
    -- own workspace-6 focus has begun, a nil active window there is not.
    if not state.restore or workspace ~= WORKSPACE then
      save_context(nil, monitor)
    end
  end

  local function focus(window)
    capture_context()
    hl.dispatch(hl.dsp.focus({ workspace = WORKSPACE }))
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
  end

  local function restore_context()
    local restore = state.restore
    if not restore then return end
    -- Workspace 6 can replace the LG's displayed workspace even though the
    -- user was focused elsewhere, so restore it before returning user focus.
    if restore.lg_workspace and restore.lg_workspace ~= WORKSPACE then
      hl.dispatch(hl.dsp.focus({ monitor = SECONDARY_OUTPUT }))
      hl.dispatch(hl.dsp.focus({ workspace = restore.lg_workspace }))
    end
    if restore.monitor then hl.dispatch(hl.dsp.focus({ monitor = restore.monitor })) end
    local current = restore.window and hl.get_window("address:" .. restore.window)
    if current and current.mapped and current.address == restore.window then
      hl.dispatch(hl.dsp.focus({ window = "address:" .. current.address }))
    elseif restore.workspace then
      hl.dispatch(hl.dsp.focus({ workspace = restore.workspace }))
    end
  end

  local function clear_preselect()
    -- Any unsupported direction resets dwindle's pending preselection.
    hl.dispatch(hl.dsp.layout("preselect none"))
  end

  local function cancel_callbacks()
    if state.deadline then state.deadline:set_enabled(false) end
    for _, timer in ipairs(state.deferred) do timer:set_enabled(false) end
    for _, subscription in ipairs(state.subscriptions) do subscription:remove() end
  end

  local function finish(message)
    if state.done then return end
    state.done = true
    -- A dispatcher error must not leave the deadline or event handlers alive.
    pcall(clear_preselect)
    pcall(cancel_callbacks)
    pcall(restore_context)
    if message then pcall(notify, message) end
  end

  local function blocked_by_unrelated()
    for _, window in ipairs(windows()) do
      local id = window.address
      if window.mapped and id ~= state.ids.youtube and id ~= state.ids.discord and id ~= state.ids.btop and not is_discord_owned(window) then
        return window
      end
    end
  end

  local function unrelated_message(window)
    local class = window.class or "<none>"
    local title = window.initial_title or window.title or "<none>"
    return "Boot dashboard left workspace 6 unchanged because another window is present " ..
      "(class=" .. tostring(class) .. ", title=" .. tostring(title) .. ")."
  end

  local function component(value, key, index)
    return type(value) == "table" and (value[key] or value[index] or 0) or 0
  end

  local function stack_ratios(top)
    local gaps = hl.get_config("general:gaps_in")
    local gap_top, gap_bottom = component(gaps, "top", 1), component(gaps, "bottom", 3)
    local visible_top = component(top.size, "y", 2)
    if visible_top <= 0 then return 1, 2 / 3 end
    local total, visible = 2 * (visible_top + gap_bottom), 0
    visible = (total - 2 * gap_top - 2 * gap_bottom) / 3
    if visible <= 0 then return 1, 2 / 3 end
    return 2 * (visible + gap_top + gap_bottom) / (2 * visible + 2 * gap_top + gap_bottom),
      2 * (visible + gap_bottom) / total
  end

  local function layout(message)
    hl.dispatch(hl.dsp.layout(message))
  end

  local function launch(name, command)
    if state.launched[name] then return end
    state.launched[name] = true
    hl.exec_cmd(command)
  end

  local function arrange_partial()
    local youtube, discord, btop = reconcile()
    if blocked_by_unrelated() or find(is_discord_startup) then return false end
    if youtube and discord and btop then
      local bottom, root = stack_ratios(youtube)
      focus(discord); layout("splitratio " .. bottom .. " exact")
      focus(youtube); layout("splitratio " .. root .. " exact")
    elseif youtube and discord then
      focus(youtube); layout("splitratio 1 exact")
    end
    return true
  end

  local advance
  local function defer_advance()
    local timer
    timer = hl.timer(function()
      timer:set_enabled(false)
      advance()
    end, { timeout = 1, type = "oneshot" })
    table.insert(state.deferred, timer)
  end

  advance = function()
    if state.done or state.busy then return end
    state.busy = true
    local ok, err = xpcall(function()
      local youtube, discord, btop = reconcile()
      -- Never alter a tree containing an unrelated mapped window.  Discord's
      -- own startup windows are tolerated while its main window is pending.
      local unrelated = blocked_by_unrelated()
      if unrelated then
        finish(unrelated_message(unrelated))
        return
      end
      if not youtube then return end
      if not state.launched.discord then
        focus(youtube); layout("preselect d")
        launch("discord", o.launch("discord"))
        return
      end
      if not discord then return end
      if not state.launched.btop then
        focus(youtube); layout("splitratio 1 exact")
        focus(discord); layout("preselect d")
        launch("btop", o.launch("omarchy launch tui btop"))
        return
      end
      if not btop then return end
      if find(is_discord_startup) then return end
      if arrange_partial() then finish() else
        finish(unrelated_message(blocked_by_unrelated()))
      end
    end, debug.traceback)
    state.busy = false
    if not ok then finish("Boot dashboard failed; workspace 6 may be partially arranged.") end
  end

  function state:start()
    if not consume_boot(os.getenv("HOME") or "") then return end
    if not hl.get_monitor(SECONDARY_OUTPUT) then
      notify("Boot dashboard skipped: HDMI-A-1 is unavailable.")
      return
    end
    launch("youtube", o.launch(o.launch_webapp("https://youtube.com")))
    state.deadline = hl.timer(function()
      if state.done then return end
      local ok = xpcall(function()
        reconcile()
        local unrelated = blocked_by_unrelated()
        if unrelated then
          finish(unrelated_message(unrelated))
        elseif arrange_partial() then
          finish("Boot dashboard incomplete; arranged available apps on workspace 6.")
        else
          finish("Boot dashboard incomplete; workspace 6 was left unchanged.")
        end
      end, debug.traceback)
      if not ok then finish("Boot dashboard failed; workspace 6 may be partially arranged.") end
    end, { timeout = DEADLINE_MS, type = "oneshot" })
    for _, event in ipairs({ "window.open", "window.class", "window.title", "window.close", "window.destroy" }) do
      table.insert(state.subscriptions, hl.on(event, defer_advance))
    end
    defer_advance()
  end

  return state
end

function M.install()
  local dashboard = M.new({ hl = hl, o = o })
  hl.on("hyprland.start", function() dashboard:start() end)
end

return M
