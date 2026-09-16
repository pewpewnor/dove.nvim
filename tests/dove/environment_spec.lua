---@diagnostic disable: undefined-field

local dove = require("dove")
local common = require("dove.common")
local module = require("dove.module")
local pathfinder = require("dove.pathfinder")
local preset = require("dove.preset")

describe("environment", function()
    it("contains all default values", function()
        dove.setup()
        local environment = module.config.environment

        local expected_functions = {
            "file_path",
            "file_path_relative",
            "file_name",
            "file_name_no_extension",
            "file_type",
            "file_extension",
            "dir_path",
            "dir_name",
            "cwd_path",
            "cwd_name",
            "config_path",
            "data_path",
            "dove_data_path",
            "cword",
            "cWORD",
            "hash_sha256",
        }
        for _, name in ipairs(expected_functions) do
            assert.is_function(environment.denv[name])
            assert.equals(preset[name], environment.denv[name])
        end
        assert.is_function(environment.denv.executors.vsplit)
        assert.equals(
            preset.executors.vsplit,
            environment.denv.executors.vsplit
        )
    end)

    it("deeply merges user values and overrides", function()
        local custom_executor = function() end
        dove.setup({
            environment = {
                my_var = "lol",
                denv = {
                    file_path = function()
                        return "overridden"
                    end,
                    executors = { custom = custom_executor },
                },
            },
        })

        local environment = module.config.environment
        assert.equals("overridden", environment.denv.file_path())
        assert.equals("lol", environment.my_var)
        assert.equals(custom_executor, environment.denv.executors.custom)
        assert.is_function(environment.denv.executors.vsplit)
    end)

    it("calls target source path resolvers without arguments", function()
        local argument_count
        local source_path =
            common.path_join(common.get_tempname(), "project.lua")
        dove.setup({
            targets = {
                project = {
                    source_path = function(...)
                        argument_count = select("#", ...)
                        return source_path
                    end,
                },
            },
        })

        pathfinder.get_true_path(module.config.targets.project.source_path)

        assert.equals(0, argument_count)
    end)

    it("creates a fresh environment for every setup", function()
        dove.setup({ environment = { marker = "first" } })
        assert.equals("first", module.config.environment.marker)

        dove.setup()

        assert.is_nil(module.config.environment.marker)
    end)
end)
