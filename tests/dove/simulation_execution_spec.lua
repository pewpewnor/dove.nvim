---@diagnostic disable: undefined-field, missing-return

local common = require("dove.common")
local dove = require("dove")
local runner = require("dove.source.runner")
local default_environment = require("dove.opts.environment")
local simulation = require("tests.dove.helpers.simulation")

describe("source file execution", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("rejects source functions that return a table", function()
        dove.setup({
            targets = {
                project = {
                    ---@return table
                    source = function()
                        return { { "echo inline" } }
                    end,
                },
            },
        })

        assert.is_false(pcall(dove.run, "project"))
        assert.same({}, context.executed_commands)
    end)

    it("opens the picker for one entry by default", function()
        local path = common.path_join(context.temp_dir, "single-command.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo single" },',
            "}",
        })
        local selected
        dove.setup({
            targets = {
                project = {
                    source = function()
                        return path
                    end,
                    default_executor = function(command)
                        context:execute(command)
                    end,
                },
            },
            ui = {
                picker = function(items)
                    selected = items
                end,
            },
        })

        dove.run("project")

        assert.equals("echo single", selected[1].command)
        assert.same({}, context.executed_commands)
    end)

    it("runs the unspecified target from the API and command", function()
        local path = common.path_join(context.temp_dir, "default-target.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo default" },',
            "}",
        })
        context:setup(path, {
            unspecified_target_name = function()
                return "project"
            end,
        })

        dove.run()
        context.original_cmd("source " .. common.fnameescape("plugin/dove.lua"))
        context.original_cmd("Dove run")

        assert.same(
            { "echo default", "echo default" },
            context.executed_commands
        )
    end)

    it("runs a string unspecified target from the API and command", function()
        local path = common.path_join(context.temp_dir, "string-target.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo string target" },',
            "}",
        })
        context:setup(path, { unspecified_target_name = "project" })

        dove.run()
        context.original_cmd("source " .. common.fnameescape("plugin/dove.lua"))
        context.original_cmd("Dove run")

        assert.same(
            { "echo string target", "echo string target" },
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
        context:setup(path, { auto_run_single_entry = false })

        dove.run("project")

        assert.equals("touch hello", context.executed_commands[1])

        local selected
        context.picker = function(items)
            selected = items
        end
        dove.run("project")
        assert.equals("echo first", selected[2].command)
        assert.equals("a", selected[2].name:match("a$"))
        assert.equals("echo second", selected[3].command)
    end)

    it(
        "runs Lua function commands and uses tostring for their default names",
        function()
            local path =
                common.path_join(context.temp_dir, "function-command.lua")
            context:write_source_file(path, {
                "return {",
                "    { cmd = function() record('first') end },",
                "    { function() record('positional') end },",
                "    {",
                '        name = "named Lua command",',
                "        cmd = function() record('second') end,",
                "        executor = function() error('executor called') end,",
                "    },",
                "}",
            })
            local recorded = {}
            local selected
            local selected_index = 1
            context.picker = function(items, _, on_choice)
                selected = items
                on_choice(items[selected_index], selected_index)
            end
            context:setup(path, {
                auto_run_single_entry = false,
                environment = {
                    record = function(value)
                        recorded[#recorded + 1] = value
                    end,
                },
            })

            dove.run("project")
            assert.equals(tostring(selected[1].command), selected[1].name)
            assert.equals(tostring(selected[2].command), selected[2].name)
            assert.is_nil(selected[1].executor)
            assert.is_nil(selected[2].executor)
            assert.is_nil(selected[3].executor)

            selected_index = 2
            dove.run("project")
            selected_index = 3
            dove.run("project")
            dove.prev_task()

            assert.same({ "first", "positional", "second", "second" }, recorded)
            assert.same({}, context.executed_commands)
        end
    )

    it("rejects functions in command lists", function()
        local path =
            common.path_join(context.temp_dir, "function-command-list.lua")
        context:write_source_file(path, {
            "return {",
            "    { cmd = { 'first', function() end } },",
            "}",
        })
        context:setup(path)

        local success = pcall(dove.run, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
    end)

    it("rejects positional command lists", function()
        local path =
            common.path_join(context.temp_dir, "positional-command-list.lua")
        context:write_source_file(path, {
            "return {",
            "    { { 'first', 'second' } },",
            "}",
        })
        context:setup(path)

        local success = pcall(dove.run, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
    end)

    it("rejects string entries", function()
        local path = common.path_join(context.temp_dir, "string-entry.lua")
        context:write_source_file(path, {
            "return {",
            '    { cmd = "echo valid" },',
            '    "echo invalid",',
            "}",
        })
        context:setup(path, { auto_run_single_entry = false })

        local success = pcall(dove.run, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
    end)

    it("rejects empty command strings", function()
        local path = common.path_join(context.temp_dir, "empty-command.lua")
        context:write_source_file(path, {
            "return {",
            '    { name = "empty", cmd = "  " },',
            "}",
        })
        context:setup(path)

        local success, message = pcall(dove.run, "project")

        assert.is_false(success)
        assert.matches(
            "dove.nvim: entry command cannot be empty",
            message,
            1,
            true
        )
        assert.same({}, context.executed_commands)
    end)

    it("rejects empty strings in command lists", function()
        local path =
            common.path_join(context.temp_dir, "empty-command-list-item.lua")
        context:write_source_file(path, {
            "return {",
            '    { cmd = { "first", "" } },',
            "}",
        })
        context:setup(path)

        local success, message = pcall(dove.run, "project")

        assert.is_false(success)
        assert.matches(
            "dove.nvim: entry command 2 cannot be empty",
            message,
            1,
            true
        )
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
                    default_executor = function(command)
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
                    default_executor = function(command)
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
            auto_run_single_entry = false,
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

        dove.run("project")

        assert.equals("Dove: run target = 'project'", received_prompt)
        assert.same({ "1. echo first", "2. echo second" }, received_labels)
        assert.same({ "echo second" }, context.executed_commands)
    end)

    it("formats selection items with the configured function", function()
        local path = common.path_join(context.temp_dir, "selection-labels.lua")
        context:write_source_file(path, {
            "return {",
            '    { "echo first" },',
            '    { "echo second" },',
            "}",
        })
        local received_labels
        context:setup(path, {
            auto_run_single_entry = false,
            ui = {
                format_selection_item = function(name, i)
                    return name .. " (" .. i .. ")"
                end,
                picker = function(items, opts, on_choice)
                    received_labels = {
                        opts.format_item(items[1]),
                        opts.format_item(items[2]),
                    }
                    on_choice(items[1], 1)
                end,
            },
        })

        dove.run("project")

        assert.same({ "echo first (1)", "echo second (2)" }, received_labels)
        assert.same({ "echo first" }, context.executed_commands)
    end)

    it("rejects one entry without an outer list", function()
        local path = common.path_join(context.temp_dir, "single-entry.lua")
        context:write_source_file(path, {
            'return { name = "a", cmd = "touch hello" }',
        })
        context:setup(path)

        local success = pcall(dove.run, "project")

        assert.is_false(success)
        assert.same({}, context.executed_commands)
    end)

    it("accepts an empty source list", function()
        local path = common.path_join(context.temp_dir, "empty.lua")
        context:write_source_file(path, { "return {}" })
        context:setup(path)

        assert.is_true(pcall(dove.run, "project"))
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

        dove.run("project")

        assert.same({ "wc custom.lua" }, context.executed_commands)
        assert.is_nil(
            require("dove.module").config.targets.project.environment.require
        )
    end)

    it("exposes task and entry replay through denv", function()
        local project_path = common.path_join(context.temp_dir, "project.lua")
        local replay_path = common.path_join(context.temp_dir, "replay.lua")
        context:write_source_file(project_path, { 'return { { "echo old" } }' })
        context:write_source_file(replay_path, {
            "if replay_choice() == 1 then",
            "    denv.run_task(denv.last_task())",
            "else",
            "    denv.run_entry(denv.last_entry())",
            "end",
            "return {}",
        })
        local choice = 1
        dove.setup({
            targets = {
                project = {
                    source = function()
                        return project_path
                    end,
                    auto_run_single_entry = true,
                    default_executor = function(command)
                        context:execute(command)
                    end,
                },
                replay = {
                    source = function()
                        return replay_path
                    end,
                    environment = {
                        ---@return integer
                        replay_choice = function()
                            return choice
                        end,
                    },
                },
            },
            ui = {
                picker = function(items, _, on_choice)
                    on_choice(items[choice], choice)
                end,
            },
        })

        dove.run("project")
        local task = assert(default_environment.last_task())
        local entry = assert(default_environment.last_entry())
        task.command = "echo changed snapshot"
        entry.index = 99
        dove.run("replay")
        context:write_source_file(project_path, { 'return { { "echo new" } }' })
        choice = 2
        dove.run("replay")
        dove.prev_task()

        assert.same(
            { "echo old", "echo old", "echo new", "echo new" },
            context.executed_commands
        )
    end)

    it("rejects source functions that return nil", function()
        local picker_called = false
        dove.setup({
            targets = {
                project = {
                    source = function() end,
                },
            },
            ui = {
                picker = function()
                    picker_called = true
                end,
            },
        })
        local previous_task = runner.last_executed_task
        local previous_entry = runner.last_executed_entry

        assert.is_false(pcall(dove.run, "project"))

        assert.is_false(picker_called)
        assert.equals(previous_task, runner.last_executed_task)
        assert.equals(previous_entry, runner.last_executed_entry)
    end)

    it("runs the previous task again", function()
        local path = common.path_join(context.temp_dir, "previous.lua")
        context:write_source_file(path, { 'return { { "echo previous" } }' })
        context:setup(path)
        dove.run("project")

        dove.prev_task()
        dove.prev_task()

        assert.same(
            { "echo previous", "echo previous", "echo previous" },
            context.executed_commands
        )
    end)

    it("does nothing when no previous entry exists", function()
        context:setup(common.path_join(context.temp_dir, "unused.lua"))
        local previous = runner.last_executed_entry
        runner.last_executed_entry = nil

        dove.prev_entry()

        assert.is_nil(runner.last_executed_entry)
        assert.same({}, context.executed_commands)
        runner.last_executed_entry = previous
    end)

    it(
        "recomputes the previous shell entry while preserving the previous task",
        function()
            local path =
                common.path_join(context.temp_dir, "previous-entry.lua")
            context:write_source_file(path, {
                'return { { "echo first" }, { "echo old" } }',
            })
            context.picker = function(items, _, on_choice)
                on_choice(items[2], 2)
            end
            context:setup(path, { auto_run_single_entry = false })
            dove.run("project")
            context:write_source_file(path, {
                'return { { "echo first" }, { "echo new" } }',
            })

            dove.prev_task()
            context.original_cmd(
                "source " .. common.fnameescape("plugin/dove.lua")
            )
            context.original_cmd("Dove prev_entry")
            context.original_cmd("Dove prev_task")
            assert.is_false(pcall(context.original_cmd, "Dove last_entry"))
            assert.is_false(pcall(context.original_cmd, "Dove last_task"))
            assert.is_false(
                pcall(context.original_cmd, "Dove prev_entry extra")
            )
            assert.is_false(pcall(context.original_cmd, "Dove prev_task extra"))

            assert.same(
                { "echo old", "echo old", "echo new", "echo new" },
                context.executed_commands
            )
        end
    )

    it("recomputes the previous Lua function entry", function()
        local path = common.path_join(context.temp_dir, "previous-function.lua")
        local recorded = {}
        context:write_source_file(path, {
            "return { { function() record('old') end } }",
        })
        context:setup(path, {
            environment = {
                record = function(value)
                    recorded[#recorded + 1] = value
                end,
            },
        })
        dove.run("project")
        context:write_source_file(path, {
            "return { { function() record('new') end } }",
        })

        dove.prev_task()
        dove.prev_entry()

        assert.same({ "old", "old", "new" }, recorded)
    end)

    it(
        "does not create a previous task when the picker is cancelled",
        function()
            local path = common.path_join(context.temp_dir, "cancelled.lua")
            context:write_source_file(path, {
                'return { { "echo first" }, { "echo second" } }',
            })
            context.picker = function(_, _, on_choice)
                on_choice(nil, nil)
            end
            context:setup(path)
            local previous_task = runner.last_executed_task
            runner.last_executed_task = nil

            dove.run("project")
            dove.prev_task()

            assert.is_nil(runner.last_executed_task)
            assert.same({}, context.executed_commands)
            runner.last_executed_task = previous_task
        end
    )

    it("keeps the last executed task when the picker is cancelled", function()
        local path = common.path_join(context.temp_dir, "previous-choice.lua")
        context:write_source_file(path, {
            'return { { "echo first" }, { "echo second" } }',
        })
        context:setup(path)
        dove.run("project")
        context.picker = function(_, _, on_choice)
            on_choice(nil, nil)
        end

        dove.run("project")
        dove.prev_task()

        assert.same({ "echo first", "echo first" }, context.executed_commands)
    end)

    it("rejects files that do not return a table", function()
        local path = common.path_join(context.temp_dir, "invalid.lua")
        context:write_source_file(path, { 'return "invalid"' })
        context:setup(path)

        local success = pcall(dove.run, "project")

        assert.is_false(success)
    end)
end)
