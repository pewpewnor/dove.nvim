local common = require("arbit.common")

local M = {
    executors = require("arbit.executors"),
    file_path = function()
        return common.fnameescape(common.expand("%:p"))
    end,
    file_path_relative = function()
        return common.fnameescape(common.expand("%"))
    end,
    file_name = function()
        return common.fnameescape(common.expand("%:t"))
    end,
    file_name_no_extension = function()
        return common.fnameescape(common.expand("%:t:r"))
    end,
    file_type = function()
        return common.get_filetype()
    end,
    file_extension = function()
        return common.fnameescape(common.expand("%:e"))
    end,
    dir_path = function()
        return common.fnameescape(common.expand("%:p:h"))
    end,
    dir_name = function()
        return common.fnameescape(common.expand("%:p:h:t"))
    end,
    cwd_path = function()
        return common.fnameescape(common.get_cwd())
    end,
    cwd_name = function()
        return common.fnameescape(common.fnamemodify(common.get_cwd(), ":t"))
    end,
    config_path = function()
        return common.fnameescape(common.get_stdpath("config"))
    end,
    data_path = function()
        return common.fnameescape(common.get_stdpath("data"))
    end,
    arbit_data_path = function()
        local arbit_data_path =
            common.path_join(common.get_stdpath("data"), "arbit")
        common.mkdir_with_parents(arbit_data_path)
        return common.fnameescape(arbit_data_path)
    end,
    cword = function()
        return common.expand("<cword>")
    end,
    cWORD = function()
        return common.expand("<cWORD>")
    end,
    hash_sha256 = function(arg)
        return common.hash_sha256(arg)
    end,
}

return M
