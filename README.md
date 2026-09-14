# ▶️ arbit.nvim

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

To lazy-load on the command:

```lua
{
    "pewpewnor/arbit.nvim",
    cmd = "Arbit",
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
    { name = "a", cmd = "touch hello" },
}
```

An empty source returns `return {}`.

Source files can use the configured environment through the `arbit` table:

```lua
return {
    { "go test -run " .. arbit.cword() },
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

arbit.setup({
    targets = {
        project = {
            source = function()
                return arbit.preset.cwd_path() .. "/.arbit.lua"
            end,
            auto_run_single_command = true,
            default_executor = arbit.preset.executors.split,
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
    display = {
        numbered = false,
        last_entry_new_line = false,
    },
})
```

A target's `source` is a resolver function, or a list of resolver functions.
Resolvers take no arguments and return a path or `nil`. When given a list,
arbit.nvim uses the first readable path and falls back to the first resolved
path when creating a file.

The built-in source environment contains:

- `arbit.executors`
- `arbit.file_path()`, `arbit.file_path_relative()`
- `arbit.file_name()`, `arbit.file_name_no_extension()`
- `arbit.file_type()`, `arbit.file_extension()`
- `arbit.dir_path()`, `arbit.dir_name()`
- `arbit.cwd_path()`, `arbit.cwd_name()`
- `arbit.config_path()`, `arbit.data_path()`, `arbit.arbit_data_path()`
- `arbit.cword()`, `arbit.cWORD()`, `arbit.hash_sha256(value)`

## Built-in executors

Source files use these through `arbit.executors`, for example
`executor = arbit.executors.bg_silent`. Plugin configuration uses the public
`arbit.preset.executors` names shown below.

| Executor | Behavior |
| -------- | -------- |
| `arbit.preset.executors.new_tab` | Terminal in a new tab |
| `arbit.preset.executors.current_buffer` | Terminal in the current buffer |
| `arbit.preset.executors.split` | Terminal in a horizontal split |
| `arbit.preset.executors.vsplit` | Terminal in a vertical split |
| `arbit.preset.executors.print` | Run synchronously and print output |
| `arbit.preset.executors.silent` | Run synchronously without output |
| `arbit.preset.executors.bg_silent` | Run asynchronously without output |
| `arbit.preset.executors.bg_exit_status` | Run asynchronously and print the exit status |

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
