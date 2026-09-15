# Agent guidelines

## Project

dove.nvim is a Neovim plugin that runs project and file commands from Lua
source files. It supports custom targets, environment values, executors, and
source imports.

## Before editing

- Read `README.md` before making changes. It states the required Neovim version.
- Inspect similar code and tests first.
- Follow existing names and patterns.
- Preserve unrelated worktree changes.

Use current Neovim APIs. Do not restore legacy compatibility unless requested.

## Code rules

- Do not add comments unless a linter requires them.
- Keep every `vim.*` call in `lua/dove/common.lua`, including calls needed by
  tests. Add a wrapper when one is missing.
- Use `common.validate` for configuration and argument type checks.
- Format errors and `print()` messages as
  `dove.nvim: <lowercase message without a trailing period>`.

## Documentation rules

Everything in `doc/` is generated with panvimdoc. Update the source
documentation and regenerate the generated files instead of editing `doc/`
directly.

## Tests

Aftter editing any source code file (non-documentation), update the matching test
file when behavior, exports, or signatures change.
Add only useful behavioral coverage; do not add module-load tests.

At the end of every final change to source code, run:

```bash
make test
stylua --check .
lua-language-server --check=. --checklevel=Warning --check_out_path=/tmp/dove-luals-check.json
```

If you are unable to find these tools in path, search them on mason.nvim install
directory.

## When changing the required Neovim version

When changing the minimum version, update all of these:

- `README.md`: the `_Requirement: Neovim vX.Y.x_` line.
- `docs/dove.md`: the minimum-version line.
- `scripts/generate-vimdoc.sh`: the `--vim-version 'NVIM vX.Y.0'` flag.
- `lua/dove/health.lua`: the `common.has("nvim-X.Y")` check and its messages.

The CI workflow has its own Neovim version. Change that pin only when CI needs a
different version.
