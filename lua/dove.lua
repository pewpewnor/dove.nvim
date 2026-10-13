local common = require("dove.common")
local create_opts = require("dove.opts.create")
local module = require("dove.module")
local validate_opts = require("dove.opts.validate")

local M = {}

---@param options table?
function M.setup(options)
    common.validate("options", options, { "table", "nil" })
    local config = create_opts(options)
    validate_opts(config)
    module.init(config)
end

M.run_target = module.run_target

M.run_prev_task = module.run_prev_task

M.edit_source_file = module.edit_source_file

M.delete_source_file = module.delete_source_file

return M
