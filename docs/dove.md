## Installation

_Requirement: Neovim v0.12.x or newer._

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "pewpewnor/dove.nvim",
    opts = {},
}
```

- `opts = {}` calls `require("dove").setup({})`.
- Add `cmd = "Dove"` for command-based lazy loading.
- Command-based lazy loading adds the vimdoc to `runtimepath` only after the
  first `:Dove` command. Load at startup if a help picker must find it earlier.

Otherwise, add dove.nvim to `runtimepath`, then configure it as described in
[Setup](#setup).

## Concepts

- A **target** names a command collection and resolves its source file.
- A **source file** returns the entries available for a target.
- An **entry** defines a shell command, picker label, and optional executor.
- An **executor** decides how and where to run the command.

The built-in targets are:

- `project`: commands for the current working directory, stored per directory.
- `filetype`: commands shared by buffers with the current buffer's filetype.

Targets resolve their paths when used. Changing directory, buffer, or filetype
can therefore change which source file a built-in target uses.

## Setup

Call before using commands or Lua API:

```lua
require("dove").setup()
```

- `setup()` accepts an optional options table.
- It merges options into the defaults, validates the result, and initializes
  the plugin.
- See [Configuration options](#configuration-options) for every option.

## Quick start

Open the current project's source file:

```vim
:Dove edit project
```

Replace its contents with:

```lua
return {
    { "make test" },
    { name = "build", cmd = "make build" },
    {
        name = "current file stats",
        cmd = "wc " .. dove.file_path(),
        executor = dove.executors.print,
    },
}
```

Run an entry:

```vim
:Dove run project
```

- One entry runs immediately by default.
- Multiple entries open the picker.
- Sources are reloaded on every run; restarting Neovim is unnecessary.
- Use `:Dove edit filetype` and `:Dove run filetype` for the current filetype.

## Default configuration

Default plugin configuration opts is equivalent to:

```lua
local preset = require("dove.preset")
{
    targets = {
        project = {
            source_path = function()
                return preset.dove_data_path()
                    .. "/projects/"
                    .. preset.hash_sha256(preset.cwd_path())
                    .. ".lua"
            end,
            auto_run_single_command = true,
            default_executor = function(command)
                preset.executors.split(
                    command,
                    { nil, "wincmd J | resize -4" }
                )
            end,
        },
        filetype = {
            source_path = function()
                return preset.dove_data_path()
                    .. "/filetypes/"
                    .. preset.file_type()
                    .. ".lua"
            end,
            auto_run_single_command = true,
            default_executor = function(command)
                preset.executors.split(
                    command,
                    { nil, "wincmd J | resize -4" }
                )
            end,
        },
    },
    environment = {
        dove = preset,
    },
    cmd_list_delimiter = function()
        return vim.o.shell:match("cmd%.exe$") and " & " or "; "
    end,
    write_template_to_new_source_file = true,
    ui = {
        picker = require("dove.picker"), -- see Built-in picker.
        enumerate_entries = true,
    },
}
```

## Configuration options

Calling `setup()` again discards previous user options and starts from fresh
defaults.

```lua
local preset = require("dove.preset")

require("dove").setup({
    targets = {
        project = {
            source_path = function()
                return preset.cwd_path() .. "/.dove.lua"
            end,
            auto_run_single_command = false,
            default_executor = preset.executors.split,
        },
        scripts = {
            source_path = function()
                return preset.config_path() .. "/dove/scripts.lua"
            end,
        },
    },
    environment = {
        test_prefix = "env TEST=1 ",
        executors = { quick = preset.executors.bg_exit_status },
    },
    cmd_list_delimiter = function()
        return " && "
    end,
    write_template_to_new_source_file = false,
    ui = {
        picker = vim.ui.select,
        enumerate_entries = false,
    },
})
```

All options are optional. Custom target names and environment keys are allowed;
known options are type-checked.

### `targets`

- Type: `table<string, Target>`.
- Defaults: `project` and `filetype`.
- User targets merge by name with built-in targets.

Each target supports:

| Option                    | Type                          | Default                                      |
| ------------------------- | ----------------------------- | -------------------------------------------- |
| `source_path`             | function or list of functions | Required for a new target                    |
| `auto_run_single_command` | boolean                       | `true`                                       |
| `default_executor`        | function                      | A short, full-width `preset.executors.split` |

A source resolver takes no arguments and returns a path string or `nil`.
Returned paths are normalized and `~` is expanded.

Use a non-empty resolver list for fallbacks:

```lua
source_path = {
    function()
        return preset.cwd_path() .. "/.dove.lua"
    end,
    function()
        return preset.config_path() .. "/dove/project.lua"
    end,
}
```

Resolution rules:

- The first readable file wins.
- Resolvers returning `nil` are skipped.
- If none is readable, the first non-`nil` path wins so `:Dove edit` can create
  it.
- Resolution fails if every resolver returns `nil`.

Built-in paths and settings:

- `project`: `stdpath("data")/dove/projects/<sha256-of-cwd>.lua`.
- `filetype`: `stdpath("data")/dove/filetypes/<filetype>.lua`.
- Both auto-run one entry and use a short, full-width `preset.executors.split`.

### `environment`

- Type: `table`.
- Default: all values under **Source environment**.

Custom values deeply merge with the built-ins. Add values and executors, or
replace built-ins:

```lua
environment = {
    test_prefix = "env TEST=1 ",
    file_path = function()
        return "fixed-input.lua"
    end,
    executors = {
        quick = preset.executors.bg_exit_status,
    },
}
```

The source can then use `dove.test_prefix`, the replaced `dove.file_path()`, and
`dove.executors.quick`.

### `cmd_list_delimiter`

- Type: function returning a string.
- Default: returns `"; "`, or `" & "` when `shell` is `cmd.exe`.
- Its return value joins list-valued entry commands and is passed directly to
  the shell.

See **Command lists** for execution behavior.

### Source file templates

`write_template_to_new_source_file` controls `:Dove edit` for a missing file:

- Type: `boolean`.
- Default: `true`.
- `true`: write a valid starter source before opening it.
- `false`: open an empty buffer at the resolved path.
- Existing files are never replaced.

### `ui`

```lua
ui = {
    picker = vim.ui.select,
    enumerate_entries = false,
}
```

- `picker`: a `vim.ui.select`-compatible function. Defaults to the built-in
  picker.
- `enumerate_entries`: prefixes labels with `"<number>. "`. Defaults to `true`.

A custom picker receives `items`, `opts`, and `on_choice`:

- `items` contains processed entries.
- `opts.prompt` includes the target name.
- `opts.format_item(entry)` returns the display label.
- Call `on_choice(item, index)` to run an entry or `on_choice()` to cancel.

#### Built-in picker

- Type to filter labels; leading and trailing query spaces are ignored.
- Matching is case-insensitive. Substrings rank above fuzzy in-order matches.
- Selection wraps at both ends.

| Action         | Keys                                      |
| -------------- | ----------------------------------------- |
| Next entry     | `<C-n>`, `<C-j>`, `<Down>`, `<Tab>`       |
| Previous entry | `<C-p>`, `<C-k>`, `<Up>`, `<S-Tab>`       |
| Choose         | `<CR>`, `<C-y>`                           |
| Cancel         | `<Esc>`, `<C-c>`, normal-mode `q`         |
| Edit query     | Type in insert mode; normal-mode `i`, `a` |

## Commands

| Command                 | Action                                                       |
| ----------------------- | ------------------------------------------------------------ |
| `:Dove run {target}`    | Load the target's source file and choose run an entry to run |
| `:Dove prev`            | Repeat execution of the last executed entry                  |
| `:Dove edit {target}`   | Open a target's source file                                  |
| `:Dove delete {target}` | Delete a target's source file                                |

- Subcommands and target names support completion.
- Missing, extra, and unknown arguments are rejected.
- `run` stops with a message when no readable source exists or it has no
  entries.
- Selecting an entry stores its final command and executor. Cancelling the
  picker does not replace the previous task.
- `prev` uses that stored task without reloading the source.
- `edit` creates missing parent directories. See **Source file templates** for
  new files.

## Source files

A source file returns a list of entry tables:

```lua
return {
    { "make test" },
    { name = "lint", cmd = "make lint" },
    {
        name = "check and build",
        cmd = { "make check", "make build" },
        executor = dove.executors.new_tab,
    },
}
```

The outer list is required even for one entry. An empty list is also valid:

```lua
return {}
```

Every entry supports:

| Field      | Type                      | Required          | Meaning                                 |
| ---------- | ------------------------- | ----------------- | --------------------------------------- |
| `[1]`      | string                    | One command field | Positional command                      |
| `cmd`      | string or list of strings | One command field | Named command                           |
| `name`     | string                    | No                | Picker label; defaults to the command   |
| `executor` | function                  | No                | Overrides the target's default executor |

- Set exactly one of `[1]` or `cmd`.
- A string item is not an entry; wrap it in a table.
- Commands run through Neovim's configured `shell`.
- An entry executor takes priority over its target's `default_executor`.

### Command lists

A named `cmd` may be a non-empty list of strings:

```lua
return {
    {
        name = "test and build",
        cmd = { "make test", "make build" },
    },
}
```

dove.nvim calls `cmd_list_delimiter`, joins the items with its return value, and
calls the executor once. They run in one shell session, so directory changes and
variables carry between items.

The default function returns `"; "`, or `" & "` for `cmd.exe`. It runs every
item, and the last item's status is the combined command's status. Return
`" && "` from `cmd_list_delimiter` on a compatible shell to stop on failure.
See the **`cmd_list_delimiter`** configuration option.

### Source environment

Source files receive the configured environment as `dove`:

```lua
return {
    {
        name = "test under cursor",
        cmd = "go test -run " .. dove.cword(),
        executor = dove.executors.bg_exit_status,
    },
}
```

- Normal Lua globals remain available.
- Each source evaluation gets a fresh Lua environment table.
- `dove` refers to the environment created by `setup()`.
- Custom values are covered under the **`environment`** configuration option.

Built-in values:

| Value                           | Result                                                |
| ------------------------------- | ----------------------------------------------------- |
| `dove.executors`                | Built-in and configured executors                     |
| `dove.file_path()`              | Filename-escaped absolute buffer path                 |
| `dove.file_path_relative()`     | Filename-escaped buffer path relative to the cwd      |
| `dove.file_name()`              | Filename-escaped buffer filename                      |
| `dove.file_name_no_extension()` | Filename-escaped buffer filename without extension    |
| `dove.file_type()`              | Current buffer filetype                               |
| `dove.file_extension()`         | Filename-escaped buffer filename extension            |
| `dove.dir_path()`               | Filename-escaped directory containing the buffer      |
| `dove.dir_name()`               | Filename-escaped name of the buffer's directory       |
| `dove.cwd_path()`               | Filename-escaped current working directory            |
| `dove.cwd_name()`               | Filename-escaped current working-directory name       |
| `dove.config_path()`            | Filename-escaped Neovim config directory              |
| `dove.data_path()`              | Filename-escaped Neovim data directory                |
| `dove.dove_data_path()`         | Filename-escaped dove.nvim data directory; creates it |
| `dove.cword()`                  | Word under the cursor                                 |
| `dove.cWORD()`                  | WORD under the cursor                                 |
| `dove.hash_sha256(value)`       | SHA-256 digest of a string                            |

Use the same values in Neovim configuration through `require("dove.preset")`.

### Imports

Import and flatten another source list with `require()`:

```lua
return {
    require("./shared.lua"),
    require("../team.lua"),
    require("~/commands/common.lua"),
    { "make test" },
}
```

A required name is a source-file import when it:

- Is an absolute path.
- Starts with `~`, `./`, or `../`.
- Ends with `.lua`.

For source-file imports:

- Relative paths start from the importing file's directory.
- `~` is expanded.
- The imported file follows the same source-list and entry rules.
- Its entries are inserted at the import's position.
- Imports may nest; circular imports are rejected.
- Entry errors identify the imported file containing them.

Other names use Lua's normal `require()` and are not flattened.

## Executors

An executor receives the final command and an optional argument list:

```lua
local function executor(command, args)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command })
end
```

Source entries pass an empty argument list. When a terminal executor is called
directly, the first argument-list item is inserted as an Ex count before its
`tabnew`, `split`, or `vsplit` command. For splits, this sets the height or
width. The second item for `split` is an Ex command run after creating the
window and before opening the terminal.

Source files use `dove.executors`. Configuration uses
`require("dove.preset").executors`.

| Executor                   | Behavior                                                           |
| -------------------------- | ------------------------------------------------------------------ |
| `executors.new_tab`        | Open a terminal in a new tab                                       |
| `executors.current_buffer` | Open a terminal in the current buffer                              |
| `executors.split`          | Open a terminal in a horizontal split                              |
| `executors.vsplit`         | Open a terminal in a vertical split                                |
| `executors.print`          | Run synchronously and print stdout                                 |
| `executors.silent`         | Run synchronously without output                                   |
| `executors.bg_silent`      | Run asynchronously without output                                  |
| `executors.bg_exit_status` | Run asynchronously and print success or failure with the exit code |

- Terminal executors use Neovim's shell through `:terminal`.
- `print` and `silent` block until completion.
- The `bg_*` executors return immediately.

Direct calls can set split size:

```lua
local executors = require("dove.preset").executors

executors.split("make test", { "12" })
executors.vsplit("make test", { "80" })
executors.split("make test", { nil, "wincmd J | resize -3" })
```

## Lua API

`require("dove")` returns:

| Function                          | Behavior                                           |
| --------------------------------- | -------------------------------------------------- |
| `setup(options?)`                 | Configure and initialize the plugin                |
| `run_target(target_name)`         | Run an entry from a named target                   |
| `run_prev_task()`                 | Repeat the last executed task                      |
| `edit_source_file(target_name)`   | Create when needed, then open a target source file |
| `delete_source_file(target_name)` | Delete a target's resolved source file             |

For example, map `<leader>dr` to run the `project` target:

```lua
local dove = require("dove")

vim.keymap.set("n", "<leader>dr", function()
    dove.run_target("project")
end, { desc = "Dove: run project target" })
```

The behavior under [Commands](#commands) also applies to these functions.
`require("dove.preset")` returns the built-in source environment for use in
configuration; see **Source environment** and [Executors](#executors).

## Health check

Run `:checkhealth dove`. It reports:

- Whether Neovim v0.12.0 or newer is running.
- Whether `setup()` was called.
- Whether the configured `shell` is executable.
- Whether each target resolves a source path.
- Whether each resolved source's parent directory is writable.

A missing or non-writable source directory is a warning. An unresolvable target
is an error.

## Links

- [Repository](https://github.com/pewpewnor/dove.nvim)
- [Contributing](../CONTRIBUTING.md)
