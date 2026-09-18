local common = require("dove.common")
local preset = require("dove.preset")

local M = {}

---@param minimum_target dove.MinimumTarget
---@return dove.Target
function M.fill_target(minimum_target)
    common.validate("minimum_target", minimum_target, "table")
    return common.tbl_deep_extend("force", {
        auto_run_single_command = true,
        default_executor = function(command)
            preset.executors.split(command, { nil, "wincmd J | resize -4" })
        end,
    }, minimum_target)
end

---@param options table?
---@return dove.Config
function M.create(options)
    return common.tbl_deep_extend("force", {
        targets = {
            project = M.fill_target({
                source_path = function()
                    return common.path_join(
                        preset.dove_data_path(),
                        "projects",
                        preset.hash_sha256(preset.cwd_path()) .. ".lua"
                    )
                end,
            }),
            filetype = M.fill_target({
                source_path = function()
                    return common.path_join(
                        preset.dove_data_path(),
                        "filetypes",
                        preset.file_type() .. ".lua"
                    )
                end,
            }),
            global = M.fill_target({
                source_path = function()
                    return common.path_join(
                        preset.dove_data_path(),
                        "global.lua"
                    )
                end,
            }),
        },
        environment = {
            denv = common.tbl_deep_extend("force", {}, preset),
        },
        default_target = nil,
        cmd_list_delimiter = common.get_default_cmd_list_delimiter,
        write_template_to_new_source_file = true,
        ui = {
            picker = require("dove.picker"),
            enumerate_entries = true,
        },
    }, options or {})
end

return M
