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
        cmd = "wc " .. denv.file_path(),
        executor = denv.executors.print,
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
        denv = preset,
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
local dove = require("dove")
local preset = require("dove.preset")

dove.setup({
    targets = {
        project = {
            source_path = {
                function()
                    return preset.cwd_path() .. "/.dove.lua"
                end,
                function()
                    return preset.config_path() .. "/dove/project.lua"
                end,
            },
            auto_run_single_command = false,
            default_executor = preset.executors.split,
        },
        custom_target = {
            source_path = function()
                return "~/custom_target_source.lua"
            end,
            auto_run_single_command = true,
            default_executor = preset.executors.current_buffer,
        },
    },
    environment = {
        custom_var = "my custom variable value",
        denv = {
            executors = {
                custom_notify = function(command)
                    vim.system(
                        { vim.o.shell, vim.o.shellcmdflag, command },
                        { text = true },
                        function(result)
                            vim.notify(result.stdout or result.stderr or "")
                        end
                    )
                end,
            },
            custom_func = function() end,
        },
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

With the above example, source files can access `custom_var`,
`denv.executors.custom_notify`, and `denv.custom_func`.

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
- Default: the built-in values under `denv`.

Custom values deeply merge with the built-ins. Add values and executors, or
replace built-ins:

```lua
environment = {
    denv = {
        file_path = function()
            return "fixed-input.lua"
        end,
        executors = {
            quick = preset.executors.bg_status,
        },
    },
    test_prefix = "env TEST=1 ",
}
```

The source can then use `test_prefix`, the replaced `denv.file_path()`, and
`denv.executors.quick`.

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

## Source file

A source file returns a list of entry tables:

```lua
return {
    { "make test" },
    {
        name = "build",
        cmd = "make build",
    },
    {
        name = "file stats",
        cmd = {
            "wc -l " .. denv.file_path(),
            "wc -w " .. denv.file_path(),
        },
        executor = denv.executors.print,
    },
    {
        name = "run test under cursor",
        cmd = "go test -run " .. denv.cword(),
        executor = denv.executors.new_tab,
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

### Imports

Import and flatten another source list with `require()`:

```lua
return {
    require("./adjacent.lua"),
    { "make test" },
    require("../parent.lua"),
    require("~/commands/common.lua"),
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

## Source environment

Source files receive each configured environment key as a global. Built-in
values are grouped under `denv`:

```lua
return {
    {
        name = "test under cursor",
        cmd = "go test -run " .. denv.cword(),
        executor = denv.executors.bg_status,
    },
}
```

- Normal Lua globals remain available.
- Each source evaluation gets a fresh Lua environment table.
- `denv` contains the built-in values and any configured overrides.
- Custom values are covered under the **`environment`** configuration option.

Use the same values in Neovim configuration through `require("dove.preset")`.
Every path function accepts either no argument or an `options` table. The
`escape` field must be a boolean when present. Its default is `true`, which
passes the return value through `fnameescape()`; `escape = false` returns the
unescaped value. `file_path` and `dir_path` additionally accept a boolean
`relative` field, which defaults to `false`. Invalid option and field types
raise an error.

- **`denv.executors`**

    A table containing the built-in executors and any executors added through the
    `environment` configuration option. Configuration is deeply merged, so a
    user-defined executor key is added without removing other built-ins. See
    [Executors](#executors) for the function contract and built-in functions.

- **`denv.file_path(options?)`**

    Expands `%:p` and returns the current buffer's absolute path. With
    `relative = true`, it expands `%` instead and returns the buffer path relative
    to the working directory. `options` accepts `escape` and `relative`.

- **`denv.file_name(options?)`**

    Expands `%:t` and returns the tail of the current buffer path, including its
    extension but excluding its directory. `options` accepts `escape`.

- **`denv.file_name_no_extension(options?)`**

    Expands `%:t:r` and returns the tail of the current buffer path without its
    final extension. For multiple extensions, only the final one is removed.
    `options` accepts `escape`.

- **`denv.file_type()`**

    Takes no arguments and returns the string value of the current buffer-local
    `filetype` option. It returns an empty string when no filetype is set.

- **`denv.file_extension(options?)`**

    Expands `%:e` and returns the current buffer filename's final extension
    without the leading dot. It returns an empty string when there is no
    extension. `options` accepts `escape`.

- **`denv.dir_path(options?)`**

    Expands `%:p:h` and returns the absolute path of the directory containing the
    current buffer. With `relative = true`, it expands `%:h` instead and returns
    the directory relative to the working directory. `options` accepts `escape`
    and `relative`.

- **`denv.dir_name(options?)`**

    Expands `%:p:h:t` and returns only the name of the directory containing the
    current buffer. `options` accepts `escape`.

- **`denv.cwd_path(options?)`**

    Returns the value of `getcwd()`. The result follows Neovim's current
    window-local, tab-local, or global working directory. `options` accepts
    `escape`.

- **`denv.cwd_name(options?)`**

    Applies the `:t` filename modifier to `getcwd()` and returns only the final
    directory name. `options` accepts `escape`.

- **`denv.config_path(options?)`**

    Returns Neovim's configuration directory from `stdpath("config")`.
    `options` accepts `escape`.

- **`denv.data_path(options?)`**

    Returns Neovim's data directory from `stdpath("data")`. `options` accepts
    `escape`.

- **`denv.dove_data_path(options?)`**

    Joins `stdpath("data")` with `dove`, recursively creates that directory when
    it does not exist, and returns its path. An existing directory is left
    unchanged. `options` accepts `escape`.

- **`denv.cword()`**

    Takes no arguments and returns `expand("<cword>")`. Word boundaries follow
    the current buffer's `iskeyword` option.

- **`denv.cWORD()`**

    Takes no arguments and returns `expand("<cWORD>")`. A WORD is a sequence of
    non-blank characters and does not use `iskeyword` boundaries.

- **`denv.expand(value)`**

    Requires a string and returns `expand(value)`. The accepted expressions and
    modifiers are those supported by Neovim's `expand()` function. A non-string
    argument raises an error.

- **`denv.hash_sha256(value)`**

    Accepts a string and returns `sha256(value)`, a 64-character lowercase
    hexadecimal SHA-256 digest.

## Executors

An executor receives the final command and an optional argument list:

```lua
local function executor(command, args)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command })
end
```

`command` is a string and `args`, when supplied, is a list of strings. dove.nvim
passes an empty list when it invokes an entry executor; non-empty argument
lists are available when an executor is called directly or wrapped by another
function. Built-in executors do not shell-escape `command` or validate the
items in `args`.

In source files, use `denv.executors`. In Neovim configuration, use
`require("dove.preset").executors`. Every executor accepts the command string
as its first argument. Terminal executors use Neovim's shell through
`:terminal`.

- **`executors.new_tab(command, args?)`**

    Opens `command` in a terminal in a new tab. The optional `args` list accepts
    an Ex count at `args[1]`, placed immediately before `tabnew`. The count has
    the semantics of `:{count}tabnew`, specifying where the new tab page is
    inserted. With no argument, the executed command is
    `tabnew | terminal {command}`.

- **`executors.current_buffer(command)`**

    Opens `command` in a terminal in the current buffer. It accepts no executor
    arguments beyond the command and executes `terminal {command}`. The current
    buffer is replaced according to the normal behavior and restrictions of
    `:terminal`.

- **`executors.split(command, args?)`**

    Opens `command` in a terminal in a `rightbelow` horizontal split. The
    optional `args` list accepts the split height at `args[1]` and an Ex command
    at `args[2]`. The Ex command runs after the split is created and before the
    terminal opens. The resulting Ex command is `rightbelow [{height}] split`,
    followed by the optional Ex command and `terminal {command}`.

- **`executors.vsplit(command, args?)`**

    Opens `command` in a terminal in a vertical split. The optional `args` list
    accepts the split width at `args[1]`. Without a width it executes
    `botright vsplit | terminal {command}`. With a width it executes
    `{width} vsplit | terminal {command}`.

- **`executors.print(command)`**

    Runs `command` synchronously and prints its standard output. Neovim is
    blocked until the command exits. The process is started as
    `{shell, shellcmdflag, command}` using the current Neovim options. Standard
    error and the exit status are not printed by this executor.

- **`executors.silent(command)`**

    Runs `command` synchronously without printing its output. Neovim is blocked
    until the command exits. The process uses the current `shell` and
    `shellcmdflag`; its standard output, standard error, and exit status are
    discarded.

- **`executors.bg_silent(command)`**

    Starts `command` asynchronously without printing its output and returns
    immediately. The process uses the current `shell` and `shellcmdflag`; its
    standard output, standard error, and exit status are discarded.

- **`executors.bg_status(command)`**

    Starts `command` asynchronously and returns immediately. When the job exits,
    it prints `dove.nvim: command job success (exit code 0)` for status zero or
    `dove.nvim: command job error (exit code N)` for a nonzero status. Process
    output is not printed.

Direct calls can set split size:

```lua
local executors = require("dove.preset").executors

executors.split("make test", { "12" })
executors.vsplit("make test", { "80" })
executors.split("make test", { nil, "wincmd J | resize -3" })
```

## Lua API

`require("dove")` returns the following functions.

- **`setup(options?)`**

    Accepts a table or `nil` and returns no value. The table accepts the fields
    described under [Configuration options](#configuration-options). The
    function deep-merges the supplied values into fresh defaults, validates the
    complete configuration, and initializes the parser and runner with it.
    Invalid values raise an error. Calling `setup()` again discards the previous
    user options and repeats this process with fresh defaults.

- **`run_target(target_name)`**

    Requires a target-name string and returns no value. It resolves the target's
    source path, evaluates and validates the source list, and either executes its
    only entry when `auto_run_single_command` is enabled or passes all entries to
    the configured picker. The chosen command and executor become the previous
    task only when an entry is executed. An unknown target, invalid resolver, or
    invalid source raises an error. A missing source or empty source list prints
    a message and does not replace the previous task.

- **`run_prev_task()`**

    Takes no arguments and returns no value. It invokes the stored executor with
    the last executed command and its stored argument list. It does not resolve
    a target, reload a source file, rerun the picker, or re-read configuration.
    If no entry has been executed, it prints
    `dove.nvim: no previously executed task` and does nothing else.

- **`edit_source_file(target_name)`**

    Requires a target-name string and returns no value. It resolves the target's
    source path, recursively creates missing parent directories, and opens the
    escaped path with `:tabedit`. If the path is not a readable file and
    `write_template_to_new_source_file` is enabled, it first appends the starter
    source template. An unknown target or invalid resolver raises an error.

- **`delete_source_file(target_name)`**

    Requires a target-name string and returns no value. It resolves the target's
    source path and calls `vim.fs.rm(path, { force = true })`. No confirmation is
    requested, and a missing path is ignored. An unknown target or invalid
    resolver raises an error.

Example of binding keys:

```lua
local dove = require("dove")

-- map `<leader>dp` to run target 'project':
vim.keymap.set("n", "<Leader>dp", function()
    dove.run_target("project")
end, { desc = "Dove: run target project" })

-- map `<leader>df` to run target 'filetype':
vim.keymap.set("n", "<Leader>df", "<Cmd>Dove run filetype<CR>",
    { desc = "Dove: run target filetype" })
```

The behavior under [Commands](#commands) also applies to these functions.
`require("dove.preset")` returns the built-in source environment for use in
configuration; see [Source environment](#source-environment) and
[Executors](#executors).

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
