# 🕊️ dove.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.12.0%2B-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io)
[![Platforms](https://img.shields.io/badge/Platforms-Linux_%7C_macOS_%7C_Windows-blue?style=for-the-badge)](#installation)
[![Documentation](https://img.shields.io/badge/Documentation-guides-blue?style=for-the-badge)](docs/dove.md)
[![License](https://img.shields.io/github/license/pewpewnor/dove.nvim?style=for-the-badge)](LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/pewpewnor/dove.nvim/makefile.yml?branch=main&style=for-the-badge&label=tests)](https://github.com/pewpewnor/dove.nvim/actions/workflows/makefile.yml)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Define and execute arbitrary shell commands with Lua for files, projects, and
global contexts on the fly without reloading Neovim. I built this to compile
code + execute the binary, build + test projects, and run anything anywhere.

## How it works

dove.nvim organizes where to retrieve your custom commands into **targets**.
A target tells dove.nvim where to look for Lua files defined by you.

### Step 1: Define targets (optional)

Built-in targets that you can immediately use without extra configuration:

- Target `project` to execute commands for the current working directory, e.g.
  commands to build the project or run all tests.
- Target `filetype` to execute commands based on the current buffer's filetype,
  e.g. a command to compile the file and execute the binary.
- Target `global` to execute commands shared across all files and projects.

You may also add new targets or override any of the above.

### Step 2: Write Lua code to define your commands

You may edit the Lua file that the target will load (which we refer to as the
**source file**). Edit the source file to define your own list of commands that
can be selected later.

To help write commands efficiently:

- Use [source environment functions](#source-environment) to refer to the
  current buffer's file path, parent directory, etc. when defining commands
  within the source file.
- Use [executors](#executors) to tell dove.nvim where and how to
  execute the command, e.g. run inside a Neovim terminal or in the background.

You may also define/override variables, functions, and executors that the source
file can access. By default, all commands will be executed in a new pane.

### Step 3: Run the target and select a command to run

When you run a target, dove.nvim loads the source file found within the target's
path and retrieves its list of commands. Then it will ask you to choose one
command you would like to execute.

## Installation

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

## Commands

| Command                 | Action                                             |
| ----------------------- | -------------------------------------------------- |
| `:Dove run [target]`    | Run a target, or `default_run_target` when omitted |
| `:Dove prev`            | Repeat execution of the last executed entry        |
| `:Dove edit {target}`   | Open a target's source file                        |
| `:Dove delete {target}` | Delete a target's source file                      |

## Writing source files

> [!TIP]
> Run `:Dove edit {target}` to create the source file for the current project.

A source file must return a list of entry tables:

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
        name = "run test under cursor",
        cmd = "go test -run " .. denv.cword(),
        executor = denv.executors.new_tab,
    },
}
```

Every entry must be a table and must have exactly one command field:

| Field      | Details                                                                             |
| ---------- | ----------------------------------------------------------------------------------- |
| `[1]`      | A non-empty command string. Use either this or `cmd`.                               |
| `cmd`      | A non-empty command string or list of non-empty command strings. Use this or `[1]`. |
| `name`     | Optional picker label. Defaults to the command.                                     |
| `executor` | Optional executor. Overrides the target's default executor.                         |

> [!NOTE]
> For a `cmd` list, items are joined with the string returned by
> `cmd_list_delimiter` and sent as a single shell command. The default function
> returns `"; "`, or `" & "` for `cmd.exe`.

### Source environment

> [!NOTE]
> Source files get built-in values through `denv`. By default, the functions
> return paths escaped for shell commands.
>
> You can use the same functions from `require("dove.preset")` in your Neovim
> configuration. See the
> [source environment reference](docs/dove.md#source-environment) for each
> function's arguments and behavior.

| Value                                   | Result                                              |
| --------------------------------------- | --------------------------------------------------- |
| `denv.executors`                        | Built-in and configured executors                   |
| `denv.file_path(options?)`              | Escaped absolute or relative buffer path            |
| `denv.file_name(options?)`              | Escaped buffer filename                             |
| `denv.file_name_no_extension(options?)` | Escaped buffer filename without its extension       |
| `denv.file_type()`                      | Current buffer filetype                             |
| `denv.file_extension(options?)`         | Escaped buffer filename extension                   |
| `denv.dir_path(options?)`               | Escaped absolute or relative buffer directory path  |
| `denv.dir_name(options?)`               | Escaped name of the directory containing the buffer |
| `denv.cwd_path(options?)`               | Escaped working-directory path                      |
| `denv.cwd_name(options?)`               | Escaped working-directory name                      |
| `denv.config_path(options?)`            | Escaped Neovim config path                          |
| `denv.data_path(options?)`              | Escaped Neovim data path                            |
| `denv.dove_data_path(options?)`         | Escaped dove.nvim data path; creates it if needed   |
| `denv.cword()`                          | Word under the cursor                               |
| `denv.cWORD()`                          | WORD under the cursor                               |
| `denv.expand(value)`                    | Expanded string value                               |
| `denv.hash_sha256(value)`               | SHA-256 digest of a string                          |

> [!TIP]
> Pass `{ escape = false }`, such as `denv.file_path({ escape = false })`, to
> return an unescaped path. Pass `{ relative = true }` to `file_path` or
> `dir_path` for a path relative to the working directory.

### Executors

> [!NOTE]
> In source files, select a built-in or configured executor through
> `denv.executors`.
>
> You can use the same executors from `require("dove.preset").executors` in your
> Neovim configuration. See the [executor reference](docs/dove.md#executors)
> for each executor's arguments and behavior.

| Executor                   | Behavior                                       |
| -------------------------- | ---------------------------------------------- |
| `executors.new_tab`        | Opens a terminal in a new tab                  |
| `executors.current_buffer` | Opens a terminal in the current buffer         |
| `executors.split`          | Opens a terminal in a horizontal split         |
| `executors.vsplit`         | Opens a terminal in a vertical split           |
| `executors.print`          | Runs synchronously and prints stdout           |
| `executors.silent`         | Runs synchronously without output              |
| `executors.bg_silent`      | Runs asynchronously without output             |
| `executors.bg_status`      | Runs asynchronously and prints the exit status |

### Imports

Importing another source file's commands with `require()`:

```lua
return {
    require("./adjacent.lua"),
    { "make test" },
    require("../parent.lua"),
    require("~/commands/common.lua"),
}
```

## Configuration

> [!NOTE]
> Passing `opts = {}` to lazy.nvim uses the [default configuration](docs/dove.md#default-configuration).

Example extensive customization:

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
    default_run_target = "project",
    cmd_list_delimiter = function() return " && " end,
    write_template_to_new_source_file = false,
    ui = {
        picker = vim.ui.select,
        format_selection_item = function(name, i)
            return name .. " (" .. i .. ")"
        end,
    },
})
```

> [!NOTE]
> With the above example, source files can access `custom_var`,
> `denv.executors.custom_notify`, and `denv.custom_func`.

### Targets

| Option                    | Details                                                                                                 |
| ------------------------- | ------------------------------------------------------------------------------------------------------- |
| `source_path`             | A resolver function or a non-empty list of resolver functions.                                          |
| `auto_run_single_command` | Run one entry without opening the picker. Defaults to `true`.                                           |
| `default_executor`        | Executor used when an entry does not set one. Defaults to a short, full-width `preset.executors.split`. |

Resolver functions must returns a string path. Use `require("dove.preset")` for
built-in path values. With a list, dove.nvim uses the first readable path, or
the first returned path when `:Dove edit` creates it.

### Other options

| Option                              | Details                                                                              |
| ----------------------------------- | ------------------------------------------------------------------------------------ |
| `environment`                       | Add source globals and customize values under `denv`.                                |
| `default_run_target`                | Target used when `run` omits its target. Defaults to `nil`.                          |
| `cmd_list_delimiter`                | Returns the separator for `cmd` lists. Defaults to `"; "` or `" & "` with `cmd.exe`. |
| `write_template_to_new_source_file` | Write a template when `:Dove edit` opens a missing file. Defaults to `true`.         |
| `ui`                                | Configure the picker and selection item labels.                                      |

## Built-in picker

The built-in picker `require("dove.picker")` opens a centered floating window.

- Type letters to search/filter for entries.
- Move with arrow keys, or `<C-n>`, `<C-p>`.
- Confirm selection by pressing `<CR>`.
- Close picker with `<Esc>`.

You may change the picker by setting `ui.picker` to any `vim.ui.select`
compatible function.

## Lua API

`require("dove")` returns:

| Function                          | Meaning                             |
| --------------------------------- | ----------------------------------- |
| `setup(options?)`                 | Configure and initialize the plugin |
| `run_target(target_name?)`        | Run an entry from a target          |
| `run_prev_task()`                 | Repeat the last executed task       |
| `edit_source_file(target_name)`   | Open a target source file           |
| `delete_source_file(target_name)` | Delete a target source file         |

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

## Other things

Run `:checkhealth dove` for diagnostics.

See [the full documentation](docs/dove.md) for the complete option and
source-file reference.

See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute.
