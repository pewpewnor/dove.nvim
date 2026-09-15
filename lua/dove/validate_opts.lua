local common = require("dove.common")
local default = require("dove.default")

---@param targets dove.Targets
local function fill_and_validate_targets(targets)
    for target_name, target_config in pairs(targets) do
        common.validate("targets." .. target_name, target_config, "table")
        targets[target_name] = default.fill_target(target_config)
        target_config = targets[target_name]

        common.validate(
            "targets." .. target_name .. ".source_path",
            target_config.source_path,
            { "function", "table" }
        )
        if type(target_config.source_path) == "table" then
            if
                not common.is_list(target_config.source_path)
                or #target_config.source_path == 0
            then
                error(
                    "dove.nvim: targets."
                        .. target_name
                        .. ".source_path must be a non-empty list of functions"
                )
            end
            for index, resolver in ipairs(target_config.source_path) do
                common.validate(
                    "targets." .. target_name .. ".source_path." .. index,
                    resolver,
                    "function"
                )
            end
        end
        common.validate(
            "targets." .. target_name .. ".auto_run_single_command",
            target_config.auto_run_single_command,
            "boolean"
        )
        common.validate(
            "targets." .. target_name .. ".default_executor",
            target_config.default_executor,
            "function"
        )
    end
end

---@param options dove.Config
local function validate_opts(options)
    common.validate("options", options, "table")
    common.validate("options.environment", options.environment, "table")
    common.validate(
        "options.cmd_list_delimiter",
        options.cmd_list_delimiter,
        "string"
    )
    common.validate(
        "options.write_template_to_new_source_file",
        options.write_template_to_new_source_file,
        "boolean"
    )
    common.validate("options.ui", options.ui, "table")
    common.validate("options.ui.picker", options.ui.picker, "function")
    common.validate(
        "options.ui.enumerate_entries",
        options.ui.enumerate_entries,
        "boolean"
    )
    common.validate("options.targets", options.targets, "table")
    fill_and_validate_targets(options.targets)
end

return validate_opts
