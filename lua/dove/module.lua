local pathfinder = require("dove.pathfinder")
local runner = require("dove.source.runner")
local common = require("dove.common")

local M = {}

---@param config dove.ResolvedOptions
function M.init(config)
    ---@type dove.ResolvedOptions
    M.config = config
    require("dove.source.parser").init(config)
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

---@param target_name string?
---@return dove.Target, string
local function find_target(target_name)
    ensure_setup()

    local resolved_target_name = target_name
    if resolved_target_name == nil then
        local unspecified_target_name = M.config.unspecified_target_name
        if unspecified_target_name == nil then
            error("dove.nvim: no unspecified target name is configured")
        end
        if type(unspecified_target_name) == "function" then
            resolved_target_name = unspecified_target_name()
        else
            resolved_target_name = unspecified_target_name
        end
    end
    common.validate(
        target_name == nil and "unspecified_target_name" or "target_name",
        resolved_target_name,
        "string"
    )
    local target = M.config.targets[resolved_target_name]
    if not target then
        error(
            string.format(
                "dove.nvim: target '%s' does not exist",
                resolved_target_name
            )
        )
    end
    return target, resolved_target_name
end

---@param target_name string?
---@return any
function M.run(target_name)
    local target, resolved_target_name = find_target(target_name)
    local source = pathfinder(target.source)
    return runner.select_and_run_entry({
        name = resolved_target_name,
        source = source,
        auto_run_single_entry = target.auto_run_single_entry,
        default_executor = target.default_executor,
    })
end

function M.prev_task()
    ensure_setup()
    runner.run_task(runner.last_task())
end

function M.prev_entry()
    ensure_setup()
    runner.run_entry(runner.last_entry())
end

---@param target_name string?
function M.edit(target_name)
    local target = find_target(target_name)
    local path = pathfinder(target.source)
    common.mkdir_with_parents(common.dirname(path))
    if not common.is_file_and_readable(path) then
        if target.new_source_file_placeholder ~= false then
            common.write_text_file(path, target.new_source_file_placeholder)
        end
    end
    common.cmd("tabedit " .. common.fnameescape(path))
end

---@param target_name string
function M.delete_source_file(target_name)
    common.validate("target_name", target_name, "string")
    local path = pathfinder(find_target(target_name).source)
    common.path_remove(path)
end

return M
