---@diagnostic disable: undefined-field, missing-return

local common = require("dove.common")
local dove = require("dove")
local simulation = require("tests.dove.helpers.simulation")

describe("source picker", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
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
end)
