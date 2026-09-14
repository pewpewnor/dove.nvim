# Agent Guidelines

## Project

arbit.nvim is a Neovim plugin that runs project and file commands from Lua
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
- Keep every `vim.*` call in `lua/arbit/common.lua`, including calls needed by
  tests. Add a wrapper when one is missing.
- Use `common.validate` for configuration and argument type checks.
- Format errors as `arbit.nvim: <lowercase message without a trailing period>`.
- Use the same format for `print()` messages.

## When Changing Required Neovim version

When changing the minimum version, update all of these:

- `README.md`: the `_Requirement: Neovim vX.Y.x_` line.
- `docs/arbit.md`: the minimum-version line.
- `scripts/generate-vimdoc.sh`: the `--vim-version 'NVIM vX.Y.0'` flag.
- `lua/arbit/health.lua`: the `common.has("nvim-X.Y")` check and its messages.

The Makefile workflow installs Neovim without pinning a version. Change it only
when CI needs a pinned version.

## Vim Doc

Everything in the `doc/` directory is meant to be generated using panvimdoc.

## Tests

At the end of every change, run:

```bash
make test
stylua --check .
```

Update the matching test file when behavior, exports, or signatures change.
Only add useful behavioral coverage, do not add module-load tests.
