# 🕊️ dove.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.12.0%2B-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io)
[![Platforms](https://img.shields.io/badge/Platforms-Linux_%7C_macOS_%7C_Windows-blue?style=for-the-badge)](#installation)
[![Documentation](https://img.shields.io/badge/Documentation-guides-blue?style=for-the-badge)](docs/dove.md)
[![License](https://img.shields.io/github/license/pewpewnor/dove.nvim?style=for-the-badge)](LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/pewpewnor/dove.nvim/makefile.yml?branch=main&style=for-the-badge&label=tests)](https://github.com/pewpewnor/dove.nvim/actions/workflows/makefile.yml)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Use Lua to define and execute arbitrary shell commands or Lua code for file,
project, or global contexts without reloading Neovim.

https://github.com/user-attachments/assets/12a4a5fd-18c2-4d5f-84a2-c15132cd8bae

## How it works

dove.nvim organizes where to retrieve your custom commands into **targets**.
A target tells dove.nvim where to look for Lua files defined by you.

Think of targets as contexts: whether to define/run commands associated with the
current project, file type, or something else.

See [commands](#commands) for all available user commands.

### Step 1: Define targets (optional)

Use `Dove edit {target}` to start defining commands you can later pick and
execute.

See [built-in targets](#built-in-targets) for targets you can use without any
extra configuration. You may also add new or override any targets.

### Step 2: Write Lua code to define your commands

You may edit the Lua file associated with the target (which we refer to as the
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

Use `Dove run {target}` to run the target.

This loads the source file associated with the target (based on configured
target's source path) and retrieves the list of commands returned by the source
file.

Then choose the command you would like to execute.

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
| `:Dove run {target}`    | Run a target, or `default_run_target` when omitted |
| `:Dove prev`            | Repeat execution of the last executed entry        |
| `:Dove edit {target}`   | Open a target's source file                        |
| `:Dove delete {target}` | Delete a target's source file                      |

## Built-in Targets

| Target     | Default behaviour                                                                                                   |
| ---------- | ------------------------------------------------------------------------------------------------------------------- |
| `filetype` | Execute commands based on the current buffer's filetype, e.g. a command to compile the file and execute the binary. |
| `project`  | Execute commands for the current working directory, e.g. commands to build the project or run all tests.            |
| `global`   | Execute commands shared across all files and projects.                                                              |

## Customization Example

> [!NOTE]
> Passing `opts = {}` to lazy.nvim uses the [default configuration](docs/dove.md#default-configuration).

```lua
local dove = require("dove")
local preset = require("dove.preset")

dove.setup({
    targets = {
        -- adding our own custom target
        custom_target = {
            source_path = function()
                return "~/custom_target_source.lua"
            end,
            default_executor = preset.executors.new_tab,
        },
        -- override built-in target `project` settings
        project = {
            -- change to search these paths to find target's source file
            source_path = {
                function()
                    return preset.cwd_path() .. "/.dove.lua"
                end,
                function()
                    return preset.dove_data_path()
                        .. "/projects/"
                        .. preset.hash_sha256(preset.cwd_path())
                        .. ".lua"
                end,
            },
            -- spawn picker even when there is only 1 defined command possible
            auto_run_single_command = false,
            -- override default executor to execute in a new side buffer
            default_executor = preset.executors.split,
        },
    },
    -- everything in this table can be referenced by any target's source file
    environment = {
        -- adding our own custom variable
        custom_var = "my custom variable value",
        denv = {
            executors = {
                -- adding our own custom executors
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
            -- adding our own custom function
            custom_func = function() end,
        },
    },
    -- make `Dove run` without any specified target to run target `project`
    default_run_target = "project",
    -- override join delimeter for `cmd` defined as lists in source files
    cmd_list_delimiter = function() return " && " end,
    -- don't write template/placeholder code when editing a new source file
    new_source_file_template_code = nil,
    ui = {
        -- override picker to any vim.ui.select compatible picker
        picker = vim.ui.select,
        -- override how entry names and displayed on picker
        format_selection_item = function(name, i)
            return name .. " (" .. i .. ")"
        end,
    },
})
```

> [!TIP]
> With the above example, source files can access `custom_var`,
> `denv.executors.custom_notify`, and `denv.custom_func`.

## Writing source files

> [!TIP]
> Run `:Dove edit {target}` to edit the target's source file.

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

Every entry must be a table and must have exactly one command field:

| Field      | Details                                                                                        |
| ---------- | ---------------------------------------------------------------------------------------------- |
| `[1]`      | A function or non-empty command string. Use either this or `cmd`.                              |
| `cmd`      | A function, non-empty command string, or list of non-empty command strings. Use this or `[1]`. |
| `name`     | Optional picker label. Defaults to the command, using `tostring()` for a function.             |
| `executor` | Optional shell-command executor. Overrides the target's default executor.                      |

> [!NOTE]
> For a `cmd` list, items are joined with the string returned by
> `cmd_list_delimiter` and sent as a single shell command. The default function
> returns `"; "`, or `" & "` for `cmd.exe`.

When `[1]` or `cmd` is a function, dove.nvim calls it directly. Both the entry's
executor and the target's default executor are ignored.

### Source environment

> [!NOTE]
> Source files get built-in values through `denv`. By default, the functions
> return paths escaped for shell commands.
>
> You can use the same functions from `require("dove.preset")` in your Neovim
> configuration. See the
> [source environment reference](docs/dove.md#source-environment) for each
> function's arguments and behavior.

| Value                           | Result                                              |
| ------------------------------- | --------------------------------------------------- |
| `denv.executors`                | Built-in and configured executors                   |
| `denv.file_path(options?)`      | Escaped absolute or relative buffer path            |
| `denv.file_name(options?)`      | Escaped buffer filename                             |
| `denv.file_type()`              | Current buffer filetype                             |
| `denv.file_extension(options?)` | Escaped buffer filename extension                   |
| `denv.dir_path(options?)`       | Escaped absolute or relative buffer directory path  |
| `denv.dir_name(options?)`       | Escaped name of the directory containing the buffer |
| `denv.cwd_path(options?)`       | Escaped working-directory path                      |
| `denv.cwd_name(options?)`       | Escaped working-directory name                      |
| `denv.config_path(options?)`    | Escaped Neovim config path                          |
| `denv.data_path(options?)`      | Escaped Neovim data path                            |
| `denv.dove_data_path(options?)` | Escaped dove.nvim data path; creates it if needed   |
| `denv.cword()`                  | Word under the cursor                               |
| `denv.cWORD()`                  | WORD under the cursor                               |
| `denv.expand(value)`            | Expanded string value                               |
| `denv.hash_sha256(value)`       | SHA-256 digest of a string                          |

> [!TIP]
> Pass `{ escape = false }`, such as `denv.file_path({ escape = false })`, to
> return an unescaped path. Pass `{ relative = true }` to `file_path` or
> `dir_path` for a path relative to the working directory. Pass
> `{ extension = false }` to `file_name` to omit the final extension.

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

| Function                          | Meaning                              |
| --------------------------------- | ------------------------------------ |
| `setup(options?)`                 | Configure and initialize the plugin. |
| `run_target(target_name?)`        | Run an entry from a target.          |
| `run_prev_task()`                 | Repeat the last executed task.       |
| `edit_source_file(target_name)`   | Open a target source file.           |
| `delete_source_file(target_name)` | Delete a target source file.         |

Example of binding keys:

```lua
local dove = require("dove")

-- map `<leader>dp` to run target 'project':
vim.keymap.set("n", "<Leader>dp", function()
    dove.run_target("project")
end, { desc = "Dove: run target project" })

-- map `<leader>df` to run target 'filetype':
vim.keymap.set("n", "<Leader>df", "<CMD>Dove run filetype<CR>",
    { desc = "Dove: run target filetype" })
```

## Other things

Run `:checkhealth dove` for diagnostics.

See [the full documentation](docs/dove.md) for the complete option and
source-file reference.

See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute.
