panvimdoc.sh \
    --project-name 'dove' \
    --input-file 'docs/dove.md' \
    --vim-version 'NVIM v0.12.0' \
    --description 'Use Lua to define and run shell commands or Lua code anywhere.' \
    --toc 'true' \
    --treesitter 'true'

nvim --headless -u NONE -c 'helptags doc' -c 'qa'
