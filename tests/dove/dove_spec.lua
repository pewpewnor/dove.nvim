---@diagnostic disable: undefined-field

local dove = require("dove")
local default = require("dove.default")
local module = require("dove.module")
local preset = require("dove.preset")

describe("setup", function()
    it("works without options", function()
        assert.is_true(pcall(dove.setup))
    end)

    it("provides the built-in targets and executors", function()
        dove.setup()

        assert.same({ "filetype", "project" }, module.get_target_names())
        assert.is_function(preset.executors.new_tab)
        assert.is_function(preset.executors.split)
        assert.is_function(preset.executors.vsplit)
        assert.is_function(preset.file_path)
        assert.is_function(preset.dove_data_path)
        assert.is_function(preset.cwd_path)
        assert.is_nil(dove.preset)
        assert.is_nil(dove.preset_executors)
        assert.is_nil(dove.executors)
        assert.is_nil(dove.cwd_path)
        assert.is_function(dove.run_prev_task)
        assert.is_function(dove.edit_source_file)
        assert.is_function(dove.delete_source_file)
        assert.is_nil(dove.run_previous_task)
        assert.is_nil(dove.edit_lua_file)
        assert.is_nil(dove.delete_lua_file)
        assert.is_function(default.create)
        assert.is_function(module.config.targets.project.source_path)
        assert.is_function(module.config.targets.filetype.source_path)
        assert.is_nil(module.config.targets.project.source)
        assert.is_nil(module.config.targets.filetype.source)
        assert.is_function(module.config.targets.project.default_executor)
        assert.is_function(module.config.targets.filetype.default_executor)
        assert.is_function(module.config.ui.picker)
        assert.is_true(module.config.ui.enumerate_entries)
        assert.is_nil(module.config.display)
    end)

    it("rejects an invalid ui picker", function()
        local success, message = pcall(dove.setup, {
            ui = { picker = true },
        })

        assert.is_false(success)
        assert.matches("options.ui.picker", message)
    end)

    it("rejects an invalid ui option", function()
        local success, message = pcall(dove.setup, { ui = true })

        assert.is_false(success)
        assert.matches("options.ui", message)
    end)

    it("rejects an invalid entry enumeration option", function()
        local success, message = pcall(dove.setup, {
            ui = { enumerate_entries = "yes" },
        })

        assert.is_false(success)
        assert.matches("options.ui.enumerate_entries", message)
    end)

    it("rejects an invalid command list delimiter", function()
        local success, message = pcall(dove.setup, {
            cmd_list_delimiter = "; ",
        })

        assert.is_false(success)
        assert.matches("options.cmd_list_delimiter", message)
    end)

    it("rejects invalid source path resolver list entries", function()
        local success, message = pcall(dove.setup, {
            targets = {
                invalid = { source_path = { true } },
            },
        })

        assert.is_false(success)
        assert.matches("targets.invalid.source_path.1", message)
    end)
end)
