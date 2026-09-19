local pathfinder = require("dove.pathfinder")
local runner = require("dove.runner")
local common = require("dove.common")

local M = {}

---@param config dove.Config
function M.init(config)
    ---@type dove.Config
    M.config = config
    require("dove.parser").init(config)
    runner.init(config)
end

---@return string[]
function M.get_target_names()
    ---@type string[]
    local target_names = {}
    for target_name in pairs(M.config.targets) do
        target_names[#target_names + 1] = target_name
    end
    table.sort(target_names)
    return target_names
end

local function ensure_setup()
    if not M.config then
        error(
            "dove.nvim: setup did not complete, check for earlier errors and ensure setup is called"
        )
    end
end

---@param target_name string
---@return dove.Target
local function find_target(target_name)
    ensure_setup()
    common.validate("target_name", target_name, "string")
    local target = M.config.targets[target_name]
    if not target then
        error(
            string.format("dove.nvim: target '%s' does not exist", target_name)
        )
    end
    return target
end

---@param target_name string?
---@return any
function M.run_target(target_name)
    ensure_setup()
    if target_name == nil then
        target_name = M.config.default_run_target
        if target_name == nil then
            error("dove.nvim: no default target is configured")
        end
    end
    local target = find_target(target_name)
    return runner.select_and_run_entry({
        name = target_name,
        source_path = pathfinder.get_true_path(target.source_path),
        auto_run_single_command = target.auto_run_single_command,
        default_executor = target.default_executor,
    })
end

M.run_prev_task = runner.run_prev_task

---@param target_name string
function M.edit_source_file(target_name)
    local path = pathfinder.get_true_path(find_target(target_name).source_path)
    common.mkdir_with_parents(common.dirname(path))
    if
        M.config.write_template_to_new_source_file
        and not common.is_file_and_readable(path)
    then
        common.write_file(path, {
            "return {",
            "    {",
            '        name = "greetings",',
            "        cmd = \"echo 'Hello from dove.nvim!'\",",
            "    },",
            "}",
        }, "a")
    end
    common.cmd("tabedit " .. common.fnameescape(path))
end

---@param target_name string
function M.delete_source_file(target_name)
    local path = pathfinder.get_true_path(find_target(target_name).source_path)
    common.path_remove(path)
end

return M
