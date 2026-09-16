panvimdoc.sh \
    --project-name 'dove' \
    --input-file 'docs/dove.md' \
    --vim-version 'NVIM v0.12.0' \
    --description 'Define and execute commands with Lua for files, projects, etc.' \
    --toc 'true' \
    --treesitter 'true'

nvim --headless -u NONE -c 'helptags doc' -c 'qa'
