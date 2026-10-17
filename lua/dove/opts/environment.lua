local common = require("dove.common")
local executors = require("dove.opts.executors")

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
    executors = executors,
}

---@param options table?
---@return string
function M.file_path(options)
    options = validate_path_options(options, { "escape", "relative" })
    return escapable_path(
        relativable_path("%:p", "%", options.relative),
        options.escape
    )
end

---@param options table?
---@return string
function M.file_name(options)
    options = validate_path_options(options, { "escape", "extension" })
    return escapable_path(
        common.expand(options.extension == false and "%:t:r" or "%:t"),
        options.escape
    )
end

---@param options table?
---@return string
function M.file_extension(options)
    options = validate_path_options(options, { "escape" })
    return escapable_path(common.expand("%:e"), options.escape)
end

---@return string
function M.file_type()
    return common.get_filetype()
end

---@param options table?
---@return string
function M.dir_path(options)
    options = validate_path_options(options, { "escape", "relative" })
    return escapable_path(
        relativable_path("%:p:h", "%:h", options.relative),
        options.escape
    )
end

---@param options table?
---@return string
function M.dir_name(options)
    options = validate_path_options(options, { "escape" })
    return escapable_path(common.expand("%:p:h:t"), options.escape)
end

---@param options table?
---@return string
function M.cwd_path(options)
    options = validate_path_options(options, { "escape" })
    return escapable_path(common.get_cwd(), options.escape)
end

---@param options table?
---@return string
function M.cwd_name(options)
    options = validate_path_options(options, { "escape" })
    return escapable_path(
        common.fnamemodify(common.get_cwd(), ":t"),
        options.escape
    )
end

---@param options table?
---@return string
function M.config_path(options)
    options = validate_path_options(options, { "escape" })
    return escapable_path(common.get_stdpath("config"), options.escape)
end

---@param options table?
---@return string
function M.data_path(options)
    options = validate_path_options(options, { "escape" })
    return escapable_path(common.get_stdpath("data"), options.escape)
end

---@param options table?
---@return string
function M.dove_data_path(options)
    options = validate_path_options(options, { "escape" })
    local dove_data_path = common.path_join(common.get_stdpath("data"), "dove")
    common.mkdir_with_parents(dove_data_path)
    return escapable_path(dove_data_path, options.escape)
end

---@return string
function M.cword()
    return common.expand("<cword>")
end

---@return string
function M.cWORD()
    return common.expand("<cWORD>")
end

---@param value string
---@return string
function M.expand(value)
    common.validate("value", value, "string")
    return common.expand(value)
end

---@param arg string
---@return string
function M.hash_sha256(arg)
    return common.hash_sha256(arg)
end

---@return dove.Task?
function M.last_task()
    return require("dove.source.runner").last_task()
end

---@param task dove.Task?
function M.run_task(task)
    require("dove.source.runner").run_task(task)
end

---@return dove.ExecutedEntry?
function M.last_entry()
    return require("dove.source.runner").last_entry()
end

---@param entry dove.ExecutedEntry?
function M.run_entry(entry)
    require("dove.source.runner").run_entry(entry)
end

return M
