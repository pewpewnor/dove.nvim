local common = require("dove.common")
local module = require("dove.module")
local dove = require("dove")

---@type table<string, dove.Subcommand>
local subcommands = {
    run = {
        func = dove.run_target,
        takes_target = true,
        target_optional = true,
    },
    prev = { func = dove.run_prev_task, takes_target = false },
    edit = { func = dove.edit_source_file, takes_target = true },
    delete = { func = dove.delete_source_file, takes_target = true },
}

---@type string[]
local subcommand_names = {}
for subcommand_name in pairs(subcommands) do
    subcommand_names[#subcommand_names + 1] = subcommand_name
end
table.sort(subcommand_names)

---@param candidates string[]
---@param arg_lead string
---@return string[]
local function filter_by_prefix(candidates, arg_lead)
    ---@type string[]
    local matches = {}
    for _, candidate in ipairs(candidates) do
        if candidate:sub(1, #arg_lead) == arg_lead then
            matches[#matches + 1] = candidate
        end
    end
    return matches
end

---@param arg_lead string
---@param cmd_line string
---@return string[]
local function complete(arg_lead, cmd_line)
    ---@type string[]
    local words = {}
    for word in cmd_line:gmatch("%S+") do
        words[#words + 1] = word
    end

    local completing_index = #words + (arg_lead == "" and 1 or 0)
    if completing_index <= 2 then
        return filter_by_prefix(subcommand_names, arg_lead)
    end

    local subcommand = subcommands[words[2]]
    local completes_target = completing_index == 3
        and subcommand ~= nil
        and subcommand.takes_target
    if not completes_target then
        return {}
    end
    return filter_by_prefix(module.get_target_names(), arg_lead)
end

common.create_user_command("Dove", function(opts)
    ---@type string[]
    local args = opts.fargs
    local subcommand_name = args[1]

    local subcommand = subcommands[subcommand_name]
    if not subcommand then
        error(
            string.format(
                "dove.nvim: unknown subcommand '%s', expected one of: %s",
                subcommand_name,
                table.concat(subcommand_names, ", ")
            )
        )
    end

    if not subcommand.takes_target then
        if #args ~= 1 then
            error(
                string.format(
                    "dove.nvim: subcommand '%s' does not take any argument",
                    subcommand_name
                )
            )
        end
        subcommand.func()
        return
    end

    if #args ~= 2 and not (#args == 1 and subcommand.target_optional) then
        error(
            string.format(
                "dove.nvim: subcommand '%s' requires %s target name",
                subcommand_name,
                subcommand.target_optional and "at most one" or "exactly one"
            )
        )
    end
    subcommand.func(args[2])
end, {
    nargs = "+",
    complete = complete,
    desc = "Dove: run, prev, edit, or delete",
})
