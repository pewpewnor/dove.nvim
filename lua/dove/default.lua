---@alias PathResolver fun(environment: Environment): string?

---@alias Executor fun(command: string, args: string[]?)

---@class Executors
---@field [string] Executor

---@class Target
---@field source PathResolver|PathResolver[]
---@field auto_run_single_command boolean
---@field default_executor Executor

---@class Targets
---@field [string] Target

---@class Environment
---@field executors Executors
---@field [string] any

---@alias Picker fun(items: any[], opts: table, on_choice: fun(item: any?, index: integer?))

---@class Config
---@field targets Targets
---@field write_template_to_new_source_file boolean
---@field environment Environment
---@field picker Picker

---@class MinimumTarget
---@field source PathResolver|PathResolver[]

local common = require("dove.common")
local preset = require("dove.preset")

local M = {}

---@param minimum_target MinimumTarget
---@return Target
function M.fill_target(minimum_target)
    common.validate("minimum_target", minimum_target, "table")
    return common.tbl_deep_extend("force", {
        auto_run_single_command = true,
        default_executor = preset.executors.new_tab,
    }, minimum_target)
end

---@param options table?
---@return Config
function M.create(options)
    return common.tbl_deep_extend("force", {
        targets = {
            project = M.fill_target({
                source = function(env)
                    return common.path_join(
                        env.dove_data_path(),
                        "projects",
                        env.hash_sha256(env.cwd_path()) .. ".lua"
                    )
                end,
            }),
            filetype = M.fill_target({
                source = function(env)
                    return common.path_join(
                        env.dove_data_path(),
                        "filetypes",
                        env.file_type() .. ".lua"
                    )
                end,
            }),
        },
        write_template_to_new_source_file = true,
        environment = common.tbl_deep_extend("force", {}, preset),
        picker = require("dove.picker"),
    }, options or {})
end

return M
