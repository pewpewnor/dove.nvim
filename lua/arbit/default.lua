---@alias PathResolver fun(): string?

---@alias Executor fun(command: string, args: string[]?)

---@class Executors
---@field [string] Executor

---@class Target
---@field source PathResolver|PathResolver[]
---@field auto_run_single_command boolean
---@field default_executor Executor

---@class Targets
---@field [string] Target

---@class EnvironmentArbit
---@field executors Executors
---@field [string] any

---@class Environment
---@field arbit EnvironmentArbit

---@class Display
---@field numbered boolean
---@field last_entry_new_line boolean

---@class Config
---@field targets Targets
---@field write_template_to_new_source_file boolean
---@field environment Environment
---@field display Display

---@class MinimumTarget
---@field source PathResolver|PathResolver[]

local common = require("arbit.common")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@type EnvironmentArbit
M.preset = {
    executors = require("arbit.preset_executors"),
    file_path = function()
        return common.fnameescape(common.expand("%:p"))
    end,
    file_path_relative = function()
        return common.fnameescape(common.expand("%"))
    end,
    file_name = function()
        return common.fnameescape(common.expand("%:t"))
    end,
    file_name_no_extension = function()
        return common.fnameescape(common.expand("%:t:r"))
    end,
    file_type = function()
        return common.get_filetype()
    end,
    file_extension = function()
        return common.fnameescape(common.expand("%:e"))
    end,
    dir_path = function()
        return common.fnameescape(common.expand("%:p:h"))
    end,
    dir_name = function()
        return common.fnameescape(common.expand("%:p:h:t"))
    end,
    cwd_path = function()
        return common.fnameescape(common.get_cwd())
    end,
    cwd_name = function()
        return common.fnameescape(common.fnamemodify(common.get_cwd(), ":t"))
    end,
    config_path = function()
        return common.fnameescape(common.get_stdpath("config"))
    end,
    data_path = function()
        return common.fnameescape(common.get_stdpath("data"))
    end,
    arbit_data_path = function()
        local arbit_data_path =
            common.path_join(common.get_stdpath("data"), "arbit")
        common.mkdir_with_parents(arbit_data_path)
        return common.fnameescape(arbit_data_path)
    end,
    cword = function()
        return common.expand("<cword>")
    end,
    cWORD = function()
        return common.expand("<cWORD>")
    end,
    hash_sha256 = function(arg)
        return common.hash_sha256(arg)
    end,
}

---@param minimum_target MinimumTarget
---@return Target
function M.fill_target(minimum_target)
    common.validate("minimum_target", minimum_target, "table")
    return common.tbl_deep_extend("force", {
        auto_run_single_command = true,
        default_executor = M.preset.executors.new_tab,
    }, minimum_target)
end

---@type Config
M.opts = {
    targets = {
        project = M.fill_target({
            source = function()
                local environment = M.config.environment.arbit
                return common.path_join(
                    environment.arbit_data_path(),
                    "projects",
                    environment.hash_sha256(environment.cwd_path()) .. ".lua"
                )
            end,
        }),
        filetype = M.fill_target({
            source = function()
                local environment = M.config.environment.arbit
                return common.path_join(
                    environment.arbit_data_path(),
                    "filetypes",
                    environment.file_type() .. ".lua"
                )
            end,
        }),
    },
    write_template_to_new_source_file = true,
    environment = { arbit = M.preset },
    display = {
        numbered = true,
        last_entry_new_line = false,
    },
}

return M
