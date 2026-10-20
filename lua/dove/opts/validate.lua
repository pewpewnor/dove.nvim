local common = require("dove.common")

---@param target_config dove.Target|dove.ParentTarget|dove.TargetOption
---@param prefix string
---@param not_parent_target boolean
local function validate_target(target_config, prefix, not_parent_target)
    common.validate(prefix, target_config, "table")
    if not_parent_target and target_config.source == nil then
        error("dove.nvim: " .. prefix .. ".source is required")
    end
    if target_config.source ~= nil then
        common.validate(prefix .. ".source", target_config.source, "function")
    end
    common.validate(
        prefix .. ".auto_run_single_entry",
        target_config.auto_run_single_entry,
        "boolean"
    )
    common.validate(prefix .. ".executor", target_config.executor, "function")
    common.validate(
        prefix .. ".environment",
        target_config.environment,
        "table"
    )
    common.validate(
        prefix .. ".cmd_list_delimiter",
        target_config.cmd_list_delimiter,
        "function"
    )
    if target_config.new_source_file_placeholder ~= false then
        common.validate(
            prefix .. ".new_source_file_placeholder",
            target_config.new_source_file_placeholder,
            "string"
        )
    end
end

---@param targets dove.Targets
local function validate_targets(targets)
    for target_name, target_config in pairs(targets) do
        validate_target(target_config, "targets." .. target_name, true)
    end
end

---@param options dove.ResolvedOptions
local function validate_opts(options)
    common.validate("options", options, "table")
    common.validate(
        "options.unspecified_target_name",
        options.unspecified_target_name,
        { "function", "string", "nil" }
    )
    common.validate("options.parent_target", options.parent_target, "table")
    if next(options.parent_target) ~= nil then
        validate_target(options.parent_target, "options.parent_target", false)
    end
    common.validate("options.ui", options.ui, "table")
    common.validate("options.ui.picker", options.ui.picker, "function")
    common.validate(
        "options.ui.format_selection_item",
        options.ui.format_selection_item,
        "function"
    )
    common.validate("options.targets", options.targets, "table")
    validate_targets(options.targets)
end

return validate_opts
