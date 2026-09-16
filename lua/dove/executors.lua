local common = require("dove.common")

local M = {}

---@type dove.Executor
---@param args? string[] Optional arguments:
--- - `args[1]`: Ex count placed before `tabnew`.
function M.new_tab(command, args)
    args = args or {}
    if #args == 0 then
        common.cmd("tabnew | terminal " .. command)
    else
        common.cmd(args[1] .. "tabnew | terminal " .. command)
    end
end

---@type dove.Executor
function M.current_buffer(command)
    common.cmd("terminal " .. command)
end

---@type dove.Executor
---@param args? string[] Optional arguments:
--- - `args[1]`: Split height.
--- - `args[2]`: Ex command run after creating the split and before opening the terminal.
function M.split(command, args)
    args = args or {}
    local split = (args[1] and args[1] .. " " or "") .. "split"
    if args[2] then
        split = split .. " | " .. args[2]
    end
    common.cmd("rightbelow " .. split .. " | terminal " .. command)
end

---@type dove.Executor
---@param args? string[] Optional arguments:
--- - `args[1]`: Split width.
function M.vsplit(command, args)
    args = args or {}
    if #args == 0 then
        common.cmd("botright vsplit | terminal " .. command)
    else
        common.cmd(args[1] .. " vsplit | terminal " .. command)
    end
end

---@type dove.Executor
function M.silent(command)
    common.run_shell_silent(command)
end

---@type dove.Executor
function M.print(command)
    print(common.run_shell_output(command))
end

---@type dove.Executor
function M.bg_silent(command)
    common.run_shell_async(command)
end

---@type dove.Executor
function M.bg_status(command)
    common.run_shell_async(command, function(result)
        print(
            result.code == 0 and "command success (exit code = 0)"
                or string.format("command error (exit code = %d)", result.code)
        )
    end)
end

return M
