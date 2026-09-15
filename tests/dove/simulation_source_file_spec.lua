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

    it("creates a template when editing a missing source file", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        context:setup(path)

        dove.edit_source_file("project")

        assert.is_true(common.is_file_and_readable(path))
        local chunk, load_error = loadfile(path)
        assert.is_nil(load_error)
        local source = assert(chunk)()
        assert.equals("greetings", source[1].name)
        assert.equals("echo Hello, World!", source[1].cmd)
    end)

    it("deletes a target's source file", function()
        local path = common.path_join(context.temp_dir, "delete.lua")
        context:write_source_file(path, { "return {}" })
        context:setup(path)

        dove.delete_source_file("project")

        assert.is_false(common.is_file_and_readable(path))
    end)
end)
