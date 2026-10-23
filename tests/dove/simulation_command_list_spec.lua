---@diagnostic disable: undefined-field, missing-return

local common = require("dove.common")
local dove = require("dove")
local simulation = require("tests.dove.helpers.simulation")

describe("source command lists", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("runs a command list in one shell", function()
        local path = common.path_join(context.temp_dir, "command-list.lua")
        context:write_source_file(path, {
            "return {",
            "    {",
            '        name = "steps",',
            "        cmd = {",
            '            "first",',
            '            "second",',
            "        },",
            "    },",
            "    {",
            '        name = "single",',
            '        cmd = "third",',
            "    },",
            "}",
        })
        context:setup(path, {
            auto_run_single_entry = false,
            cmd_list_delimiter = function()
                return "; "
            end,
        })

        dove.run("project")

        assert.equals(1, #context.executed_commands)
        assert.equals("first; second", context.executed_commands[1])

        local selected
        context.picker = function(items)
            selected = items
        end
        dove.run("project")

        assert.equals(2, #selected)
        assert.equals("third", selected[2].command)
    end)

    it("joins a command list with the configured delimiter", function()
        local path =
            common.path_join(context.temp_dir, "command-list-delimiter.lua")
        context:write_source_file(path, {
            "return {",
            '    { cmd = { "first", "second" } },',
            "}",
        })
        context:setup(path, {
            cmd_list_delimiter = function()
                return " && "
            end,
        })

        dove.run("project")

        assert.same({ "first && second" }, context.executed_commands)
    end)

    it("uses each target's environment and command delimiter", function()
        local path = common.path_join(context.temp_dir, "per-target.lua")
        context:write_source_file(path, {
            'return { { cmd = { prefix .. "first", "second" } } }',
        })
        dove.setup({
            parent_target = {
                auto_run_single_entry = true,
                environment = { prefix = "shared-" },
            },
            targets = {
                project = {
                    source = function()
                        return path
                    end,
                    executor = function(command)
                        context:execute(command)
                    end,
                    cmd_list_delimiter = function()
                        return " && "
                    end,
                },
                custom = {
                    source = function()
                        return path
                    end,
                    executor = function(command)
                        context:execute(command)
                    end,
                    environment = { prefix = "custom-" },
                    cmd_list_delimiter = function()
                        return " | "
                    end,
                },
            },
        })

        dove.run("project")
        dove.run("custom")

        assert.same(
            { "shared-first && second", "custom-first | second" },
            context.executed_commands
        )
    end)

    it("rejects an invalid command list delimiter return value", function()
        local path = common.path_join(
            context.temp_dir,
            "invalid-command-list-delimiter.lua"
        )
        context:write_source_file(path, {
            "return {",
            '    { cmd = { "first", "second" } },',
            "}",
        })
        context:setup(path, {
            cmd_list_delimiter = function()
                return true
            end,
        })

        local success = pcall(dove.run, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
    end)

    it("uses shell-compatible default delimiters", function()
        local path =
            common.path_join(context.temp_dir, "default-command-list.lua")
        context:write_source_file(path, {
            "return {",
            '    { cmd = { "first", "second" } },',
            "}",
        })
        local cases = {
            { shell = "/bin/sh", command = "first; second" },
            { shell = "/bin/zsh", command = "first; second" },
            {
                shell = [[C:\Windows\System32\cmd.exe]],
                command = "first & second",
            },
            {
                shell = [[C:\Program Files\PowerShell\7\pwsh.exe]],
                command = "first; second",
            },
        }

        for _, case in ipairs(cases) do
            context.executed_commands = {}
            context:set_common("get_shell", function()
                return case.shell
            end)
            context:setup(path)

            dove.run("project")

            assert.same({ case.command }, context.executed_commands)
        end
    end)
end)
