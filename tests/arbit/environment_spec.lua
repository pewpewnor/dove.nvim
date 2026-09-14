---@diagnostic disable: undefined-field

local arbit = require("arbit")
local common = require("arbit.common")
local module = require("arbit.module")
local pathfinder = require("arbit.pathfinder")

describe("environment", function()
    it("contains all default values", function()
        arbit.setup()
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
            "arbit_data_path",
            "cword",
            "cWORD",
            "hash_sha256",
        }
        for _, name in ipairs(expected_functions) do
            assert.is_function(environment[name])
            assert.equals(arbit.preset[name], environment[name])
        end
        assert.is_function(environment.executors.vsplit)
        assert.equals(
            arbit.preset.executors.vsplit,
            environment.executors.vsplit
        )
    end)

    it("deeply merges user values and overrides", function()
        local custom_executor = function() end
        arbit.setup({
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
            arbit.setup({
                environment = {
                    arbit_data_path = function()
                        return "/tmp/arbit-test"
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
                common.path_normalize("/tmp/arbit-test/projects/hash-cwd.lua"),
                path
            )
        end
    )
end)
