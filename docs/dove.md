## Installation

Requirement: Neovim v0.12.x or newer.

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "pewpewnor/dove.nvim",
    opts = {},
}
-- or
{
    "pewpewnor/dove.nvim",
    config = function()
        require("dove").setup()
    end
}
```

- `opts = {}` calls `require("dove").setup({})`.
- Add `cmd = "Dove"` for command-based lazy loading.
- Command-based lazy loading adds the vimdoc to `runtimepath` only after the
  first `:Dove` command. Load at startup if a help picker must find it earlier.

Otherwise, add dove.nvim to `runtimepath`, then configure it as described in
[Setup](#setup).

## Concepts

- A **target** names a command collection and resolves its source.
- A **source file** returns the entries available for a target.
- An **entry** defines a shell command or Lua function, picker label, and
  optional executor.
- An **executor** decides how and where to run the command.

The built-in targets are:

- `project`: commands for the current working directory, stored per directory.
- `filetype`: commands shared by buffers with the current buffer's filetype.
- `global`: commands shared across all files and projects.

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
- See [configuration](#configuration) for every option.

## Quick Start

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

- One entry opens the picker by default.
- Multiple entries open the picker.
- Sources are reloaded on every run; restarting Neovim is unnecessary.
- Use `:Dove edit filetype` and `:Dove run filetype` for the current filetype.
- Use `:Dove edit global` and `:Dove run global` for global commands.

## Configuration

### Default Configuration

Assuming we define:

```lua
local default_environment = require("dove.opts.environment")
```

The default plugin configuration opts is equivalent to:

```lua
{
    targets = {
        project = {
            source = function()
                return default_environment.dove_data_path()
                    .. "/projects/"
                    .. default_environment.hash_sha256(default_environment.cwd_path())
                    .. ".lua"
            end,
        },
        filetype = {
            source = function()
                return default_environment.dove_data_path()
                    .. "/filetypes/"
                    .. default_environment.file_type()
                    .. ".lua"
            end,
        },
        global = {
            source = function()
                return default_environment.dove_data_path() .. "/global.lua"
            end,
        },
    },
    parent_target = {
        auto_run_single_entry = false,
        default_executor = default_environment.executors.default,
        environment = {
            denv = default_environment,
        },
        cmd_list_delimiter = function()
            local shell = vim.fs.basename(vim.o.shell:gsub("\\", "/")):lower()
            return (shell == "cmd" or shell == "cmd.exe") and " & " or "; "
        end,
        new_source_file_placeholder = [[return {
    {
        name = "placeholder greeting",
        cmd = "echo 'Hello from dove.nvim!'",
    },
}
]],
    },
    unspecified_target_name = nil,
    ui = {
        picker = require("dove.picker"),
        format_selection_item = function(name, i)
            return i .. ". " .. name
        end,
    },
}
```

### `targets`

- Type: `table<string, Target|false>`.
- Defaults: `project`, `filetype`, and `global`.
- User targets merge by name with built-in targets.
- Every target inherits `parent_target` before its own options are applied.
- A target set to `false` is removed from the configuration. It cannot be
  run, edited, deleted, or completed by name. This also works for built-in
  targets and does not require a `source`.

Each target supports:

| Option                             | Type              | Default                                 |
| ---------------------------------- | ----------------- | --------------------------------------- |
| `source`                           | function          | Required for a new target               |
| `auto_run_single_entry`            | boolean           | `false`                                 |
| `default_executor`                 | function          | `default_environment.executors.default` |
| `environment`                      | table             | Built-in `denv` values                  |
| `cmd_list_delimiter`               | function          | Shell-compatible list separator         |
| `new_source_file_placeholder`      | string or false   | Starter source code                     |

A source function takes no arguments and returns a source file path string.
Paths are normalized and `~` is expanded. For example:

```lua
source = function()
    return default_environment.cwd_path() .. "/.dove.lua"
end
```

`:Dove edit` creates the source file when it does not exist.

Built-in paths and settings:

- `project`: `stdpath("data")/dove/projects/<sha256-of-cwd>.lua`.
- `filetype`: `stdpath("data")/dove/filetypes/<filetype>.lua`.
- Both show the picker for one entry and use `default_environment.executors.default`.

### `parent_target`

- Type: `table` or `false`.
- Setting `false` removes inherited parent options. Every remaining target must
  define its required options, including the built-in targets.

The options in `parent_target` are deeply merged into every built-in and custom
target. A target can override any inherited value. Its `environment` table
merges with the built-in `denv` values and with the target's own environment.
When `targets` is omitted, all built-in targets share the same environment table
as `parent_target`.
`source` is still required for each new target.

### `targets.<name>.environment`

- Type: `table`.
- Default: the built-in values under `denv`.

Custom values deeply merge with the built-ins. Add values and executors, or
replace built-ins:

```lua
targets = {
    project = {
        environment = {
            denv = {
                file_path = function()
                    return "fixed-input.lua"
                end,
                executors = { quick = default_environment.executors.bg_status },
            },
            test_prefix = "env TEST=1 ",
        },
    },
}
```

The source can then use `test_prefix`, the replaced `denv.file_path()`, and
`denv.executors.quick`.

### `unspecified_target_name`

- Type: `(fun(): string)|nil`.
- Default: `nil`.

Resolves the target name used by `:Dove run`, `:Dove edit`, `run()`, and
`edit()` when no target is provided. The returned name must match
a configured target. If the option is `nil`, omitting a target raises an error.

### `targets.<name>.cmd_list_delimiter`

- Type: `fun(): string`.
- Default: returns `"; "`, or `" & "` when `shell` is `cmd.exe`.
- Its return value joins list-valued entry commands and is passed directly to
  the shell.

See **Command lists** for execution behavior.

### Source File Templates

`targets.<name>.new_source_file_placeholder` controls `:Dove edit` for a
missing file:

- Type: `string` or `false`.
- Default: the starter source code shown in the default configuration.
- Omitting the option or assigning `nil` uses the default.
- Set `false` to open a new source file without writing a template.
- A string is written to the new source file before it is opened.
- Existing files are never replaced.

### `ui`

```lua
ui = {
    picker = vim.ui.select,
    format_selection_item = function(name, i)
        return name .. " (" .. i .. ")"
    end,
}
```

- `picker`: a `vim.ui.select`-compatible function. Defaults to the built-in
  picker.
- `format_selection_item`: receives an entry name and its index and returns its
  picker label. Defaults to `function(name, i) return i .. ". " .. name end`.

A custom picker receives `items`, `opts`, and `on_choice`:

- `items` contains processed entries.
- `opts.prompt` includes the target name.
- `opts.format_item(entry)` returns the display label.
- Call `on_choice(item, index)` to run an entry or `on_choice()` to cancel.

#### Built-in Picker

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

| Command                 | Action                           |
| ----------------------- | -------------------------------- |
| `:Dove run [target]`    | Run the target                   |
| `:Dove edit [target]`   | Open the target's source file    |
| `:Dove delete {target}` | Delete the target's source file  |
| `:Dove prev_task`       | Repeat the last executed task    |
| `:Dove prev_entry`      | Recompute and run the last entry |

- Subcommands and target names support completion.
- Missing, extra, and unknown arguments are rejected, except that `run` and
  `edit` may omit their target when `unspecified_target_name` is configured.
- `run` stops with a message when no readable source exists or it has no
  entries.
- Selecting an entry stores its final command or function and executor.
  Cancelling the picker does not replace the previous task.
- `:Dove prev_task` uses that stored task without reloading the source.
- `:Dove prev_entry` resolves the original target again, reloads its source, and runs
  the entry at the previously selected position without opening the picker.
- Without a previous task or entry, those subcommands print a message and do nothing.
- If the previous entry no longer exists, `prev_entry` prints a message and
  does nothing.
- `edit` creates missing parent directories. See **Source file templates** for
  new files.

## Source File

A source file returns a list of entry tables:

```lua
return {
    { "make build" },
    {
        name = "run python file",
        cmd = "python3 " .. denv.file_path(),
    },
    {
        "print dir stats",
        cmd = {
            "echo size = $(du -sh " .. denv.dir_path() .. " | cut -f1)",
            "echo file count = $(ls -1 " .. denv.file_path() .. " | wc -l)",
        },
        executor = denv.executors.print,
    },
    {
        name = "run hovered test function under cursor",
        cmd = "go test -run " .. denv.cword(),
        executor = denv.executors.new_tab,
    },
    {
        name = "run some Lua code",
        cmd = function()
            print("calling my module")
            require("my_module")
        end,
    },
}
```

The outer list is required even for one entry. An empty list is also valid:

```lua
return {}
```

Every entry supports:

| Field      | Type                                 | Required          | Meaning                                       |
| ---------- | ------------------------------------ | ----------------- | --------------------------------------------- |
| `[1]`      | string or function                   | One command field | Positional shell command or Lua function      |
| `cmd`      | string, list of strings, or function | One command field | Named shell command or Lua function           |
| `name`     | string                               | No                | Picker label; defaults to the command         |
| `executor` | function                             | No                | Overrides the target's default shell executor |

- Set exactly one of `[1]` or `cmd`. Every command string must contain a
  non-whitespace character.
- A string item is not an entry; wrap it in a table.
- String commands run through Neovim's configured `shell`.
- For string commands, an entry executor takes priority over its target's
  `default_executor`.

When `[1]` or `cmd` is a function, dove.nvim calls it directly without
arguments. Both the entry's executor and the target's `default_executor` are
ignored, and the processed entry's executor is `nil`. Its picker label defaults
to `tostring()` of the function when `name` is omitted. The same function is
called again by `:Dove prev_task`. `:Dove prev_entry` reloads the source and calls
the newly defined function at the same entry position.

### Command Lists

A named `cmd` may be a non-empty list of strings:

```lua
return {
    {
        name = "test and build",
        cmd = { "make test", "make build" },
    },
}
```

dove.nvim calls the target's `cmd_list_delimiter`, joins the items with its return value, and
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

## Source Environment

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

Use the same values in Neovim configuration through `require("dove.opts.environment")`.
The replay functions are also available through `denv`:

- **`denv.last_task()`** returns a copy of the last executed command, executor,
  and argument list, or `nil` if no task has run.
- **`denv.run_task(task)`** runs that saved task without changing replay history.
  Passing `nil` prints `dove.nvim: no previously executed task`.
- **`denv.last_entry()`** returns a copy of the last executed entry's target name
  and list index, or `nil` if no entry has run.
- **`denv.run_entry(entry)`** resolves the saved target again, reloads its source,
  and runs the entry at the saved index. It updates replay history. Passing
  `nil` prints `dove.nvim: no previously executed entry`.

Every path function accepts either no argument or an `options` table. The
`escape` field must be a boolean when present. Its default is `true`, which
passes the return value through `fnameescape()`; `escape = false` returns the
unescaped value. `file_path` and `dir_path` additionally accept a boolean
`relative` field, which defaults to `false`. `file_name` additionally accepts a
boolean `extension` field, which defaults to `true`. Invalid option and field
types raise an error.

- **`denv.executors`**

    A table containing the built-in executors and any executors added through the
    target's `environment` option. Configuration is deeply merged, so a
    user-defined executor key is added without removing other built-ins. See
    [Executors](#executors) for the function contract and built-in functions.

- **`denv.file_path(options?)`**

    Expands `%:p` and returns the current buffer's absolute path. With
    `relative = true`, it expands `%` instead and returns the buffer path relative
    to the working directory. `options` accepts `escape` and `relative`.

- **`denv.file_name(options?)`**

    Expands `%:t` and returns the tail of the current buffer path, including its
    extension but excluding its directory. With `extension = false`, it expands
    `%:t:r` instead and removes the final extension. `options` accepts `escape`
    and `extension`.

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
`require("dove.opts.environment").executors`. Every executor accepts the command string
as its first argument. Terminal executors use Neovim's shell through
`:terminal`.

- **`executors.default(command)`**

    Opens `command` in a short, full-width terminal split. It runs
    `rightbelow split | wincmd J | resize -4` before opening the terminal.

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
local default_environment = require("dove.opts.environment")

default_environment.executors.split("make test", { "12" })
default_environment.executors.vsplit("make test", { "80" })
default_environment.executors.split("make test", { nil, "wincmd J | resize -3" })
```

## Lua API

`require("dove")` returns the following functions.

- **`setup(options?)`**

    Accepts a table or `nil` and returns no value. The table accepts the fields
    described under [configuration](#configuration). The function deep-merges
    the supplied values into fresh defaults, validates the complete
    configuration, and initializes the parser and runner with it. Invalid values
    raise an error. Calling `setup()` again discards the previous user options
    and repeats this process with fresh defaults.

- **`run(target_name?)`**

    Accepts an optional target-name string and returns no value. When omitted,
    it uses `unspecified_target_name`; an error is raised if none is configured.
    It resolves the target's source, evaluates and validates the source list,
    and either executes its only entry when `auto_run_single_entry` is enabled
    or passes all entries to the configured picker. The chosen command or
    function and executor become the previous task only when an entry is
    executed. An unknown target, invalid resolver, or invalid source raises an
    error. A source function returning a non-string value raises an error. A
    missing source file or empty source list prints a message. None of these
    cases replace the previous task.

- **`prev_task()`**

    Runs the last executed command or function again without reloading its
    source or changing replay history. If no task has run, it prints a message.

- **`prev_entry()`**

    Resolves the last selected entry's target again, reloads its source, and
    runs the entry at the same position. It updates replay history. If no entry
    has run or the entry is no longer available, it prints a message.

- **`edit(target_name?)`**

    Accepts an optional target-name string and returns no value. When omitted,
    it uses `unspecified_target_name`; an error is raised if none is configured.
    It resolves the target's source path, recursively creates missing parent
    directories, and opens the escaped path with `:tabedit`. If the path is not
    a readable file and the target's `new_source_file_placeholder` is a
    string, it first writes that string to the new source file. With
    `false`, it opens the file without writing a template. An unknown
    target or invalid resolver raises an error.

- **`delete_source_file(target_name)`**

    Requires a literal target-name string and returns no value. It resolves the
    target's source path and calls
    `vim.fs.rm(path, { force = true })`. No confirmation is requested, and a
    missing path is ignored. An unknown target or invalid resolver raises an
    error.

Example of binding keys:

```lua
local dove = require("dove")

-- map `<leader>dp` to run target 'project':
vim.keymap.set("n", "<Leader>dp", function()
    dove.run("project")
end, { desc = "Dove: run target project" })

-- map `<leader>df` to run target 'filetype':
vim.keymap.set("n", "<Leader>df", "<Cmd>Dove run filetype<CR>",
    { desc = "Dove: run target filetype" })
```

The behavior under [Commands](#commands) also applies to these functions.
`require("dove.opts.environment")` returns the built-in source environment for use in
configuration; see [Source environment](#source-environment) and
[Executors](#executors).

## Health Check

Run `:checkhealth dove`. It reports:

- Whether Neovim v0.12.0 or newer is running.
- Whether `setup()` was called.
- Whether the configured `shell` is executable.

## Links

- [Repository](https://github.com/pewpewnor/dove.nvim)
- [Contribute](https://github.com/pewpewnor/dove.nvim/blob/main/CONTRIBUTING.md)
- [License](https://github.com/pewpewnor/dove.nvim/blob/main/LICENSE)
