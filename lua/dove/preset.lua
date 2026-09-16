local common = require("dove.common")

---@param escape_option boolean
---@param path string
---@return string
local function escape_path_based_on_options(escape_option, path)
    return escape_option == false and path or common.fnameescape(path)
end

---@param options table?
---@param path string
---@return string
local function escapable_path(options, path)
    common.validate("options", options, { "table", "nil" })
    options = options or {}
    common.validate("options.escape", options.escape, { "boolean", "nil" })
    return escape_path_based_on_options(options.escape, path)
end

---@param options table?
---@param absolute string
---@param relative string
---@return string
local function relativable_path(options, absolute, relative)
    common.validate("options", options, { "table", "nil" })
    options = options or {}
    common.validate("options.escape", options.escape, { "boolean", "nil" })
    common.validate("options.relative", options.relative, { "boolean", "nil" })
    local path =
        common.expand(options.relative == true and relative or absolute)
    return escape_path_based_on_options(options.escape, path)
end

local M = {
    executors = require("dove.executors"),
    file_path = function(options)
        return relativable_path(options, "%:p", "%")
    end,
    file_name = function(options)
        return escapable_path(options, common.expand("%:t"))
    end,
    file_name_no_extension = function(options)
        return escapable_path(options, common.expand("%:t:r"))
    end,
    file_type = function()
        return common.get_filetype()
    end,
    file_extension = function(options)
        return escapable_path(options, common.expand("%:e"))
    end,
    dir_path = function(options)
        return relativable_path(options, "%:p:h", "%:h")
    end,
    dir_name = function(options)
        return escapable_path(options, common.expand("%:p:h:t"))
    end,
    cwd_path = function(options)
        return escapable_path(options, common.get_cwd())
    end,
    cwd_name = function(options)
        return escapable_path(
            options,
            common.fnamemodify(common.get_cwd(), ":t")
        )
    end,
    config_path = function(options)
        return escapable_path(options, common.get_stdpath("config"))
    end,
    data_path = function(options)
        return escapable_path(options, common.get_stdpath("data"))
    end,
    dove_data_path = function(options)
        local dove_data_path =
            common.path_join(common.get_stdpath("data"), "dove")
        common.mkdir_with_parents(dove_data_path)
        return escapable_path(options, dove_data_path)
    end,
    cword = function()
        return common.expand("<cword>")
    end,
    cWORD = function()
        return common.expand("<cWORD>")
    end,
    expand = function(value)
        common.validate("value", value, "string")
        return common.expand(value)
    end,
    hash_sha256 = function(arg)
        return common.hash_sha256(arg)
    end,
}

return M
