---@diagnostic disable: undefined-field

local common = require("dove.common")
local dove = require("dove")
local simulation = require("tests.dove.helpers.simulation")

describe("source file management", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("writes the default template code to a missing source file", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        context:setup(path)

        dove.edit_source_file("project")

        local source = assert(loadfile(path))()
        assert.equals("placeholder greeting", source[1].name)
        assert.equals("echo 'Hello from dove.nvim!'", source[1].cmd)
    end)

    it("writes configured template code to a missing source file", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        local template = "return {\n    { 'make test' },\n}\n"
        context:setup(path, { new_source_file_template_code = template })

        dove.edit_source_file("project")

        local file = assert(io.open(path, "rb"))
        local content = file:read("*a")
        file:close()
        assert.equals(template, content)
    end)

    it("does not replace an existing source file with template code", function()
        local path = common.path_join(context.temp_dir, "existing.lua")
        context:write_source_file(path, { "return {}" })
        context:setup(path, {
            new_source_file_template_code = "return { { 'make test' } }",
        })

        dove.edit_source_file("project")

        local source = assert(loadfile(path))()
        assert.same({}, source)
    end)

    it("deletes a target's source file", function()
        local path = common.path_join(context.temp_dir, "delete.lua")
        context:write_source_file(path, { "return {}" })
        context:setup(path)

        dove.delete_source_file("project")

        assert.is_false(common.is_file_and_readable(path))
    end)
end)
