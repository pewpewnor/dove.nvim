# ▶️ arbit.nvim

![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Run project and file commands from Lua source files in Neovim.

_Requirement: Neovim v0.12.x_

## Features

- Separate command lists for projects, filetypes, or custom targets.
- Lua source files with access to built-in and custom environment values.
- Built-in executors for tabs, splits, the current buffer, and background jobs.
- Source imports through Lua's `require()`.
- Commands for running, repeating, editing, and deleting source files.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "pewpewnor/arbit.nvim",
    opts = {},
}
```

## Commands

| Command | Action |
| ------- | ------ |
| `:Arbit run {target}` | Run a command for a target |
| `:Arbit prev` | Repeat the last command |
| `:Arbit edit {target}` | Edit a target's source file |
| `:Arbit delete {target}` | Delete a target's source file |

The default targets are `project` and `filetype`. Commands and target names
support completion.

## Source files

Run `:Arbit edit project` to create the source file for the current project. A
source file returns a list of command entries:

```lua
return {
    { "make test" },
    { name = "build & run", cmd = "make build && make run" },
    {
        "git status --short",
        name = "status",
        executor = arbit.executors.print,
    },
}
```

Every entry is a table with these fields:

- `[1]`: positional command string.
- `cmd`: command string or list of command strings.
- `name`: optional label shown in the picker.
- `executor`: optional executor function.

A `cmd` list is joined with semicolons and passed to its executor once, so every
item runs sequentially in one shell session:

```lua
return {
    {
        name = "stats for this file",
        cmd = {
            "wc " .. arbit.file_path(),
            "echo lines: $(wc -l < " .. arbit.file_path() .. ")",
            "echo words: $(wc -w < " .. arbit.file_path() .. ")",
        },
    },
}
```

A source containing only one entry must still return a list:

```lua
return {
    { "ls " .. arbit.dir_path() },
}
```

Source files can use your configured environment:

```lua
return {
    { "go test -run " .. arbit.cword(), name = "run golang tests" },
    { "gcc " .. arbit.file_path() .. " -o app" },
}
```

Import another source file with `require()`:

```lua
return {
    require("./shared.lua"),
    { "make test" },
}
```

Relative imports are resolved from the importing file.

## Configuration

The defaults work without configuration:

```lua
require("arbit").setup()
```

Example customization:

```lua
local arbit = require("arbit")
local preset = require("arbit.preset")

arbit.setup({
    targets = {
        project = {
            source = function()
                return preset.cwd_path() .. "/.arbit.lua"
            end,
            auto_run_single_command = true,
            default_executor = preset.executors.split,
        },
    },
    environment = {
        prefix = "env DEBUG=1 ",
        executors = {
            notify = function(command)
                vim.system(
                    { vim.o.shell, vim.o.shellcmdflag, command },
                    { text = true },
                    function(result) vim.notify(result.stdout) end
                )
            end,
        },
    },
    picker = vim.ui.select,
})
```

By default, arbit.nvim uses a dependency-free picker in a centered floating
window. Type in its first line to fuzzy-filter numbered entries; surrounding
spaces are ignored. Move with `<C-n>` and `<C-p>` (or the arrow keys), confirm
with `<CR>`, and cancel with `<Esc>`.
Set `picker` to any function with the same signature as `vim.ui.select` to
use another picker.

A target's `source` is a resolver function, or a list of resolver functions.
Resolvers receive the effective environment and return a path or `nil`. They
can also use the built-in values from `require("arbit.preset")`. When given a
list, arbit.nvim uses the first readable path and falls back to the first
resolved path when creating a file.

The built-in source environment contains:

| Value | Result |
| ----- | ------ |
| `arbit.executors` | Built-in and configured executors |
| `arbit.file_path()` | Escaped absolute buffer path |
| `arbit.file_path_relative()` | Escaped buffer path relative to the working directory |
| `arbit.file_name()` | Escaped buffer filename |
| `arbit.file_name_no_extension()` | Escaped buffer filename without its extension |
| `arbit.file_type()` | Current buffer filetype |
| `arbit.file_extension()` | Escaped buffer filename extension |
| `arbit.dir_path()` | Escaped directory containing the buffer |
| `arbit.dir_name()` | Escaped name of the directory containing the buffer |
| `arbit.cwd_path()` | Escaped working-directory path |
| `arbit.cwd_name()` | Escaped working-directory name |
| `arbit.config_path()` | Escaped Neovim config path |
| `arbit.data_path()` | Escaped Neovim data path |
| `arbit.arbit_data_path()` | Escaped arbit.nvim data path; creates it if needed |
| `arbit.cword()` | Word under the cursor |
| `arbit.cWORD()` | WORD under the cursor |
| `arbit.hash_sha256(value)` | SHA-256 digest of a string |

The same built-in values are returned by `require("arbit.preset")` for use in
target configuration.

## Built-in executors

Source files use `arbit.executors`. Plugin configuration gets the same functions
from `require("arbit.preset").executors`.

| Executor | Behavior |
| -------- | -------- |
| `preset.executors.new_tab` | Terminal in a new tab |
| `preset.executors.current_buffer` | Terminal in the current buffer |
| `preset.executors.split` | Terminal in a horizontal split |
| `preset.executors.vsplit` | Terminal in a vertical split |
| `preset.executors.print` | Run synchronously and print output |
| `preset.executors.silent` | Run synchronously without output |
| `preset.executors.bg_silent` | Run asynchronously without output |
| `preset.executors.bg_exit_status` | Run asynchronously and print the exit status |

## Lua API

```lua
local arbit = require("arbit")

arbit.run_target("project")
arbit.run_prev_task()
arbit.edit_source_file("filetype")
arbit.delete_source_file("project")
```

See [the full documentation](docs/arbit.md) for every option and source-file
rule. Run `:checkhealth arbit` to check the setup.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
