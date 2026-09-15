---@diagnostic disable: undefined-field

local common = require("dove.common")
local dove = require("dove")

local M = {}

function M.new()
    local context = setmetatable({
        executed_commands = {},
        loader_enabled = false,
        original_cmd = common.cmd,
        original_expand = common.expand,
        original_get_shell = common.get_shell,
        temp_dir = common.get_tempname(),
    }, { __index = M })
    context.picker = function(items, _, on_choice)
        on_choice(items[1], 1)
    end
    common.mkdir_with_parents(context.temp_dir)
    rawset(common, "cmd", function() end)
    return context
end

function M:cleanup()
    if self.loader_enabled then
        common.enable_loader(false)
    end
    rawset(common, "cmd", self.original_cmd)
    rawset(common, "expand", self.original_expand)
    rawset(common, "get_shell", self.original_get_shell)
    common.path_remove_recursive(self.temp_dir)
end

function M:execute(command)
    self.executed_commands[#self.executed_commands + 1] = command
end

function M:set_common(name, value)
    rawset(common, name, value)
end

function M:setup(path, options)
    options = options or {}
    local auto_run_single_command = options.auto_run_single_command ~= false
    options.auto_run_single_command = nil
    options.ui = options.ui or {}
    options.ui.picker = options.ui.picker
        or function(...)
            return self.picker(...)
        end
    options.targets = {
        project = {
            source_path = function()
                return path
            end,
            auto_run_single_command = auto_run_single_command,
            default_executor = function(command)
                self:execute(command)
            end,
        },
    }
    dove.setup(options)
end

function M:write_source_file(path, lines)
    common.mkdir_with_parents(common.dirname(path))
    assert.is_true(common.write_file(path, lines))
end

return M
