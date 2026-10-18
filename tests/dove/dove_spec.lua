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
        assert.is_function(module.config.targets.project.default_executor)
        assert.equals(
            default_environment.executors.default,
            module.config.parent_target.default_executor
        )
        assert.is_function(module.config.targets.filetype.default_executor)
        assert.is_function(module.config.targets.global.default_executor)
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

    it(
        "shares the parent environment when targets are not configured",
        function()
            dove.setup({
                parent_target = { environment = { marker = "shared" } },
            })

            local config = module.config
            for _, target in pairs(config.targets) do
                assert.is_true(
                    target.environment == config.parent_target.environment
                )
                assert.equals("shared", target.environment.marker)
            end
        end
    )

    it("requires target settings when the parent target is false", function()
        assert.is_false(pcall(dove.setup, { parent_target = false }))
        assert.is_false(pcall(dove.setup, {
            parent_target = false,
            targets = {
                project = false,
                filetype = false,
                global = false,
                custom = {
                    ---@return string
                    source = function()
                        return "custom.lua"
                    end,
                },
            },
        }))
    end)

    it("merges targets with an empty parent when it is false", function()
        local options = {
            parent_target = false,
            targets = {
                project = false,
                filetype = false,
                global = false,
                custom = {
                    ---@return string
                    source = function()
                        return "custom.lua"
                    end,
                    auto_run_single_entry = false,
                    default_executor = default_environment.executors.default,
                    environment = { marker = "custom" },
                    cmd_list_delimiter = default_opts.parent_target.cmd_list_delimiter,
                    new_source_file_placeholder = false,
                },
            },
        }

        dove.setup(options)

        assert.is_false(options.parent_target)
        assert.same({}, module.config.parent_target)
        assert.same({ "custom" }, module.get_target_names())
        assert.equals(
            default_environment.executors.default,
            module.config.targets.custom.default_executor
        )
        assert.equals("custom", module.config.targets.custom.environment.marker)
        assert.is_function(module.config.targets.custom.cmd_list_delimiter)
        assert.is_false(
            module.config.targets.custom.new_source_file_placeholder
        )
    end)

    it("rejects an invalid ui picker", function()
        local success = pcall(dove.setup, {
            ui = { picker = true },
        })

        assert.is_false(success)
    end)

    it("rejects an invalid ui option", function()
        local success = pcall(dove.setup, { ui = true })

        assert.is_false(success)
    end)

    it("rejects an invalid selection item formatter", function()
        local success = pcall(dove.setup, {
            ui = { format_selection_item = "name" },
        })

        assert.is_false(success)
    end)

    it("rejects an invalid command list delimiter", function()
        local success = pcall(dove.setup, {
            parent_target = { cmd_list_delimiter = "; " },
        })

        assert.is_false(success)
    end)

    it("rejects invalid new source file template code", function()
        local success = pcall(dove.setup, {
            targets = { project = { new_source_file_placeholder = true } },
        })

        assert.is_false(success)
    end)

    it("rejects an invalid unspecified target name", function()
        local success = pcall(dove.setup, {
            unspecified_target_name = true,
        })

        assert.is_false(success)
    end)

    it(
        "rejects omitted targets when no unspecified target is configured",
        function()
            dove.setup()

            assert.is_false(pcall(dove.run))
            assert.is_false(pcall(dove.edit))
            assert.is_false(pcall(dove.delete_source_file))
        end
    )

    it("requires source options to be functions", function()
        for _, source in ipairs({
            "project.lua",
            { default_opts.targets.project.source },
            { { "make test" } },
        }) do
            assert.is_false(pcall(dove.setup, {
                targets = { project = { source = source } },
            }))
        end
    end)

    it("rejects a new target without a source", function()
        local success = pcall(dove.setup, {
            targets = {
                custom_target = {
                    default_executor = default_environment.executors.new_tab,
                    auto_run_single_entry = false,
                },
            },
        })

        assert.is_false(success)
    end)

    it("removes false built-in and custom targets", function()
        dove.setup({
            targets = {
                project = false,
                custom = false,
            },
        })

        assert.same({ "filetype", "global" }, module.get_target_names())
        assert.is_nil(module.config.targets.project)
        assert.is_nil(module.config.targets.custom)
        assert.is_false(pcall(dove.run, "project"))
        assert.is_false(pcall(dove.edit, "project"))
        assert.is_false(pcall(dove.delete_source_file, "project"))
        assert.is_false(pcall(dove.run, "custom"))
    end)

    it("rejects target values other than tables or false", function()
        assert.is_false(pcall(dove.setup, {
            targets = { project = true },
        }))
        assert.is_false(pcall(dove.setup, {
            targets = { project = "disabled" },
        }))
    end)

    it("inherits default target options and keeps target overrides", function()
        local inherited_executor = function() end
        local custom_executor = function() end
        dove.setup({
            parent_target = {
                auto_run_single_entry = true,
                default_executor = inherited_executor,
                environment = { marker = "shared" },
                cmd_list_delimiter = function()
                    return " && "
                end,
            },
            targets = {
                custom = {
                    source = function()
                        return "custom.lua"
                    end,
                    default_executor = custom_executor,
                    environment = { custom = true },
                },
            },
        })

        local project = module.config.targets.project
        local custom = module.config.targets.custom
        assert.is_true(project.auto_run_single_entry)
        assert.equals(inherited_executor, project.default_executor)
        assert.equals("shared", project.environment.marker)
        assert.equals(" && ", project.cmd_list_delimiter())
        assert.equals(custom_executor, custom.default_executor)
        assert.equals("shared", custom.environment.marker)
        assert.is_true(custom.environment.custom)
        assert.is_function(custom.environment.denv.file_path)
        assert.is_nil(project.environment.custom)
    end)
end)
