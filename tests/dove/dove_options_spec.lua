---@diagnostic disable: undefined-field, assign-type-mismatch

local dove = require("dove")
local default_opts = require("dove.opts.default")
local module = require("dove.module")
local default_environment = require("dove.opts.environment")

describe("setup options", function()
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
                    executor = default_environment.executors.default,
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
            module.config.targets.custom.executor
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

    it("rejects an invalid target executor", function()
        local success, err = pcall(dove.setup, {
            targets = { project = { executor = "new_tab" } },
        })

        assert.is_false(success)
        assert.matches("targets.project.executor", err, 1, true)
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
                    executor = default_environment.executors.new_tab,
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
                executor = inherited_executor,
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
                    executor = custom_executor,
                    environment = { custom = true },
                },
            },
        })

        local project = module.config.targets.project
        local custom = module.config.targets.custom
        assert.is_true(project.auto_run_single_entry)
        assert.equals(inherited_executor, project.executor)
        assert.equals("shared", project.environment.marker)
        assert.equals(" && ", project.cmd_list_delimiter())
        assert.equals(custom_executor, custom.executor)
        assert.equals("shared", custom.environment.marker)
        assert.is_true(custom.environment.custom)
        assert.is_function(custom.environment.denv.file_path)
        assert.is_nil(project.environment.custom)
    end)
end)
