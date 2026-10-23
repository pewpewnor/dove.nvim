---@diagnostic disable: undefined-field, missing-return

local common = require("dove.common")
local dove = require("dove")
local simulation = require("tests.dove.helpers.simulation")

describe("source environment", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("exposes configured globals and built-ins under denv", function()
        local path = common.path_join(context.temp_dir, "environment.lua")
        context:write_source_file(path, {
            "assert(file_path == nil)",
            "assert(executors == nil)",
            "assert(dove == nil)",
            'assert(type(denv.dir_name) == "function")',
            'assert(type(denv.executors.bg_silent) == "function")',
            "return {",
            "    { prefix .. denv.file_path(), executor = denv.executors.capture },",
            "}",
        })
        context:setup(path, {
            environment = {
                prefix = "wc ",
                denv = {
                    file_path = function()
                        return "custom.lua"
                    end,
                    executors = {
                        capture = function(command)
                            context:execute(command)
                        end,
                    },
                },
            },
        })

        dove.run("project")

        assert.same({ "wc custom.lua" }, context.executed_commands)
        assert.is_nil(
            require("dove.module").config.targets.project.environment.require
        )
    end)
end)
