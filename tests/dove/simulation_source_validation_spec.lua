---@diagnostic disable: undefined-field, missing-return

local common = require("dove.common")
local dove = require("dove")
local runner = require("dove.source.runner")
local simulation = require("tests.dove.helpers.simulation")

describe("source validation", function()
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

    it("rejects files that do not return a table", function()
        local path = common.path_join(context.temp_dir, "invalid.lua")
        context:write_source_file(path, { 'return "invalid"' })
        context:setup(path)

        local success = pcall(dove.run, "project")

        assert.is_false(success)
    end)
end)
