---@diagnostic disable: undefined-field

local dove = require("dove")
local simulation = require("tests.dove.simulation_helpers")

describe("source file execution", function()
    local context

    before_each(function()
        context = simulation.new()
    end)

    after_each(function()
        context:cleanup()
    end)

    it("runs named and positional command tables", function()
        local path = common.path_join(temp_dir, "project.lua")
        write_source_file(path, {
            "return {",
            '    { "touch hello" },',
            '    { name = "a", cmd = "echo first" },',
            '    { "echo second", name = "b" },',
            "}",
        })
        setup(path, { auto_run_single_command = false })

        dove.run_target("project")

        assert.equals("touch hello", executed_commands[1])

        local selected
        picker = function(items)
            selected = items
        end
        dove.run_target("project")
        assert.equals("echo first", selected[2].command)
        assert.equals("a", selected[2].name:match("a$"))
        assert.equals("echo second", selected[3].command)
    end)

    it("rejects string entries", function()
        local path = common.path_join(temp_dir, "string-entry.lua")
        write_source_file(path, {
            "return {",
            '    { cmd = "echo valid" },',
            '    "echo invalid",',
            "}",
        })
        setup(path, { auto_run_single_command = false })

        local success, message = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.matches("each entry must be a table", message)
        assert.same({}, executed_commands)
    end)

    it("runs a command list in one shell", function()
        local path = common.path_join(temp_dir, "command-list.lua")
        write_source_file(path, {
            "return {",
            "    {",
            '        name = "steps",',
            "        cmd = {",
            '            "first",',
            '            "second",',
            "        },",
            "    },",
            "    {",
            '        name = "single",',
            '        cmd = "third",',
            "    },",
            "}",
        })
        setup(path, {
            auto_run_single_command = false,
            cmd_list_delimiter = "; ",
        })

        dove.run_target("project")

        assert.equals(1, #executed_commands)
        assert.equals("first; second", executed_commands[1])

        local selected
        picker = function(items)
            selected = items
        end
        dove.run_target("project")

        assert.equals(2, #selected)
        assert.equals("third", selected[2].command)
    end)

    it("joins a command list with the configured delimiter", function()
        local path = common.path_join(temp_dir, "command-list-delimiter.lua")
        write_source_file(path, {
            "return {",
            '    { cmd = { "first", "second" } },',
            "}",
        })
        setup(path, { cmd_list_delimiter = " && " })

        dove.run_target("project")

        assert.same({ "first && second" }, executed_commands)
    end)

    it("uses shell-compatible default delimiters", function()
        local path = common.path_join(temp_dir, "default-command-list.lua")
        write_source_file(path, {
            "return {",
            '    { cmd = { "first", "second" } },',
            "}",
        })
        local cases = {
            { shell = "/bin/sh", command = "first; second" },
            { shell = "/bin/zsh", command = "first; second" },
            {
                shell = [[C:\Windows\System32\cmd.exe]],
                command = "first & second",
            },
            {
                shell = [[C:\Program Files\PowerShell\7\pwsh.exe]],
                command = "first; second",
            },
        }

        for _, case in ipairs(cases) do
            executed_commands = {}
            set_common("get_shell", function()
                return case.shell
            end)
            setup(path)

            dove.run_target("project")

            assert.same({ case.command }, executed_commands)
        end
    end)

    it("uses the configured picker", function()
        local path = common.path_join(temp_dir, "selection-ui.lua")
        write_source_file(path, {
            "return {",
            '    { "echo first" },',
            '    { "echo second" },',
            "}",
        })
        local received_prompt
        local received_labels
        setup(path, {
            auto_run_single_command = false,
            ui = {
                picker = function(items, opts, on_choice)
                    received_prompt = opts.prompt
                    received_labels = {
                        opts.format_item(items[1]),
                        opts.format_item(items[2]),
                    }
                    on_choice(items[2], 2)
                end,
            },
        })

        dove.run_target("project")

        assert.same({ "1. echo first", "2. echo second" }, received_labels)
        assert.same({ "echo second" }, executed_commands)
    end)

    it("does not enumerate entries when disabled", function()
        local path = common.path_join(temp_dir, "selection-labels.lua")
        write_source_file(path, {
            "return {",
            '    { "echo first" },',
            '    { "echo second" },',
            "}",
        })
        local received_labels
        setup(path, {
            auto_run_single_command = false,
            ui = {
                enumerate_entries = false,
                picker = function(items, opts, on_choice)
                    received_labels = {
                        opts.format_item(items[1]),
                        opts.format_item(items[2]),
                    }
                    on_choice(items[1], 1)
                end,
            },
        })

        dove.run_target("project")

        assert.same({ "echo first", "echo second" }, received_labels)
        assert.same({ "echo first" }, executed_commands)
    end)

    it("rejects one entry without an outer list", function()
        local path = common.path_join(temp_dir, "single-entry.lua")
        write_source_file(path, {
            'return { name = "a", cmd = "touch hello" }',
        })
        setup(path)

        local success, message = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.matches("must return a list of entries", message)
        assert.same({}, executed_commands)
    end)

    it("accepts an empty source list", function()
        local path = common.path_join(temp_dir, "empty.lua")
        write_source_file(path, { "return {}" })
        setup(path)

        assert.is_true(pcall(dove.run_target, "project"))
        assert.same({}, executed_commands)
    end)

    it("exposes the configured environment under dove", function()
        local path = common.path_join(temp_dir, "environment.lua")
        write_source_file(path, {
            "assert(file_path == nil)",
            "assert(executors == nil)",
            "assert(prefix == nil)",
            'assert(type(dove.dir_name) == "function")',
            'assert(type(dove.executors.bg_silent) == "function")',
            "return {",
            "    { dove.prefix .. dove.file_path(), executor = dove.executors.capture },",
            "}",
        })
        setup(path, {
            environment = {
                prefix = "wc ",
                file_path = function()
                    return "custom.lua"
                end,
                executors = { capture = test_executor },
            },
        })

        dove.run_target("project")

        assert.same({ "wc custom.lua" }, executed_commands)
        assert.is_nil(require("dove.module").config.environment.require)
    end)

    it("flattens source files required from expanded paths", function()
        local imported_path = common.path_join(temp_dir, "shared.lua")
        local path = common.path_join(temp_dir, "project.lua")
        write_source_file(imported_path, { 'return { { "echo imported" } }' })
        write_source_file(path, {
            "return {",
            '    { "echo local" },',
            '    require("~/template.lua"),',
            "}",
        })
        set_common("expand", function(value)
            if value == "~/template.lua" then
                return imported_path
            end
            return original_expand(value)
        end)
        setup(path, { auto_run_single_command = false })

        local selected
        picker = function(items)
            selected = items
        end
        dove.run_target("project")

        assert.equals(2, #selected)
        assert.equals("echo local", selected[1].name)
        assert.equals("echo imported", selected[2].name)
    end)

    it("resolves relative required paths from the requiring file", function()
        local imported_path = common.path_join(temp_dir, "shared.lua")
        local path = common.path_join(temp_dir, "project.lua")
        write_source_file(imported_path, { 'return { { "echo relative" } }' })
        write_source_file(path, { 'return { require("./shared.lua") }' })
        setup(path)

        dove.run_target("project")

        assert.same({ "echo relative" }, executed_commands)
    end)

    it("attributes imported entry errors to the imported file", function()
        local imported_path = common.path_join(temp_dir, "invalid-shared.lua")
        local path = common.path_join(temp_dir, "project-with-import.lua")
        write_source_file(imported_path, { 'return { "invalid" }' })
        write_source_file(
            path,
            { 'return { require("./invalid-shared.lua") }' }
        )
        setup(path)

        local success, message = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.matches("invalid%-shared%.lua", message)
        assert.is_nil(message:match("project%-with%-import%.lua"))
    end)

    it("reloads files on every run", function()
        local path = common.path_join(temp_dir, "reload.lua")
        write_source_file(path, { 'return { { "echo first" } }' })
        setup(path)
        dove.run_target("project")
        write_source_file(path, { 'return { { "echo second" } }' })

        dove.run_target("project")

        assert.same({ "echo first", "echo second" }, executed_commands)
    end)

    it("loads source files with the bytecode loader enabled", function()
        local path = common.path_join(temp_dir, "loader.lua")
        write_source_file(path, { 'return { { "echo loaded" } }' })
        setup(path)
        common.enable_loader()
        loader_enabled = true

        dove.run_target("project")

        assert.same({ "echo loaded" }, executed_commands)
    end)

    it("runs the previous task again", function()
        local path = common.path_join(temp_dir, "previous.lua")
        write_source_file(path, { 'return { { "echo previous" } }' })
        setup(path)
        dove.run_target("project")

        dove.run_prev_task()

        assert.same({ "echo previous", "echo previous" }, executed_commands)
    end)

    it("creates a template when editing a missing source file", function()
        local path = common.path_join(temp_dir, "nested", "new.lua")
        setup(path)

        dove.edit_source_file("project")

        assert.is_true(common.is_file_and_readable(path))
        local chunk, load_error = loadfile(path)
        assert.is_nil(load_error)
        local source = assert(chunk)()
        assert.equals("greetings", source[1].name)
        assert.equals("echo Hello, World!", source[1].cmd)
    end)

    it("deletes a target's source file", function()
        local path = common.path_join(temp_dir, "delete.lua")
        write_source_file(path, { "return {}" })
        setup(path)

        dove.delete_source_file("project")

        assert.is_false(common.is_file_and_readable(path))
    end)

    it("rejects files that do not return a table", function()
        local path = common.path_join(temp_dir, "invalid.lua")
        write_source_file(path, { 'return "invalid"' })
        setup(path)

        local success, message = pcall(dove.run_target, "project")

        assert.is_false(success)
        assert.matches("must return a table", message)
    end)
end)
