local common = require("dove.common")
---@param target_config dove.Target|dove.FillEachTarget
---@param prefix string
---@param source_required boolean
local function validate_target(target_config, prefix, source_required)
    common.validate(prefix, target_config, "table")
    if source_required and target_config.source_path == nil then
        error("dove.nvim: " .. prefix .. ".source_path is required")
    end
    if target_config.source_path ~= nil then
        common.validate(
            prefix .. ".source_path",
            target_config.source_path,
            { "function", "table" }
        )
        if type(target_config.source_path) == "table" then
            if
                not common.is_list(target_config.source_path)
                or #target_config.source_path == 0
            then
                error(
                    "dove.nvim: "
                        .. prefix
                        .. ".source_path must be a non-empty list of functions"
                )
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            for index, resolver in ipairs(target_config.source_path) do
                common.validate(
                    prefix .. ".source_path." .. index,
                    resolver,
                    "function"
                )
            end
        end
    end
    common.validate(
        prefix .. ".auto_run_single_command",
        target_config.auto_run_single_command,
        "boolean"
    )
    common.validate(
        prefix .. ".default_executor",
        target_config.default_executor,
        "function"
    )
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
    common.validate(
        prefix .. ".new_source_file_template_code",
        target_config.new_source_file_template_code,
        { "string", "nil" }
    )
end

---@param targets dove.Targets
local function validate_targets(targets)
    for target_name, target_config in pairs(targets) do
        validate_target(target_config, "targets." .. target_name, true)
    end
end

---@param options dove.Config
local function validate_opts(options)
    common.validate("options", options, "table")
    common.validate(
        "options.default_run_target",
        options.default_run_target,
        { "function", "nil" }
    )
    validate_target(options.fill_each_target, "options.fill_each_target", false)
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
