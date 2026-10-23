---@diagnostic disable: undefined-field, missing-return

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
                    executor = function(command)
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
end)
