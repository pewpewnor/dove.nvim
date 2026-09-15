---@class ProcessedTarget
---@field name string
---@field source_path string
---@field auto_run_single_command boolean
---@field default_executor Executor

---@class Task
---@field command string
---@field executor Executor
---@field args string[]

local parser = require("dove.parser")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@type Task|nil
M.last_executed_task = nil

---@param task Task
local function execute_task(task)
    task.executor(task.command, task.args)
end

---@param entry ProcessedEntry
---@param default_executor Executor
local function run_entry(entry, default_executor)
    local executor = entry.executor or default_executor

    M.last_executed_task = {
        command = entry.command,
        executor = executor,
        args = {},
    }
    execute_task(M.last_executed_task)
end

---@param target ProcessedTarget
function M.select_and_run_entry(target)
    local entries = parser.parse_source_file(target.source_path)
    if not entries then
        return
    end

    if #entries == 0 then
        print(
            string.format(
                "dove.nvim: no entries in the source file for '%s'",
                target.name
            )
        )
        return
    end

    if #entries == 1 and target.auto_run_single_command then
        return run_entry(entries[1], target.default_executor)
    end

    local entry_indices = {}
    for index, entry in ipairs(entries) do
        entry_indices[entry] = index
    end
    M.config.selection.picker(entries, {
        prompt = string.format("Dove: run target = '%s'", target.name),
        format_item = function(entry)
            if M.config.selection.enumerate_entries then
                return entry_indices[entry] .. ". " .. entry.name
            end
            return entry.name
        end,
    }, function(chosen_entry)
        if chosen_entry then
            return run_entry(chosen_entry, target.default_executor)
        end
    end)
end

function M.run_prev_task()
    if not M.last_executed_task then
        print("dove.nvim: no previously executed task")
        return
    end
    execute_task(M.last_executed_task)
end

return M
