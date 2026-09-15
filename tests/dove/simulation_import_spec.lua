---@diagnostic disable: undefined-field

local common = require("dove.common")
local dove = require("dove")
local simulation = require("tests.dove.helpers.simulation")

describe("source file loading", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("flattens source files required from expanded paths", function()
        local imported_path = common.path_join(context.temp_dir, "shared.lua")
        local path = common.path_join(context.temp_dir, "project.lua")
        context:write_source_file(imported_path, {
            'return { { "echo imported" } }',
        })
        context:write_source_file(path, {
            "return {",
            '    { "echo local" },',
            '    require("~/template.lua"),',
            "}",
        })
        context:set_common("expand", function(value)
            if value == "~/template.lua" then
                return imported_path
            end
            return context.original_expand(value)
        end)
        context:setup(path, { auto_run_single_command = false })

        local selected
        context.picker = function(items)
            selected = items
        end
        dove.run_target("project")

        assert.equals(2, #selected)
        assert.equals("echo local", selected[1].name)
        assert.equals("echo imported", selected[2].name)
    end)

    it("resolves relative required paths from the requiring file", function()
        local imported_path = common.path_join(context.temp_dir, "shared.lua")
        local path = common.path_join(context.temp_dir, "project.lua")
        context:write_source_file(imported_path, {
            'return { { "echo relative" } }',
        })
        context:write_source_file(path, {
            'return { require("./shared.lua") }',
        })
        context:setup(path)

        dove.run_target("project")

        assert.same({ "echo relative" }, context.executed_commands)
    end)

    it("attributes imported entry errors to the imported file", function()
        local imported_path =
            common.path_join(context.temp_dir, "invalid-shared.lua")
        local path =
            common.path_join(context.temp_dir, "project-with-import.lua")
        context:write_source_file(imported_path, { 'return { "invalid" }' })
        context:write_source_file(path, {
            'return { require("./invalid-shared.lua") }',
        })
        context:setup(path)

        local success, message = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.matches("invalid%-shared%.lua", message)
        assert.is_nil(message:match("project%-with%-import%.lua"))
    end)

    it("reloads files on every run", function()
        local path = common.path_join(context.temp_dir, "reload.lua")
        context:write_source_file(path, { 'return { { "echo first" } }' })
        context:setup(path)
        dove.run_target("project")
        context:write_source_file(path, { 'return { { "echo second" } }' })

        dove.run_target("project")

        assert.same({ "echo first", "echo second" }, context.executed_commands)
    end)

    it("loads source files with the bytecode loader enabled", function()
        local path = common.path_join(context.temp_dir, "loader.lua")
        context:write_source_file(path, { 'return { { "echo loaded" } }' })
        context:setup(path)
        common.enable_loader()
        context.loader_enabled = true

        dove.run_target("project")

        assert.same({ "echo loaded" }, context.executed_commands)
    end)
end)
