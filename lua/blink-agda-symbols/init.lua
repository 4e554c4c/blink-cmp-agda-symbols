--- @module 'blink.cmp'

--- @class agda-symbols.Options
--- @field extra table<string, string | string[]>
local defaults = {
  extra  = {},
}

--- @class agda-symbols.Source : blink.cmp.Source
--- @field symbols blink.cmp.CompletionItem[]
--- @field opts agda-symbols.Options
local source = {}

local function compute_symbols(symbols)
  local computed = {}
  for completion, associated_symbols in pairs(symbols) do
    local prefix_completion = [[\]] .. completion
    if type(associated_symbols) ~= "table" then
      associated_symbols = {associated_symbols}
    end
    for _ , symbol in ipairs(associated_symbols) do
      local item = {
        -- Label of the item in the UI
        label = prefix_completion .. ' ' .. symbol,
        -- (Optional) Item kind, where `Function` and `Method` will receive
        -- auto brackets automatically
        kind = require('blink.cmp.types').CompletionItemKind.Text,

        -- (Optional) Text to fuzzy match against
        filterText = prefix_completion,
        -- (Optional) Text to use for sorting. You may use a layout like
        -- 'aaaa', 'aaab', 'aaac', ... to control the order of the items
        sortText = prefix_completion,

        -- Text to be inserted when accepting the item:
        --
        -- we use dummy completion text for proper "ghost" text until resolution
        textEdit = {
          newText = prefix_completion,
        },
        --]]
        -- Or get blink.cmp to guess the range to replace for you. Use this only
        -- when inserting *exclusively* alphanumeric characters. Any symbols will
        -- trigger complicated guessing logic in blink.cmp that may not give the
        -- result you're expecting
        -- Note that blink.cmp will use `label` when omitting both `insertText` and `textEdit`
        insertText = symbol,
        -- May be Snippet or PlainText
        insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
      }
      table.insert(computed, item)
    end
  end
  return computed
end
-- `opts` table comes from `sources.providers.your_provider.opts`
-- You may also accept a second argument `config`, to get the full
-- `sources.providers.your_provider` table
function source.new(opts)
  -- TODO use vim.validate for opts when it is stabilized
  local self = setmetatable({}, { __index = source })

  local pluginPath = debug.getinfo(1,"S").source:match("^@(.-)/lua/blink%-agda%-symbols/init.lua")
  assert(pluginPath, "Unable to find location of current lua file")
  local symbolsPath = pluginPath .. '/agda-symbols/symbols.json'
  local f = assert(io.open(symbolsPath))
  local symbolsJson = f:read '*all'
  f:close()
  local symbols = vim.json.decode(symbolsJson, {luanil={object=true, array=true}})

  self.opts = opts
  symbols = vim.tbl_extend('force', symbols, opts.extra or {});
  self.symbols = compute_symbols(symbols)
  return self
end

-- (Optional) Enable the source in specific contexts only
function source:enabled()
    -- e.g. foo.bar.agda
    return string.match(vim.bo.filetype, '[%a.]*agda') ~= nil
end

-- (Optional) Non-alphanumeric characters that trigger the source
function source:get_trigger_characters()
  return {
    "'",
    ' ',
    '!',
    '"',
    '(',
    ')',
    '*',
    '+',
    '-',
    '.',
    '<',
    '=',
    '>',
    '^',
    '_',
    '`',
    '{',
    '|',
    '}',
    '~',
    [[\]],
  }
end

function source:get_completions(context, callback)
  -- ctx (context) contains the current keyword, cursor position, bufnr, etc.

  -- You should never filter items based on the keyword, since blink.cmp will
  -- do this for you

  local items = self.symbols

  items = vim.tbl_map(function(entry)
    return vim.tbl_deep_extend("force", entry, {
      textEdit = {
        range = {
          start = { line = context.cursor[1] - 1, character = context.bounds.start_col - 2 },
          ["end"] = { line = context.cursor[1] - 1, character = context.cursor[2] },
        },
      },
    })
  end , items)

  -- The callback _MUST_ be called at least once. The first time it's called,
  -- blink.cmp will show the results in the completion menu. Subsequent calls
  -- will append the results to the menu to support streaming results.
  callback({
    items = items,
    -- Whether blink.cmp should request items when deleting characters
    -- from the keyword (i.e. "foo|" -> "fo|")
    -- Note that any non-alphanumeric characters will always request
    -- new items (excluding `-` and `_`)
    is_incomplete_backward = false,
    -- Whether blink.cmp should request items when adding characters
    -- to the keyword (i.e. "fo|" -> "foo|")
    -- Note that any non-alphanumeric characters will always request
    -- new items (excluding `-` and `_`)
    is_incomplete_forward = false,
  })

  -- (Optional) Return a function which cancels the request
  -- If you have long running requests, it's essential you support cancellation
  return function() end
end

-- (Optional) Before accepting the item or showing documentation, blink.cmp will call this function
-- so you may avoid calculating expensive fields (i.e. documentation) for only when they're actually needed
function source:resolve(item, callback)
  item = vim.deepcopy(item)

  --[[ Shown in the documentation window (<C-space> when menu open by default)
  item.documentation = {
    kind = 'markdown',
    value = '# Foo\n\nBar',
  }
  --]]
  --
  item.textEdit.newText = item.insertText

  -- Additional edits to make to the document, such as for auto-imports
  --[[
  item.additionalTextEdits = {
    {
      newText = 'foo',
      range = {
        start = { line = 0, character = 0 },
        ['end'] = { line = 0, character = 0 },
      },
    },
  }
  --]]

  callback(item)
end

-- Called immediately after applying the item's textEdit/insertText
function source:execute(ctx, item, callback, default_implementation)
  -- By default, your source must handle the execution of the item itself,
  -- but you may use the default implementation at any time
  default_implementation()

  -- The callback _MUST_ be called once
  callback()
end

return source
