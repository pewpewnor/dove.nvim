local common = require("dove.common")
local create_opts = require("dove.opts.create")
local module = require("dove.module")
local validate_opts = require("dove.opts.validate")

local M = {}

---@param options dove.Options?
function M.setup(options)
    common.validate("options", options, { "table", "nil" })
    local config = create_opts(options)
    validate_opts(config)
    module.init(config)
end

M.run = module.run

M.prev_task = module.prev_task

M.prev_entry = module.prev_entry

M.edit = module.edit

M.delete_source_file = module.delete_source_file

return M
