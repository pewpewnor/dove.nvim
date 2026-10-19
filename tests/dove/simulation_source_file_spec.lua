---@diagnostic disable: undefined-field, return-type-mismatch

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

    it(
        "rejects file operations when a source function returns a table",
        function()
            dove.setup({
                targets = {
                    project = {
                        source = function()
                            return { { "echo inline" } }
                        end,
                    },
                },
            })

            assert.is_false(pcall(dove.edit, "project"))
            assert.is_false(pcall(dove.delete_source_file, "project"))
        end
    )

    it("writes the default template code to a missing source file", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        context:setup(path)

        dove.edit("project")

        local source = assert(loadfile(path))()
        assert.equals("placeholder greeting", source[1].name)
        assert.equals("echo 'Hello from dove.nvim!'", source[1].cmd)
    end)

    it("writes configured template code to a missing source file", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        local template = "return {\n    { 'make test' },\n}\n"
        context:setup(path, {
            new_source_file_placeholder = template,
        })

        dove.edit("project")

        local file = assert(io.open(path, "rb"))
        local content = file:read("*a")
        file:close()
        assert.equals(template, content)
    end)

    it("preserves CRLF in configured template code", function()
        local path = common.path_join(context.temp_dir, "new.lua")
        local template = "return {\r\n    { 'make test' },\r\n}\r\n"
        context:setup(path, { new_source_file_placeholder = template })

        dove.edit("project")

        local file = assert(io.open(path, "rb"))
        local content = file:read("*a")
        file:close()
        assert.equals(template, content)
    end)

    it("does not write a template when the target option is false", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        context:setup(path, { new_source_file_placeholder = false })

        dove.edit("project")

        assert.is_false(common.is_file_and_readable(path))
    end)

    it(
        "does not write a template when the inherited option is false",
        function()
            local path = common.path_join(context.temp_dir, "nested", "new.lua")
            dove.setup({
                parent_target = { new_source_file_placeholder = false },
                targets = {
                    project = {
                        ---@return string
                        source = function()
                            return path
                        end,
                    },
                },
            })

            dove.edit("project")

            assert.is_false(common.is_file_and_readable(path))
        end
    )

    it("rejects a template function", function()
        local path = common.path_join(context.temp_dir, "nested", "new.lua")
        assert.is_false(pcall(context.setup, context, path, {
            ---@return string
            new_source_file_placeholder = function()
                return "return {}"
            end,
        }))

        assert.is_false(common.is_file_and_readable(path))
    end)

    it("uses the selected target's template code", function()
        local project_path = common.path_join(context.temp_dir, "project.lua")
        local custom_path = common.path_join(context.temp_dir, "custom.lua")
        dove.setup({
            parent_target = {
                new_source_file_placeholder = "return { { 'shared' } }",
            },
            targets = {
                project = {
                    source = function()
                        return project_path
                    end,
                },
                custom = {
                    source = function()
                        return custom_path
                    end,
                    new_source_file_placeholder = "return { { 'custom' } }",
                },
            },
        })

        dove.edit("project")
        dove.edit("custom")

        assert.equals("shared", assert(loadfile(project_path))()[1][1])
        assert.equals("custom", assert(loadfile(custom_path))()[1][1])
    end)

    it("does not replace an existing source file with template code", function()
        local path = common.path_join(context.temp_dir, "existing.lua")
        context:write_source_file(path, { "return {}" })
        context:setup(path, {
            new_source_file_placeholder = "return { { 'make test' } }",
        })

        dove.edit("project")

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

    it("edits the unspecified target from the API and command", function()
        local path = common.path_join(context.temp_dir, "unspecified-edit.lua")
        context:setup(path, {
            ---@return string
            unspecified_target_name = function()
                return "project"
            end,
        })

        dove.edit()
        assert.is_true(common.is_file_and_readable(path))

        common.path_remove(path)
        context.original_cmd("source " .. common.fnameescape("plugin/dove.lua"))
        context.original_cmd("Dove edit")
        assert.is_true(common.is_file_and_readable(path))
    end)

    it("edits a string unspecified target from the API and command", function()
        local path = common.path_join(context.temp_dir, "string-edit.lua")
        context:setup(path, { unspecified_target_name = "project" })

        dove.edit()
        assert.is_true(common.is_file_and_readable(path))

        common.path_remove(path)
        context.original_cmd("source " .. common.fnameescape("plugin/dove.lua"))
        context.original_cmd("Dove edit")
        assert.is_true(common.is_file_and_readable(path))
    end)

    it(
        "requires a literal target to delete from the API and command",
        function()
            local path =
                common.path_join(context.temp_dir, "unspecified-delete.lua")
            context:write_source_file(path, { "return {}" })
            context:setup(path, {
                ---@return string
                unspecified_target_name = function()
                    return "project"
                end,
            })

            assert.is_false(pcall(dove.delete_source_file))
            assert.is_true(common.is_file_and_readable(path))
            context.original_cmd(
                "source " .. common.fnameescape("plugin/dove.lua")
            )
            assert.is_false(pcall(context.original_cmd, "Dove delete"))
            assert.is_true(common.is_file_and_readable(path))

            context.original_cmd("Dove delete project")
            assert.is_false(common.is_file_and_readable(path))
        end
    )
end)
