local common = require("arbit.common")
local default = require("arbit.default")
local module = require("arbit.module")
local validate_opts = require("arbit.validate_opts")

local M = {
    preset = default.preset,
}

---@param options table?
function M.setup(options)
    local config = common.tbl_deep_extend(
        "force",
        default.opts,
        options or {}
    )
    validate_opts(config)
    module.init(config)
end

M.run_target = module.run_target

M.run_prev_task = module.run_prev_task

M.edit_source_file = module.edit_source_file

M.delete_source_file = module.delete_source_file

return M
