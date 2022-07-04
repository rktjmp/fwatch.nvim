local uv = vim.loop

local make_default_error_cb = function(path, runnable)
  return function(error, _)
    error("fwatch.watch("..path..", "..runnable..")" ..
     "encountered an error: "..error)
  end
end

-- @doc """
-- Watch path and calls on_event(filename, events) or on_error(error)
--
-- opts:
--  is_oneshot -> don't reattach after running, no matter the return value
-- """
local function watch_with_function(path, on_event, on_error, opts)
  -- TODO: Check for 'fail'? What is 'fail' in the context of handle creation?
  --       Probably everything else is on fire anyway (or no inotify/etc?).
  local handle = uv.new_fs_event()

  -- these are just the default values
  local flags = {
    watch_entry = false, -- true = when dir, watch dir inode, not dir content
    stat = false, -- true = don't use inotify/kqueue but periodic check, not implemented
    recursive = false -- true = watch dirs inside dirs
  }

  local unwatch_cb = function()
    uv.fs_event_stop(handle)
  end

  local event_cb = function(err, filename, events)
    if err then
      on_error(error, unwatch_cb)
    else
      on_event(filename, events, unwatch_cb)
    end
    if opts.is_oneshot then
      unwatch_cb()
    end
  end

  -- attach handler
  uv.fs_event_start(handle, path, flags, event_cb)

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
  local on_event = function(_, _)
    vim.schedule(function()
      vim.cmd(string)
    end)
  end
  local on_error = make_default_error_cb(path, string)
  return watch_with_function(path, on_event, on_error, opts)
end

-- @doc """
-- Sniff parameters and call appropriate watch handler
-- """
local function do_watch(path, runnable, opts)
  if type(runnable) == "string" then
    return watch_with_string(path, runnable, opts)
  elseif type(runnable) == "table" then
    assert(runnable.on_event,
     "must provide on_event to watch")
    assert(type(runnable.on_event) == "function",
      "on_event must be a function")

    -- no on_error provided, make default
    if runnable.on_error == nil then
      table.on_error = make_default_error_cb(path, "on_event_cb")
    end

    return watch_with_function(
     path,
     runnable.on_event,
     runnable.on_error,
     opts
    )
  else
    error("Unknown runnable type given to watch," ..
      " must be string or {on_event = function, on_error = function}.")
  end
end

M = {
  -- create watcher
  watch = function (path, vim_command_or_callback_table)
    return do_watch(path, vim_command_or_callback_table, {
      is_oneshot = false
    })
  end,
  -- stop watcher
  unwatch = function (handle)
    return uv.fs_event_stop(handle)
  end,
  -- create watcher that auto stops
  once = function (path, vim_command_or_callback_table)
    return do_watch(path, vim_command_or_callback_table, {
      is_oneshot = true
    })
  end
}

return M
