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

- Add `cmd = "Dove"` to the plugin spec for command-based lazy loading.
- Command-only lazy loading keeps the vimdoc off `runtimepath` until `:Dove`
  runs once. Use startup loading if help must be available through a picker
  before that.

## Setup

```lua
require("dove").setup()
```

- `setup()` accepts an optional options table.
- It deeply merges the options into the defaults, validates the result, and
  initializes the plugin.
- Call it before using commands or other Lua API functions.

## Commands

dove.nvim defines one user command with four subcommands:

| Command | Action |
| ------- | ------ |
| `:Dove run {target}` | Read the target's source file and run an entry |
| `:Dove prev` | Repeat the last executed entry |
| `:Dove edit {target}` | Create when needed, then open the target's source file in a new tab |
| `:Dove delete {target}` | Delete the target's resolved source file |

- The default targets are `project` and `filetype`.
- Subcommands and target names support completion.
- Missing, extra, and unknown arguments are rejected.
- `run` prints a message and stops when the resolved source is missing or
  returns an empty list.
- A successfully selected entry becomes the previous task. Cancelling the
  picker does not replace it.
- `prev` uses the stored command and executor without loading the source again.
- `edit` creates missing parent directories and, when enabled, writes a starter
  entry for a missing source file.
- `delete` removes the resolved file immediately without confirmation.

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

- The returned table must be a list.
- Every item must be an entry table.
- Every entry must have exactly one command field: `[1]` or `cmd`.

| Field | Type | Required | Meaning |
| ----- | ---- | -------- | ------- |
| `[1]` | string | One command field | Positional command |
| `cmd` | string or list of strings | One command field | Named command |
| `name` | string | No | Picker label; defaults to the command |
| `executor` | function | No | Overrides the target's default executor |

- Do not set both `[1]` and `cmd`.

- A list-valued `cmd` is joined with `cmd_list_delimiter` and sent to the
  executor once.
- The default delimiter is `"; "`, or `" & "` with `cmd.exe`.
- The default runs every item sequentially in one shell session, so variables
  and working-directory changes carry between items.
- The final item's exit status becomes the combined command's exit status.

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

- A source with one entry still needs the outer list.
- When `auto_run_single_command` is true, that entry runs without a picker.
- An empty source is written as `return {}`; running it prints a message and
  does nothing.

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

- Normal Lua globals remain available alongside `dove`.
- Each source load receives a fresh Lua environment table.
- Its `dove` value refers to the environment configured by `setup()`.

### Imports

Use `require()` to include another source list:

```lua
return {
    require("./shared.lua"),
    require("~/commands/common.lua"),
    { "make test" },
}
```

- Absolute paths, paths beginning with `~`, `./`, or `../`, and names ending
  in `.lua` load source files.
- Relative paths start from the directory containing the importing file.
- `~` is expanded.
- Other names use Lua's normal `require()`.
- Imported lists are flattened in place and follow the root source's entry
  rules.
- Circular source imports are rejected.

## Configuration options

### Defaults

The user-configurable defaults are equivalent to:

```lua
local preset = require("dove.preset")

{
    targets = {
        project = {
            source_path = function()
                return vim.fs.joinpath(
                    preset.dove_data_path(),
                    "projects",
                    preset.hash_sha256(preset.cwd_path()) .. ".lua"
                )
            end,
            auto_run_single_command = true,
            default_executor = preset.executors.split,
        },
        filetype = {
            source_path = function()
                return vim.fs.joinpath(
                    preset.dove_data_path(),
                    "filetypes",
                    preset.file_type() .. ".lua"
                )
            end,
            auto_run_single_command = true,
            default_executor = preset.executors.split,
        },
    },
    environment = {
        executors = {
            -- see the Executors section
        },
        -- see the Source environment section
    },
    cmd_list_delimiter = <"; ", or " & " with cmd.exe>,
    write_template_to_new_source_file = true,
    selection = {
        picker = <built-in picker>,
        enumerate_entries = true,
    },
}
```

- The built-in environment is added automatically.
- User options are deeply merged into the defaults.
- Calling `setup()` again starts with a fresh default configuration before
  applying the new options.
- `project` stores its source under `stdpath("data")/dove/projects`, using a
  SHA-256 digest of the working-directory path as its filename.
- `filetype` stores its source under `stdpath("data")/dove/filetypes`, using
  the current buffer filetype as its filename.

### `cmd_list_delimiter`

- Type: `string`.

- Joins the items in a list-valued `cmd`.
- Defaults to `"; "`, or `" & "` when the configured shell is `cmd.exe`.
- Is passed directly to the configured shell.
- Can be set to `" && "` on supporting shells to stop after the first failure.

### `targets`

- Type: `table<string, Target>`.

Each target has:

| Option | Type | Meaning |
| ------ | ---- | ------- |
| `source_path` | function or list of functions | Resolves the source-file path |
| `auto_run_single_command` | boolean | Skips the picker for one entry |
| `default_executor` | function | Runs entries without their own executor; defaults to `preset.executors.split` |

- A source resolver takes no arguments and returns a path string or `nil`.
- Returned paths are normalized and `~` is expanded.
- Built-in path helpers are available from `require("dove.preset")`:

```lua
source_path = function()
    return preset.cwd_path() .. "/.dove.lua"
end
```

- With multiple resolvers, the first readable file wins.
- If no returned path is readable, the first non-`nil` path wins so `:Dove
  edit` can create it.
- Resolution fails when every resolver returns `nil`.

```lua
source_path = {
    function()
        return preset.cwd_path() .. "/.dove.lua"
    end,
    function()
        return preset.config_path() .. "/dove/fallback.lua"
    end,
}
```

### `write_template_to_new_source_file`

- Type: `boolean`.

- Defaults to `true`.
- When true, `:Dove edit` writes a starter template before opening a missing
  source file.
- When false, `:Dove edit` opens an empty buffer for that path.

### `environment`

- Type: `table`.

- Values are exposed through the source file's `dove` table.
- Custom values are deeply merged with the built-ins.
- Individual built-in values and executors can be extended or replaced.

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

- Outside source files, access these built-ins through `require("dove.preset")`.

### `selection`

- Type: `table`.

Configure the picker and entry labels with:

```lua
selection = {
    picker = <vim.ui.select-compatible function>,
    enumerate_entries = true,
}
```

- `picker` defaults to a dependency-free floating picker.
- Matching is case-insensitive. Contiguous substring matches rank first;
  otherwise, characters may match in order across the label.
- The first line is the editable query. Leading and trailing spaces are
  ignored.
- Selection wraps at both ends.
- Next-entry keys are `<C-n>`, `<C-j>`, `<Down>`, and `<Tab>`.
- Previous-entry keys are `<C-p>`, `<C-k>`, `<Up>`, and `<S-Tab>`.
- Choose with `<CR>` or `<C-y>`.
- Cancel with `<Esc>`, `<C-c>`, or normal-mode `q`.
- Normal-mode `i` or `a` returns focus to the query.
- `enumerate_entries` defaults to `true` and prefixes labels with
  `"<number>. "`. Set it to `false` to omit the prefix.
- A custom picker receives `items`, `opts`, and `on_choice`, following the
  `vim.ui.select` signature.
- `opts.prompt` contains the target name and `opts.format_item` produces the
  entry label.
- Calling `on_choice` without an item cancels execution.

To use Neovim's configured `vim.ui.select` implementation:

```lua
require("dove").setup({
    selection = {
        picker = vim.ui.select,
    },
})
```

## Executors

An executor receives the final command string and an optional argument list:

```lua
local function executor(command, args)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command })
end
```

- Source entries currently pass an empty argument list.
- The second parameter remains part of the executor interface.
- An entry's executor takes priority over its target's `default_executor`.

- Source files access built-in executors through `dove.executors`.
- Plugin configuration accesses the same functions through
  `require("dove.preset").executors`.

| Executor | Behavior |
| -------- | -------- |
| `preset.executors.new_tab` | Opens a terminal in a new tab |
| `preset.executors.current_buffer` | Opens a terminal in the current buffer |
| `preset.executors.split` | Opens a terminal in a horizontal split |
| `preset.executors.vsplit` | Opens a terminal in a vertical split |
| `preset.executors.print` | Runs synchronously and prints stdout |
| `preset.executors.silent` | Runs synchronously without output |
| `preset.executors.bg_silent` | Runs asynchronously without output |
| `preset.executors.bg_exit_status` | Runs asynchronously and prints success or failure with the exit code |

- Terminal executors use Neovim's configured shell through `:terminal`.
- `silent` and `print` wait for the command to finish.
- The two `bg_*` executors return immediately.

## Lua API

All public functions are returned by `require("dove")`:

| Function | Meaning |
| -------- | ------- |
| `setup(options?)` | Configure and initialize the plugin |
| `run_target(target_name)` | Run an entry from a named target |
| `run_prev_task()` | Repeat the last executed task |
| `edit_source_file(target_name)` | Create when needed, then open a target source file |
| `delete_source_file(target_name)` | Delete a target's resolved source file |

- `require("dove.preset")` returns the built-in source environment for use in
  plugin configuration.

## Health check

Run:

```vim
:checkhealth dove
```

- Reports whether Neovim v0.12.0 or newer is running.
- Reports whether `setup()` was called.
- Reports whether the configured shell is executable.
- After setup, resolves every target and checks whether its source file's
  parent directory is writable.
- Reports a missing or non-writable source directory as a warning.

## Links

- [Repository](https://github.com/pewpewnor/dove.nvim)
- [Contributing](../CONTRIBUTING.md)
