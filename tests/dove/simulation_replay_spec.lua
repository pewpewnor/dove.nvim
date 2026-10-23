---@diagnostic disable: undefined-field, missing-return

local common = require("dove.common")
local dove = require("dove")
local runner = require("dove.source.runner")
local default_environment = require("dove.opts.environment")
local simulation = require("tests.dove.helpers.simulation")

describe("source replay", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
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
                    executor = function(command)
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
end)
