local common = require("dove.common")
local default_opts = require("dove.opts.default")

---@param options table?
---@return dove.Config
local function create_opts(options)
    local config = common.tbl_deep_extend(
        "force",
        common.deepcopy(default_opts),
        options or {}
    )
    if
        type(config.parent_target) == "table"
        and type(config.targets) == "table"
    then
        for name, target in pairs(config.targets) do
            if type(target) == "table" then
                local merged = common.tbl_deep_extend(
                    "force",
                    {},
                    config.parent_target,
                    target
                )
                if merged.ignore == true then
                    config.targets[name] = nil
                else
                    config.targets[name] = merged
                    if not options or options.targets == nil then
                        merged.environment = config.parent_target.environment
                    end
                end
            end
        end
    end
    return config
end

return create_opts
