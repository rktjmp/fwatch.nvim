local uv = vim.loop
-- 
local watchers = {}
local M = {}

-- watches path and calls on_event(filename, events) or on_error(error)
local function watch_with_function(path, on_event, on_error)
  -- check for 'fail', what is 'fail'?
  local handle = uv.new_fs_event()

  -- these are all default
  local flags = {
    watch_entry = false,
    stat = false,
    recursive = false
  }

  -- attach handler
  uv.fs_event_start(handle, path, flags, function(err, filename, events)
    if err then
      local remain_attached = on_error(error)
      if not remain_attached then
        uv.fs_event_stop(handle)
      end
    else
      local remain_attached = on_event(filename, events)
      if not remain_attached then
        uv.fs_event_stop(handle)
      end
    end
  end)

  return handle
end

local function watch_with_string(path, string)
  local on_event = function(_, _)
    vim.schedule(function()
      vim.cmd(string)
    end)
  end
  local on_error = function(error)
    print("fwatch with with command: " .. string .. " encounterd an error: " .. error)
  end
  return watch_with_function(path, on_event, on_error)
end

-- creates a new watcher
local function watch(path, runnable)
  if type(runnable) == "string" then
    return watch_with_string(path, runnable)
  elseif type(runnable) == "table" then
    assert(runnable.on_event, "must provide on_event")
    assert(runnable.on_error, "must provide on_error")
    return watch_with_function(path, runnable.on_event, runnable.on_error)
  else
    error("Unknown runnable type given to watch")
  end
end

local function unwatch(handle)
  uv.fs_event_stop(handle)
end

-- local function once(path, runnable)
--   local handle = watch(path, runnable)
-- end

return {
  watch = watch,
  -- once = once,
  unwatch = unwatch
}
