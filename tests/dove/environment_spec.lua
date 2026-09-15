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
            assert.is_function(environment[name])
            assert.equals(preset[name], environment[name])
        end
        assert.is_function(environment.executors.vsplit)
        assert.equals(preset.executors.vsplit, environment.executors.vsplit)
    end)

    it("deeply merges user values and overrides", function()
        local custom_executor = function() end
        dove.setup({
            environment = {
                file_path = function()
                    return "overridden"
                end,
                my_var = "lol",
                executors = { custom = custom_executor },
            },
        })

        local environment = module.config.environment
        assert.equals("overridden", environment.file_path())
        assert.equals("lol", environment.my_var)
        assert.equals(custom_executor, environment.executors.custom)
        assert.is_function(environment.executors.vsplit)
    end)

    it(
        "uses overridden environment values in default target sources",
        function()
            dove.setup({
                environment = {
                    dove_data_path = function()
                        return "/tmp/dove-test"
                    end,
                    cwd_path = function()
                        return "cwd"
                    end,
                    hash_sha256 = function(value)
                        return "hash-" .. value
                    end,
                },
            })

            local path =
                pathfinder.get_true_path(module.config.targets.project.source)
            assert.equals(
                common.path_normalize("/tmp/dove-test/projects/hash-cwd.lua"),
                path
            )
        end
    )

    it("passes the effective environment to target source resolvers", function()
        local received_environment
        dove.setup({
            environment = { marker = "configured" },
            targets = {
                project = {
                    source = function(environment)
                        received_environment = environment
                        return "/tmp/dove-test/project.lua"
                    end,
                },
            },
        })

        pathfinder.get_true_path(module.config.targets.project.source)

        assert.equals(module.config.environment, received_environment)
        assert.equals("configured", received_environment.marker)
        assert.equals(preset.cwd_path, received_environment.cwd_path)
    end)

    it("creates a fresh environment for every setup", function()
        dove.setup({ environment = { marker = "first" } })
        assert.equals("first", module.config.environment.marker)

        dove.setup()

        assert.is_nil(module.config.environment.marker)
    end)
end)
