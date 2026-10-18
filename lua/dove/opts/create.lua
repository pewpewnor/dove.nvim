local common = require("dove.common")
local default_opts = require("dove.opts.default")

---@param options dove.Options?
---@return dove.ResolvedOptions
local function create_opts(options)
    local config = common.tbl_deep_extend(
        "force",
        common.deepcopy(default_opts),
        options or {}
    )
    if options and options.parent_target == false then
        config.parent_target = {}
    end
    if
        type(config.parent_target) == "table"
        and type(config.targets) == "table"
    then
        for name, target in pairs(config.targets) do
            if target == false then
                config.targets[name] = nil
            elseif type(target) == "table" then
                local merged = common.tbl_deep_extend(
                    "force",
                    {},
                    config.parent_target,
                    target
                )
                config.targets[name] = merged
                if not options or options.targets == nil then
                    merged.environment = config.parent_target.environment
                end
            end
        end
    end
    return config
end

return create_opts
