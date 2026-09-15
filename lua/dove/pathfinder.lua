local common = require("dove.common")
local M = {}

---@param resolver PathResolver
---@return string|nil
local function resolve_path(resolver)
    local raw_path = resolver()
    if raw_path == nil then
        return nil
    end
    common.validate("source resolver return value", raw_path, "string")
    return common.path_normalize(common.expand(raw_path))
end

---@param path_resolvers PathResolver|PathResolver[]
---@return string
function M.get_true_path(path_resolvers)
    local resolvers
    if type(path_resolvers) == "function" then
        resolvers = { path_resolvers }
    elseif type(path_resolvers) == "table" and #path_resolvers > 0 then
        resolvers = path_resolvers
    else
        error(
            "dove.nvim: target source must be a function or a list of functions"
        )
    end

    local first_path
    for _, resolver in ipairs(resolvers) do
        local path = resolve_path(resolver)
        first_path = first_path or path
        if path and common.is_file_and_readable(path) then
            return path
        end
    end

    if not first_path then
        error("dove.nvim: unexpected: no first source resolved")
    end
    return first_path
end

return M
