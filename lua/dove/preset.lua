local common = require("dove.common")

---@param options table?
---@param attributes string[]
---@return table
local function validate_path_options(options, attributes)
    common.validate("options", options, { "table", "nil" })
    options = options or {}
    for _, name in ipairs(attributes) do
        common.validate("options." .. name, options[name], { "boolean", "nil" })
    end
    return options
end

---@param path string
---@param escape boolean?
---@return string
local function escapable_path(path, escape)
    return escape == false and path or common.fnameescape(path)
end

---@param absolute string
---@param relative string
---@param use_relative boolean?
---@return string
local function relativable_path(absolute, relative, use_relative)
    return common.expand(use_relative == true and relative or absolute)
end

local M = {
    executors = require("dove.executors"),
    file_path = function(options)
        options = validate_path_options(options, { "escape", "relative" })
        return escapable_path(
            relativable_path("%:p", "%", options.relative),
            options.escape
        )
    end,
    file_name = function(options)
        options = validate_path_options(options, { "escape", "extension" })
        return escapable_path(
            common.expand(options.extension == false and "%:t:r" or "%:t"),
            options.escape
        )
    end,
    file_extension = function(options)
        options = validate_path_options(options, { "escape" })
        return escapable_path(common.expand("%:e"), options.escape)
    end,
    file_type = function()
        return common.get_filetype()
    end,
    dir_path = function(options)
        options = validate_path_options(options, { "escape", "relative" })
        return escapable_path(
            relativable_path("%:p:h", "%:h", options.relative),
            options.escape
        )
    end,
    dir_name = function(options)
        options = validate_path_options(options, { "escape" })
        return escapable_path(common.expand("%:p:h:t"), options.escape)
    end,
    cwd_path = function(options)
        options = validate_path_options(options, { "escape" })
        return escapable_path(common.get_cwd(), options.escape)
    end,
    cwd_name = function(options)
        options = validate_path_options(options, { "escape" })
        return escapable_path(
            common.fnamemodify(common.get_cwd(), ":t"),
            options.escape
        )
    end,
    config_path = function(options)
        options = validate_path_options(options, { "escape" })
        return escapable_path(common.get_stdpath("config"), options.escape)
    end,
    data_path = function(options)
        options = validate_path_options(options, { "escape" })
        return escapable_path(common.get_stdpath("data"), options.escape)
    end,
    dove_data_path = function(options)
        options = validate_path_options(options, { "escape" })
        local dove_data_path =
            common.path_join(common.get_stdpath("data"), "dove")
        common.mkdir_with_parents(dove_data_path)
        return escapable_path(dove_data_path, options.escape)
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
