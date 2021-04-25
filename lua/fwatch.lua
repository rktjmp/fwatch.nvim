local uv = vim.loop

-- @doc """
-- Watch path and calls on_event(filename, events) or on_error(error)
--
-- opts:
--  is_oneshot -> don't reattach after running, no matter the return value
-- """
local function watch_with_function(path, on_event, on_error, opts)
  -- TODO: check for 'fail', what is 'fail'?
  local handle = uv.new_fs_event()

  -- these are just the default values
  local flags = {
    watch_entry = false, -- true = when dir, watch dir inode, not dir content
    stat = false, -- true = don't use inotify/kqueue but periodic check, not implemented
    recursive = false -- true = watch dirs inside dirs
  }

  local callback = function(err, filename, events)
    local remain_attached
    if err then
      remain_attached = on_error(error)
    else
      remain_attached = on_event(filename, events)
    end
    if opts.is_oneshot or remain_attached == false then
      uv.fs_event_stop(handle)
    end
  end

  -- attach handler
  uv.fs_event_start(handle, path, flags, callback)

  return handle
end

-- @doc """
-- Watch a path and run given string as an ex command
--
-- Internally creates on_event and on_error handler and
-- delegates to watch_with_function.
--
-- """
local function watch_with_string(path, string, opts)
  -- just run the command and reattach
  local on_event = function(_, _)
    vim.schedule(function()
      vim.cmd(string)
    end)

    -- may not re-attach if opts.is_oneshot = true
    return true
  end

  -- log the error and reattach
  local on_error = function(error)
    error("fwatch with with command: " .. string .. " encounterd an error: " .. error)

    -- always re-attach error so it's noticed
    -- may not re-attach if opts.is_oneshot = true
    return true
  end

  -- delegate out
  return watch_with_function(path, on_event, on_error, opts)
end

-- @doc """
-- Sniff parameters and call appropriate watch handler
-- """
local function do_watch(path, runnable, opts)
  if type(runnable) == "string" then
    return watch_with_string(path, runnable, opts)
  elseif type(runnable) == "table" then
    assert(runnable.on_event, "must provide on_event to watch")
    assert(runnable.on_error, "must provide on_error to watch")
    return watch_with_function(path, runnable.on_event, runnable.on_error, opts)
  else
    error("Unknown runnable type given to watch," ..
      " must be string or {on_event = function, on_error = function}.")
  end
end

M = {
  watch = function (path, runnable)
    return do_watch(path, runnable, {
      is_oneshot = false
    })
  end,
  unwatch = function (handle)
    return uv.fs_event_stop(handle)
  end,
  once = function (path, runnable)
    return do_watch(path, runnable, {
      is_oneshot = true
    })
  end
}

return M
