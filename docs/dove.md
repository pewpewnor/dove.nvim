dove.nvim runs project and file commands from Lua source files.

It requires Neovim v0.12.x or newer.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "pewpewnor/dove.nvim",
    lazy = false,
    opts = {},
}
```

Add `cmd = "Dove"` to the plugin spec for command-based lazy loading.
Command-only lazy loading keeps the vimdoc off `runtimepath` until `:Dove` is
run once, so use startup loading when browsing help through a picker first.

## Setup

```lua
require("dove").setup()
```

`setup()` accepts an options table and deeply merges it into the defaults.

## Commands

dove.nvim defines one user command with four subcommands:

| Command | Action |
| ------- | ------ |
| `:Dove run {target}` | Read the target's source file and run an entry |
| `:Dove prev` | Repeat the last command |
| `:Dove edit {target}` | Open the target's source file in a new tab |
| `:Dove delete {target}` | Delete the target's source file |

Subcommands and target names support completion. The default targets are
`project` and `filetype`.

## Source files

A source file is a Lua file that returns a list of entries:

```lua
return {
    { "make test" },
    { name = "build & run", cmd = "make build && make run" },
    {
        cmd = "git status --short",
        name = "status",
        executor = dove.executors.print,
    },
}
```

Every entry must be a table with a command in `[1]` or `cmd`.

| Field | Type | Required | Meaning |
| ----- | ---- | -------- | ------- |
| `[1]` | string | One command field | Positional command |
| `cmd` | string or list of strings | One command field | Named command |
| `name` | string | No | Picker label; defaults to the command |
| `executor` | function | No | Overrides the target's default executor |

Do not set both `[1]` and `cmd`.

When `cmd` is a list, dove.nvim joins its items with
`cmd_list_delimiter` and sends the result to the executor once. With the
default `"; "` (`" & "` with `cmd.exe`), the commands run sequentially in the
same shell session, so state such as variables and the working directory
carries between items. Every item is attempted, and the final item's status is
the command's exit status.

```lua
return {
    {
        name = "stats for this file",
        cmd = {
            "wc " .. dove.file_path(),
            "echo lines: $(wc -l < " .. dove.file_path() .. ")",
            "echo words: $(wc -w < " .. dove.file_path() .. ")",
        },
    },
}
```

When a source has only one entry, it must still return a list:

```lua
return {
    { name = "a", cmd = "touch hello" },
}
```

When a source contains one entry and `auto_run_single_command` is true, dove.nvim
runs it without opening the picker. Empty source lists do nothing and print a
message; write an empty source as `return {}`.

### Source environment

Source files run with the configured `environment`. Its keys are available on
the `dove` table inside the file:

```lua
return {
    { dove.prefix .. "go test -run " .. dove.cword() },
    {
        "git status --short",
        executor = dove.executors.print,
    },
}
```

Normal Lua globals remain available alongside the `dove` table.

### Imports

Use `require()` to include another source list:

```lua
return {
    require("./shared.lua"),
    require("~/commands/common.lua"),
    { "make test" },
}
```

Absolute paths, paths beginning with `~/`, `./`, or `../`, and names ending in
`.lua` are loaded as source files. Relative paths are resolved from the
importing file. Other names use Lua's normal `require()`. Imported source lists
are flattened in place. Circular source imports are rejected.

## Configuration options

### Defaults

The user-configurable defaults are equivalent to:

```lua
local preset = require("dove.preset")

{
    targets = {
        project = {
            source = function(environment)
                return vim.fs.joinpath(
                    environment.dove_data_path(),
                    "projects",
                    environment.hash_sha256(environment.cwd_path()) .. ".lua"
                )
            end,
            auto_run_single_command = true,
            default_executor = preset.executors.new_tab,
        },
        filetype = {
            source = function(environment)
                return vim.fs.joinpath(
                    environment.dove_data_path(),
                    "filetypes",
                    environment.file_type() .. ".lua"
                )
            end,
            auto_run_single_command = true,
            default_executor = preset.executors.new_tab,
        },
    },
    environment = {
        arbit = {
            executors = {
                -- see section on preset executors
            },
            -- see section on preset environment
        },
    },
    cmd_list_delimiter = <"; ", or " & " with cmd.exe>,
    write_template_to_new_source_file = true,
    picker = <built-in picker>,
}
```

The built-in environment is added automatically, then user options are deeply
merged into these defaults.

### `cmd_list_delimiter`

Type: `string`

The string used to join a source entry's `cmd` list. The default is `"; "`, or
`" & "` when using `cmd.exe`. The value is passed directly to the configured
shell. On shells that support it, set it to `" && "` to stop after the first
failed command.

### `targets`

Type: `table<string, Target>`

Each target has:

| Option | Type | Meaning |
| ------ | ---- | ------- |
| `source` | function or list of functions | Resolves the source-file path |
| `auto_run_single_command` | boolean | Skips the picker for one entry |
| `default_executor` | function | Runs entries without their own executor |

A source resolver receives the effective environment and returns a path or
`nil`. Built-in environment values are also returned by
`require("dove.preset")`:

```lua
source = function()
    return preset.cwd_path() .. "/.dove.lua"
end
```

Using the argument lets a resolver honor configured environment overrides:

```lua
source = function(environment)
    return environment.cwd_path() .. "/.dove.lua"
end
```

For a list of resolvers, dove.nvim uses the first readable path. If none are
readable, it uses the first non-`nil` path so `:Dove edit` can create it.

```lua
source = {
    function()
        return preset.cwd_path() .. "/.dove.lua"
    end,
    function()
        return preset.config_path() .. "/dove/fallback.lua"
    end,
}
```

### `write_template_to_new_source_file`

Type: `boolean`

When true, `:Dove edit` writes a small template before opening a missing source
file. The default is true.

### `environment`

Type: `table`

Values in this table are available on the source file's `dove` table. Custom
values are merged with the built-ins:

```lua
environment = {
    prefix = "env DEBUG=1 ",
    branch = function()
        local result = vim.system(
            { "git", "branch", "--show-current" },
            { text = true }
        ):wait()
        return result.stdout:gsub("%s+$", "")
    end,
    executors = {
        capture = function(command)
            vim.system(
                { vim.o.shell, vim.o.shellcmdflag, command },
                { text = true },
                function(result) vim.notify(result.stdout) end
            )
        end,
    },
}
```

The built-in environment contains:

| Value | Result |
| ----- | ------ |
| `dove.executors` | Built-in executor table |
| `dove.file_path()` | Escaped absolute buffer path |
| `dove.file_path_relative()` | Escaped buffer path relative to the working directory |
| `dove.file_name()` | Escaped buffer filename |
| `dove.file_name_no_extension()` | Escaped buffer filename without its extension |
| `dove.file_type()` | Current buffer filetype |
| `dove.file_extension()` | Escaped buffer filename extension |
| `dove.dir_path()` | Escaped directory containing the buffer |
| `dove.dir_name()` | Escaped name of the directory containing the buffer |
| `dove.cwd_path()` | Escaped working-directory path |
| `dove.cwd_name()` | Escaped working-directory name |
| `dove.config_path()` | Escaped Neovim config path |
| `dove.data_path()` | Escaped Neovim data path |
| `dove.dove_data_path()` | Escaped dove.nvim data path; creates it if needed |
| `dove.cword()` | Word under the cursor |
| `dove.cWORD()` | WORD under the cursor |
| `dove.hash_sha256(value)` | SHA-256 digest of a string |

Outside source files, the built-in values are returned by
`require("dove.preset")`.

### `picker`

Type: `function`

The default is a dependency-free fuzzy picker in a centered floating window.
Its first line is an editable search query, followed by a margin and numbered
matching entries. Leading and trailing search spaces are ignored. Use `<C-n>`,
`<C-j>`, `<Down>`, or `<Tab>` for the next entry; `<C-p>`, `<C-k>`, `<Up>`, or
`<S-Tab>` for the previous entry; `<CR>` or `<C-y>` to choose; and `<Esc>` or
`<C-c>` to cancel.

The function receives `items`, `opts`, and `on_choice`, following the
`vim.ui.select` signature. To use the configured Neovim selector instead:

```lua
require("dove").setup({
    picker = vim.ui.select,
})
```

## Executors

An executor receives the command and an optional argument list:

```lua
local function executor(command, args)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command })
end
```

Current source entries pass an empty argument list. The second parameter remains
part of the executor interface.

Built-in executors:

Source files use `dove.executors`. Plugin configuration gets the same functions
from `require("dove.preset").executors`.

| Executor | Behavior |
| -------- | -------- |
| `preset.executors.new_tab` | Opens a terminal in a new tab |
| `preset.executors.current_buffer` | Opens a terminal in the current buffer |
| `preset.executors.split` | Opens a terminal in a horizontal split |
| `preset.executors.vsplit` | Opens a terminal in a vertical split |
| `preset.executors.print` | Runs synchronously and prints stdout |
| `preset.executors.silent` | Runs synchronously without output |
| `preset.executors.bg_silent` | Runs asynchronously without output |
| `preset.executors.bg_exit_status` | Runs asynchronously and prints success or failure |

## Lua API

All public functions are returned by `require("dove")`:

| Function | Meaning |
| -------- | ------- |
| `setup(options?)` | Configure and initialize the plugin |
| `run_target(target_name)` | Run an entry from a target |
| `run_prev_task()` | Repeat the last executed task |
| `edit_source_file(target_name)` | Open a target source file |
| `delete_source_file(target_name)` | Delete a target source file |

The built-in source environment is returned by `require("dove.preset")` for use
in plugin configuration.

## Health check

Run:

```vim
:checkhealth dove
```

The check reports the Neovim version, shell, setup state, source paths, and
configured executors.

## Links

- [Repository](https://github.com/pewpewnor/dove.nvim)
- [Contributing](../CONTRIBUTING.md)
