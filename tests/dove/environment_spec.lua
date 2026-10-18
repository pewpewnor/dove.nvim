---@diagnostic disable: undefined-field, redundant-parameter

local dove = require("dove")
local common = require("dove.common")
local module = require("dove.module")
local pathfinder = require("dove.pathfinder")
local default_environment = require("dove.opts.environment")

describe("environment", function()
    it("contains all default values", function()
        dove.setup()
        local environment = module.config.targets.project.environment

        local expected_functions = {
            "file_path",
            "file_name",
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
            "expand",
            "hash_sha256",
        }
        for _, name in ipairs(expected_functions) do
            assert.is_function(environment.denv[name])
            assert.equals(default_environment[name], environment.denv[name])
        end
        assert.is_function(environment.denv.executors.vsplit)
        assert.equals(
            default_environment.executors.vsplit,
            environment.denv.executors.vsplit
        )
    end)

    it("deeply merges user values and overrides", function()
        local custom_executor = function() end
        dove.setup({
            parent_target = {
                environment = {
                    my_var = "lol",
                    denv = {
                        file_path = function()
                            return "overridden"
                        end,
                        executors = { custom = custom_executor },
                    },
                },
            },
        })

        local environment = module.config.targets.project.environment
        assert.equals("overridden", environment.denv.file_path())
        assert.equals("lol", environment.my_var)
        assert.equals(custom_executor, environment.denv.executors.custom)
        assert.is_function(environment.denv.executors.vsplit)
    end)

    it("calls target source resolvers without arguments", function()
        local argument_count
        local source = common.path_join(common.get_tempname(), "project.lua")
        dove.setup({
            targets = {
                project = {
                    source = function(...)
                        argument_count = select("#", ...)
                        return source
                    end,
                },
            },
        })

        pathfinder(module.config.targets.project.source)

        assert.equals(0, argument_count)
    end)

    it("creates a fresh environment for every setup", function()
        dove.setup({ parent_target = { environment = { marker = "first" } } })
        assert.equals("first", module.config.targets.project.environment.marker)

        dove.setup()

        assert.is_nil(module.config.targets.project.environment.marker)
    end)
end)
