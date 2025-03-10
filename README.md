# blink-cmp-agda-symbols
A [blink.cmp](https://github.com/Saghen/blink.cmp/tree/main) source for agda symbols

# Install
Using [lazy.nvim](https://github.com/folke/lazy.nvim)


## Setup
In your lazy config:
```lua
{
  "saghen/blink.cmp",
  dependencies = {
    "4e554c4c/blink-cmp-agda-symbols",
    ...
  },
  opts = {

    sources = {
      -- There is no need to set `per_filetype` since agda-symbols already
      -- detects the correct filetype
      default = { 'agda_symbols', ...},

      providers = {
        agda_symbols = {
          name = "agda_symbols",
          module = "blink-agda-symbols",
          opts = {
            -- you can add extra symbols here. The table key is the
            -- completion key, which gets prepended with a backslash '\'
            extra = {
              wknight = '♘',
              moon = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
            }
          }
        },
      },
    },
  }
```

# Symbols
See [Agda symbols](https://github.com/4e554c4c/agda-symbols).

# Credits

This repository was forked from https://github.com/Arkissa/cmp-agda-symbols
