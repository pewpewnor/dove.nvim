panvimdoc.sh \
    --project-name 'dove' \
    --input-file 'docs/dove.md' \
    --vim-version 'NVIM v0.12.0' \
    --description 'Run project and file commands from Lua source files in Neovim.' \
    --toc 'true' \
    --treesitter 'true'

nvim --headless -u NONE -c 'helptags doc' -c 'qa'
