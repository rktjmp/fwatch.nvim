local uv = vim.loop
-- 
local watchers = {}
local M = {}

-- watches path and calls on_event(filename, events) or on_error(error)
local function watch_with_function(path, on_event, on_error)
  local fs_event = uv.new_fs_event()
  -- check for 'fail', what is 'fail'?
  local flags = {
    watch_entry = false,
    stat = false,
    recursive = false
  }

  uv.fs_event_start(fs_event, path, flags, function(err, filename, events)
    if err then
      on_error(error)
    else
      on_event(filename, events)
    end
  end)

end

local function watch_with_string(path, string)
  local on_event = function(filename, events)
    print(string)
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

return {
  watch = watch
}
