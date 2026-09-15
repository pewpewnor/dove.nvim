# 🕊️ dove.nvim

![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Run project and file commands from Lua source files in Neovim.

_Requirement: Neovim v0.12.x_

## How it works

dove.nvim organizes where to retrieve your custom commands into **targets**.
A target tells dove.nvim where to look for Lua files defined by you.

### Step 1: Define targets (optional)

Built-in targets that you can immediately use without extra configuration:

- `project` to execute commands for current working directory, e.g. commands to
  build the project or run all tests.
- `filetype` to execute commands based on current buffer's filetype, e.g.
  command to compile the file and execute the binary.

You may also add new targets or override any of the above.

### Step 2: Write Lua code to define your commands

You may edit the Lua file that the target will load (which we refer as source
file). Edit the source file to define your own list of commands that can be
selected later.

To help write commands efficiently:

- Use preset functions to refer to current buffer's file path, parent directory,
  etc when defining commands within source file.
- Use preset executors dove.nvim where and how to execute the command, e.g. run
  inside of a Neovim terminal or in the background.

You may also define/override variables, functions, and executors that the source
file can access. By default, all commands will be executed in a new pane.

### Step 3: Run the target and select command to run

When you run a target, dove.nvim loads the source file found within the target's
path and retrieves its list of commands.
Then it will ask you to choose one command you would like to execute.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "pewpewnor/dove.nvim",
    opts = {},
}
```

## Commands

| Command                 | Action                                       |
| ----------------------- | -------------------------------------------- |
| `:Dove run {target}`    | Load a target's source file and run an entry |
| `:Dove prev`            | Repeat the last executed entry               |
| `:Dove edit {target}`   | Open a target's source file                  |
| `:Dove delete {target}` | Delete a target's source file                |

The default targets are `project` and `filetype`. Commands and target names
support completion. By default, one entry runs immediately; multiple entries
use the picker.

## Writing source files

Run `:Dove edit project` to create the source file for the current project. A
source file must return a list of entry tables:

```lua
return {
    { "make test" },
    {
        name = "build",
        cmd = "make build",
        executor = dove.executors.new_tab,
    },
    {
        name = "file stats",
        cmd = {
            "wc -l " .. dove.file_path(),
            "wc -w " .. dove.file_path(),
        },
        executor = dove.executors.print,
    },
    {
        name = "run test under cursor",
        cmd = "go test -run " .. dove.cword(),
        executor = dove.executors.bg_exit_status,
    },
}
```

Every entry must be a table with exactly one command field:

| Field      | Details                                                                     |
| ---------- | --------------------------------------------------------------------------- |
| `[1]`      | A command string. Use this or `cmd`.                                        |
| `cmd`      | A command string or a non-empty list of command strings. Use this or `[1]`. |
| `name`     | Optional picker label. Defaults to the command.                             |
| `executor` | Optional executor. Overrides the target's default executor.                 |

Do not set both `[1]` and `cmd`. A source with one entry still needs the outer
list:

```lua
return {
    { "ls " .. dove.dir_path() },
}
```

For a `cmd` list:

- Items are joined with `cmd_list_delimiter` and sent as one shell command.
- The default delimiter is `"; "` or `" & "` with `cmd.exe`.
- Set it to `" && "` to stop after the first failed item on shells that support it.

### Preset environment

Source files get these values through `dove`. Path values are escaped for shell
commands. Use the same functions from `require("dove.preset")` in configuration.

| Value                           | Result                                                |
| ------------------------------- | ----------------------------------------------------- |
| `dove.executors`                | Built-in and configured executors                     |
| `dove.file_path()`              | Escaped absolute buffer path                          |
| `dove.file_path_relative()`     | Escaped buffer path relative to the working directory |
| `dove.file_name()`              | Escaped buffer filename                               |
| `dove.file_name_no_extension()` | Escaped buffer filename without its extension         |
| `dove.file_type()`              | Current buffer filetype                               |
| `dove.file_extension()`         | Escaped buffer filename extension                     |
| `dove.dir_path()`               | Escaped directory containing the buffer               |
| `dove.dir_name()`               | Escaped name of the directory containing the buffer   |
| `dove.cwd_path()`               | Escaped working-directory path                        |
| `dove.cwd_name()`               | Escaped working-directory name                        |
| `dove.config_path()`            | Escaped Neovim config path                            |
| `dove.data_path()`              | Escaped Neovim data path                              |
| `dove.dove_data_path()`         | Escaped dove.nvim data path; creates it if needed     |
| `dove.cword()`                  | Word under the cursor                                 |
| `dove.cWORD()`                  | WORD under the cursor                                 |
| `dove.hash_sha256(value)`       | SHA-256 digest of a string                            |

### Preset executors

Use `dove.executors` in source files and
`require("dove.preset").executors` in configuration.

| Executor                          | Behavior                                       |
| --------------------------------- | ---------------------------------------------- |
| `preset.executors.new_tab`        | Opens a terminal in a new tab                  |
| `preset.executors.current_buffer` | Opens a terminal in the current buffer         |
| `preset.executors.split`          | Opens a terminal in a horizontal split         |
| `preset.executors.bottom_split`   | Opens a full-width terminal below all windows  |
| `preset.executors.vsplit`         | Opens a terminal in a vertical split           |
| `preset.executors.print`          | Runs synchronously and prints stdout           |
| `preset.executors.silent`         | Runs synchronously without output              |
| `preset.executors.bg_silent`      | Runs asynchronously without output             |
| `preset.executors.bg_exit_status` | Runs asynchronously and prints the exit status |

### Imports

Import another source list with `require()`:

```lua
return {
    require("./shared.lua"),
    require("~/commands/common.lua"),
    { "make test" },
}
```

Paths starting with `/`, `~`, `./`, or `../`, and names ending in `.lua`, load
source files. Other names use Lua's normal `require()`. Imported lists are
flattened, and relative paths start from the importing file.

## Configuration

Passing `opts = {}` to lazy.nvim uses the defaults. To customize them:

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
        dove = {
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
    cmd_list_delimiter = " && ",
    write_template_to_new_source_file = false,
    selection = {
        picker = vim.ui.select,
        enumerate_entries = false,
    },
})
```

In the example, source files would be able to access the custom values as
`custom_var`, `dove.executors.custom_notify`, and `dove.custom_func`.

### Targets

| Option                    | Details                                                                               |
| ------------------------- | ------------------------------------------------------------------------------------- |
| `source_path`             | A resolver function or a non-empty list of resolver functions.                        |
| `auto_run_single_command` | Run one entry without opening the picker. Defaults to `true`.                         |
| `default_executor`        | Executor used when an entry does not set one. Defaults to `preset.executors.bottom_split`. |

A resolver takes no arguments and returns a path. Use `require("dove.preset")`
for built-in path values. With a list, dove.nvim uses the first readable path,
or the first returned path when `:Dove edit` creates it.

### Other options

| Option                              | Details                                                                      |
| ----------------------------------- | ---------------------------------------------------------------------------- |
| `cmd_list_delimiter`                | Separator for `cmd` lists. Defaults to `"; "` or `" & "` with `cmd.exe`.     |
| `write_template_to_new_source_file` | Write a template when `:Dove edit` opens a missing file. Defaults to `true`. |
| `environment`                       | Add or replace values available as `dove.*`.                                 |
| `selection`                         | Configure the picker and whether entry labels are numbered.                  |

## Built-in picker

The built-in picker opens in a centered floating window.

- Type letters to search/filter for entries.
- Move with arrow keys, or `<C-n>`, `<C-p>`.
- Confirm selection by pressing `<CR>`.
- Close picker with `<Esc>`.

Set `selection.picker` to any `vim.ui.select`-compatible function to use
another picker. `selection.enumerate_entries` defaults to `true`; set it to
`false` to omit the `"<number>. "` prefix from entry labels.

## Lua API

`require("dove")` returns:

| Function                          | Meaning                             |
| --------------------------------- | ----------------------------------- |
| `setup(options?)`                 | Configure and initialize the plugin |
| `run_target(target_name)`         | Run an entry from a target          |
| `run_prev_task()`                 | Repeat the last executed task       |
| `edit_source_file(target_name)`   | Open a target source file           |
| `delete_source_file(target_name)` | Delete a target source file         |

Run `:checkhealth dove` for setup diagnostics.

See [the full documentation](docs/dove.md) for the complete option and
source-file reference. See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute.
