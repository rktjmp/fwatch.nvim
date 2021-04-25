# fwatch.nvim

### **This is ultra pre-release and the API should be considered unstable.**

Watch files for changes and execute vim commands or lua functions.

**Needs inotify (probably). Doesn't notice '$ touch file' (probably). Doesn't work on windows (probably).**

## Usage

Paths are relative to your current working dir and are not expanded ("\~/file" will *not* work).
You can use other nvim functions to expand current file or "\~" into an absolute path.

```lua
local fwatch = require("fwatch")

-- run a vim command on change
-- NOTE: This will run as ":my command", you /do not/ need to prefix with ":"
handle_a = fwatch.watch("my_path.txt", "my command")

-- run a pair of lua callbacks, you /must/ provide on_event and on_error
handle_b = fwatch.watch("my_other_path.txt", {
  on_event = function(filename, events)
    if events.change then
      print(filename .. " was changed")
    elseif events.rename then
      print(filename .. " was renamed")
    else
      pirint(filename .. " had some other event that libuv cant explain")
    end

    -- remain attached
    return true
  end,
  on_error = function(error)
    print(error)

    -- detatch
    return false
  end
})

fwatch.unwatch(handle_a)
fwatch.unwatch(handle_b)
```

## Maybe

`:Fwatchers` - show list of watchers?
`:Fwatch "path" "command"` ?
