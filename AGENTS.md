# Agent Guidelines

## Project

dove.nvim is a Neovim plugin that runs project and file commands from Lua
source files. It supports custom targets, environment values, executors, and
source imports.

Read `README.md` before making changes. It states the required Neovim version.
Use current APIs only, do not restore legacy compatibility unless requested.

## Before editing

- Inspect similar code and tests first.
- Follow existing names and patterns.
- Preserve unrelated worktree changes.

## Code rules

- Do not add comments unless a linter requires them.
- Keep every `vim.*` call in `lua/dove/common.lua`, including calls needed by
  tests. Add a wrapper when one is missing.
- Use `common.validate` for configuration and argument type checks.
- Format errors as `dove.nvim: <lowercase message without a trailing period>`.
- Use the same format for `print()` messages.

## When Changing Required Neovim version

When changing the minimum version, update all of these:

- `README.md`: the `_Requirement: Neovim vX.Y.x_` line.
- `docs/dove.md`: the minimum-version line.
- `scripts/generate-vimdoc.sh`: the `--vim-version 'NVIM vX.Y.0'` flag.
- `lua/dove/health.lua`: the `common.has("nvim-X.Y")` check and its messages.

The Makefile workflow installs Neovim without pinning a version. Change it only
when CI needs a pinned version.

## Vim Doc

Everything in the `doc/` directory is meant to be generated using panvimdoc.

## Tests

At the end of every change, run:

```bash
make test
stylua --check .
lua-language-server --check=. --checklevel=Warning --check_out_path=/tmp/dove-luals-check.json
```

The LuaLS diagnosis must report no problems.

Update the matching test file when behavior, exports, or signatures change.
Only add useful behavioral coverage, do not add module-load tests.
