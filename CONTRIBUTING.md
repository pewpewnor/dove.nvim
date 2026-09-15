# Contributing

Bug fixes, features, and documentation improvements are welcome.

## Bug report

- Describe your environment: operating system, Neovim version, lua config, etc.
- Explain step by step how to reproduce the problem.

## Pull requests

Explain what changed and why. Link any related issue.

Use a clear commit prefix when practical:

- `fix:` for bug fixes.
- `feat:` for features.
- `test:` for test only changes.
- `docs:` for documentation only changes.
- `chore:` for codebase maintenance.

## Code guideline

- Try to follow the conventions in `AGENTS.md`.
- Update tests and documentation when behavior changes.
- Pass all checks & CI e.g. `make test`, `lua-language-server`, and `stylua`.
