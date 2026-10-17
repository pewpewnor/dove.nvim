local parser = require("dove.source.parser")
local pathfinder = require("dove.pathfinder")
local common = require("dove.common")

local M = {}

---@param config dove.Config
function M.init(config)
    ---@type dove.Config
    M.config = config
end

---@type dove.Task?
M.last_executed_task = nil

---@type dove.ExecutedEntry?
M.last_executed_entry = nil

---@param task dove.Task
local function execute_task(task)
    local command = task.command
    if type(command) == "function" then
        command()
        return
    end
    local executor = assert(task.executor)
    executor(command, task.args)
end

---@param entry dove.ProcessedEntry
---@param target dove.ProcessedTarget
---@param index integer
local function execute_entry(entry, target, index)
    local executor = entry.executor
    if type(entry.command) == "string" then
        executor = executor or target.default_executor
    end

    ---@type dove.Task
    local task = {
        command = entry.command,
        executor = executor,
        args = {},
    }
    M.last_executed_entry = { target_name = target.name, index = index }
    M.last_executed_task = task
    execute_task(task)
end

---@param target dove.ProcessedTarget
function M.select_and_run_entry(target)
    local entries = parser.parse_source_file(target.source, target.name)
    if not entries then
        return
    end

    if #entries == 0 then
        print(
            string.format("dove.nvim: no entries for target '%s'", target.name)
        )
        return
    end

    if #entries == 1 and target.auto_run_single_entry then
        return execute_entry(entries[1], target, 1)
    end

    ---@type table<dove.ProcessedEntry, integer>
    local entry_indices = {}
    for index, entry in ipairs(entries) do
        entry_indices[entry] = index
    end
    M.config.ui.picker(entries, {
        prompt = string.format("Dove: run target = '%s'", target.name),
        format_item = function(entry)
            return M.config.ui.format_selection_item(
                entry.name,
                entry_indices[entry]
            )
        end,
    }, function(chosen_entry)
        if chosen_entry then
            return execute_entry(
                chosen_entry,
                target,
                entry_indices[chosen_entry]
            )
        end
    end)
end

---@return dove.Task?
function M.last_task()
    if not M.last_executed_task then
        return nil
    end
    return common.deepcopy(M.last_executed_task)
end

---@param task dove.Task?
function M.run_task(task)
    if task == nil then
        print("dove.nvim: no previously executed task")
        return
    end
    common.validate("task", task, "table")
    common.validate("task.command", task.command, { "string", "function" })
    if type(task.command) == "string" then
        common.validate("task.executor", task.executor, "function")
    end
    common.validate("task.args", task.args, "table")
    execute_task(task)
end

---@return dove.ExecutedEntry?
function M.last_entry()
    if not M.last_executed_entry then
        return nil
    end
    return common.deepcopy(M.last_executed_entry)
end

---@param previous dove.ExecutedEntry?
function M.run_entry(previous)
    if previous == nil then
        print("dove.nvim: no previously executed entry")
        return
    end
    common.validate("entry", previous, "table")
    common.validate("entry.target_name", previous.target_name, "string")
    common.validate("entry.index", previous.index, "number")
    local target_config = M.config.targets[previous.target_name]
    if not target_config then
        error(
            string.format(
                "dove.nvim: target '%s' does not exist",
                previous.target_name
            )
        )
    end
    local source = pathfinder(target_config.source)
    ---@type dove.ProcessedTarget
    local target = {
        name = previous.target_name,
        source = source,
        auto_run_single_entry = target_config.auto_run_single_entry,
        default_executor = target_config.default_executor,
    }
    local entries = parser.parse_source_file(target.source, target.name)
    if not entries then
        return
    end
    local entry = entries[previous.index]
    if not entry then
        print("dove.nvim: previously executed entry is no longer available")
        return
    end
    execute_entry(entry, target, previous.index)
end

return M
