---@alias PathResolver fun(): string?

---@alias Executor fun(command: string, args: string[]?)

---@class Executors
---@field [string] Executor

---@class Target
---@field source_path PathResolver|PathResolver[]
---@field auto_run_single_command boolean
---@field default_executor Executor

---@class Targets
---@field [string] Target

---@class Environment
---@field executors Executors
---@field [string] any

---@alias Picker fun(items: any[], opts: table, on_choice: fun(item: any?, index: integer?))

---@class Ui
---@field picker Picker
---@field enumerate_entries boolean

---@class Config
---@field targets Targets
---@field environment Environment
---@field cmd_list_delimiter string
---@field write_template_to_new_source_file boolean
---@field ui Ui

---@class MinimumTarget
---@field source_path PathResolver|PathResolver[]

local common = require("dove.common")
local preset = require("dove.preset")

local M = {}

---@param minimum_target MinimumTarget
---@return Target
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
---@return Config
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
        },
        environment = common.tbl_deep_extend("force", {}, preset),
        cmd_list_delimiter = common.get_default_cmd_list_delimiter(),
        write_template_to_new_source_file = true,
        ui = {
            picker = require("dove.picker"),
            enumerate_entries = true,
        },
    }, options or {})
end

return M
