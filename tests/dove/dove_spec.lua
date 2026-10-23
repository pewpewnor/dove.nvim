---@diagnostic disable: undefined-field, assign-type-mismatch

local dove = require("dove")
local create_opts = require("dove.opts.create")
local default_opts = require("dove.opts.default")
local module = require("dove.module")
local default_environment = require("dove.opts.environment")

describe("setup", function()
    it("works without options", function()
        assert.is_true(pcall(dove.setup))
    end)

    it("rejects running a target before setup", function()
        local config = module.config
        module.config = nil

        local success = pcall(dove.run, "project")

        module.config = config
        assert.is_false(success)
    end)

    it("provides the built-in targets and executors", function()
        dove.setup()

        assert.same(
            { "filetype", "global", "project" },
            module.get_target_names()
        )
        assert.is_function(default_environment.executors.new_tab)
        assert.is_function(default_environment.executors.default)
        assert.is_function(default_environment.executors.split)
        assert.is_function(default_environment.executors.vsplit)
        assert.is_function(default_environment.file_path)
        assert.is_function(default_environment.dove_data_path)
        assert.is_function(default_environment.cwd_path)
        assert.is_function(dove.run)
        assert.is_function(dove.prev_task)
        assert.is_function(dove.prev_entry)
        assert.is_function(dove.edit)
        assert.is_function(dove.delete_source_file)
        assert.is_function(create_opts)
        assert.is_table(default_opts.parent_target)
        assert.is_function(module.config.targets.project.source)
        assert.is_function(module.config.targets.filetype.source)
        assert.is_function(module.config.targets.global.source)
        assert.is_false(module.config.targets.project.auto_run_single_entry)
        assert.is_false(module.config.targets.filetype.auto_run_single_entry)
        assert.is_false(module.config.targets.global.auto_run_single_entry)
        assert.is_function(module.config.targets.project.executor)
        assert.equals(
            default_environment.executors.default,
            module.config.parent_target.executor
        )
        assert.is_function(module.config.targets.filetype.executor)
        assert.is_function(module.config.targets.global.executor)
        assert.is_nil(module.config.unspecified_target_name)
        assert.is_nil(module.config.cmd_list_delimiter)
        assert.is_nil(module.config.new_source_file_placeholder)
        assert.equals(
            table.concat({
                "return {",
                "    {",
                '        name = "placeholder greeting",',
                "        cmd = \"echo 'Hello from dove.nvim!'\",",
                "    },",
                "}",
                "",
            }, "\n"),
            module.config.targets.project.new_source_file_placeholder
        )
        assert.is_function(module.config.ui.picker)
        assert.equals(
            "1. build",
            module.config.ui.format_selection_item("build", 1)
        )
        assert.is_nil(module.config.display)
    end)

    it("does not expose replay as targets", function()
        dove.setup()

        for _, name in ipairs({ "last_task", "last_entry" }) do
            assert.is_false(pcall(dove.run, name))
            assert.is_false(pcall(dove.edit, name))
            assert.is_false(pcall(dove.delete_source_file, name))
        end
    end)
end)
