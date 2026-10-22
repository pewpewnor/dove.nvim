#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -d vendor/panvimdoc ]]; then
    git clone --branch v6.0.0 --depth 1 https://github.com/kdheepak/panvimdoc.git vendor/panvimdoc
elif [[ ! -f vendor/panvimdoc/panvimdoc.sh ]]; then
    printf 'dove.nvim: vendor/panvimdoc exists but panvimdoc.sh is missing\n' >&2
    exit 1
else
    if [[ -n "$(git -C vendor/panvimdoc status --porcelain)" ]]; then
        printf 'dove.nvim: vendor/panvimdoc has local changes\n' >&2
        exit 1
    fi
    if ! git -C vendor/panvimdoc show-ref --verify --quiet refs/tags/v6.0.0; then
        git -C vendor/panvimdoc fetch --depth 1 origin tag v6.0.0
    fi
    git -C vendor/panvimdoc checkout --detach v6.0.0
fi

git config --local core.hooksPath .githooks
