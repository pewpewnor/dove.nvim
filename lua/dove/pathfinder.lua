local common = require("dove.common")
---@param resolver dove.SourceResolver
---@return string
local function get_true_path(resolver)
    local raw_path = resolver()
    common.validate("source return value", raw_path, "string")
    return common.path_normalize(common.expand(raw_path))
end

return get_true_path
