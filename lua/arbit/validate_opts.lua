local common = require("arbit.common")
local default = require("arbit.default")

---@param targets Targets
local function fill_and_validate_targets(targets)
    for target_name, target_config in pairs(targets) do
        common.validate("targets." .. target_name, target_config, "table")
        targets[target_name] = default.fill_target(target_config)
        target_config = targets[target_name]

        common.validate(
            "targets." .. target_name .. ".source",
            target_config.source,
            { "function", "table" }
        )
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

---@param options Config
local function validate_opts(options)
    common.validate("options", options, "table")
    common.validate("options.environment", options.environment, "table")
    common.validate(
        "options.write_template_to_new_source_file",
        options.write_template_to_new_source_file,
        "boolean"
    )
    common.validate(
        "options.display.numbered",
        options.display.numbered,
        "boolean"
    )
    common.validate(
        "options.display.last_entry_new_line",
        options.display.last_entry_new_line,
        "boolean"
    )
    common.validate("options.targets", options.targets, "table")
    fill_and_validate_targets(options.targets)
end

return validate_opts
