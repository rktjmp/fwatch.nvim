# fwatch.nvim

Watch files for changes and execute vim commands or lua functions.

## Usage

```lua
handle_a = fwatch("my_path.txt", "a vim cmd")
handle_b = fwatch("my_other_path.txt", {
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
```

## Maybe

`:Fwatchers` - show list of watchers?
