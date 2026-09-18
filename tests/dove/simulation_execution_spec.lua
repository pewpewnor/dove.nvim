---@diagnostic disable: undefined-field

local common = require("dove.common")
local dove = require("dove")
local simulation = require("tests.dove.helpers.simulation")

describe("source file execution", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("runs the default target from the API and command", function()
        local path = common.path_join(context.temp_dir, "default-target.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo default" },',
            "}",
        })
        context:setup(path, { default_target = "project" })

        dove.run_target()
        context.original_cmd("source " .. common.fnameescape("plugin/dove.lua"))
        context.original_cmd("Dove run")

        assert.same(
            { "echo default", "echo default" },
            context.executed_commands
        )
    end)

    it("runs named and positional command tables", function()
        local path = common.path_join(context.temp_dir, "project.lua")
        context:write_source_file(path, {
            "return {",
            '    { "touch hello" },',
            '    { name = "a", cmd = "echo first" },',
            '    { "echo second", name = "b" },',
            "}",
        })
        context:setup(path, { auto_run_single_command = false })

        dove.run_target("project")

        assert.equals("touch hello", context.executed_commands[1])

        local selected
        context.picker = function(items)
            selected = items
        end
        dove.run_target("project")
        assert.equals("echo first", selected[2].command)
        assert.equals("a", selected[2].name:match("a$"))
        assert.equals("echo second", selected[3].command)
    end)

    it("rejects string entries", function()
        local path = common.path_join(context.temp_dir, "string-entry.lua")
        context:write_source_file(path, {
            "return {",
            '    { cmd = "echo valid" },',
            '    "echo invalid",',
            "}",
        })
        context:setup(path, { auto_run_single_command = false })

        local success = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
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
            auto_run_single_command = false,
            cmd_list_delimiter = function()
                return "; "
            end,
        })

        dove.run_target("project")

        assert.equals(1, #context.executed_commands)
        assert.equals("first; second", context.executed_commands[1])

        local selected
        context.picker = function(items)
            selected = items
        end
        dove.run_target("project")

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

        dove.run_target("project")

        assert.same({ "first && second" }, context.executed_commands)
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

        local success = pcall(dove.run_target, "project")

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

            dove.run_target("project")

            assert.same({ case.command }, context.executed_commands)
        end
    end)

    it("uses the configured picker", function()
        local path = common.path_join(context.temp_dir, "selection-ui.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo first" },',
            '    { "echo second" },',
            "}",
        })
        local received_prompt
        local received_labels
        context:setup(path, {
            auto_run_single_command = false,
            ui = {
                picker = function(items, opts, on_choice)
                    received_prompt = opts.prompt
                    received_labels = {
                        opts.format_item(items[1]),
                        opts.format_item(items[2]),
                    }
                    on_choice(items[2], 2)
                end,
            },
        })

        dove.run_target("project")

        assert.equals("Dove: run target = 'project'", received_prompt)
        assert.same({ "1. echo first", "2. echo second" }, received_labels)
        assert.same({ "echo second" }, context.executed_commands)
    end)

    it("does not enumerate entries when disabled", function()
        local path = common.path_join(context.temp_dir, "selection-labels.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo first" },',
            '    { "echo second" },',
            "}",
        })
        local received_labels
        context:setup(path, {
            auto_run_single_command = false,
            ui = {
                enumerate_entries = false,
                picker = function(items, opts, on_choice)
                    received_labels = {
                        opts.format_item(items[1]),
                        opts.format_item(items[2]),
                    }
                    on_choice(items[1], 1)
                end,
            },
        })

        dove.run_target("project")

        assert.same({ "echo first", "echo second" }, received_labels)
        assert.same({ "echo first" }, context.executed_commands)
    end)

    it("rejects one entry without an outer list", function()
        local path = common.path_join(context.temp_dir, "single-entry.lua")
        context:write_source_file(path, {
            'return { name = "a", cmd = "touch hello" }',
        })
        context:setup(path)

        local success = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
    end)

    it("accepts an empty source list", function()
        local path = common.path_join(context.temp_dir, "empty.lua")
        context:write_source_file(path, { "return {}" })
        context:setup(path)

        assert.is_true(pcall(dove.run_target, "project"))
        assert.same({}, context.executed_commands)
    end)

    it("exposes configured globals and built-ins under denv", function()
        local path = common.path_join(context.temp_dir, "environment.lua")
        context:write_source_file(path, {
            "assert(file_path == nil)",
            "assert(executors == nil)",
            "assert(dove == nil)",
            'assert(type(denv.dir_name) == "function")',
            'assert(type(denv.executors.bg_silent) == "function")',
            "return {",
            "    { prefix .. denv.file_path(), executor = denv.executors.capture },",
            "}",
        })
        context:setup(path, {
            environment = {
                prefix = "wc ",
                denv = {
                    file_path = function()
                        return "custom.lua"
                    end,
                    executors = {
                        capture = function(command)
                            context:execute(command)
                        end,
                    },
                },
            },
        })

        dove.run_target("project")

        assert.same({ "wc custom.lua" }, context.executed_commands)
        assert.is_nil(require("dove.module").config.environment.require)
    end)

    it("runs the previous task again", function()
        local path = common.path_join(context.temp_dir, "previous.lua")
        context:write_source_file(path, { 'return { { "echo previous" } }' })
        context:setup(path)
        dove.run_target("project")

        dove.run_prev_task()

        assert.same(
            { "echo previous", "echo previous" },
            context.executed_commands
        )
    end)

    it("rejects files that do not return a table", function()
        local path = common.path_join(context.temp_dir, "invalid.lua")
        context:write_source_file(path, { 'return "invalid"' })
        context:setup(path)

        local success = pcall(dove.run_target, "project")

        assert.is_false(success)
    end)
end)
