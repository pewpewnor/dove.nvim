# Contributing

Bug fixes, features, and documentation improvements are welcome.

## Before Opening a Pull Request

- Keep the change focused.
- Follow the conventions in `AGENTS.md`.
- Update tests and documentation when behavior changes.
- Run the checks below from the repository root.

## Bug Reports

Report bugs by creating a new issue.

- Describe your environment, including the operating system, Neovim version,
  and Lua configuration.
- Give step-by-step instructions to reproduce the problem.

## Pull Requests

Explain what changed and why, and link any related issue. Open an issue or
discussion first when a change needs design agreement.

### Commit Messages

Use a clear commit prefix:

- `fix:` for bug fixes.
- `feat:` for features.
- `test:` for test-only changes.
- `docs:` for documentation only changes.
- `chore:` for codebase maintenance.

Write only the header for commit message except for when attributing co-authors.

### Checks

All CI checks must pass before the pull request can be merged. You may also run
these checks locally first, e.g. `make test`, `lua-language-server`, and
`stylua`.
