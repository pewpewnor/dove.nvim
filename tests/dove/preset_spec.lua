---@diagnostic disable: undefined-field

local common = require("dove.common")
local preset = require("dove.preset")

describe("preset paths", function()
    local original_expand
    local original_fnameescape
    local path_functions = {
        "file_path",
        "file_name",
        "file_name_no_extension",
        "file_extension",
        "dir_path",
        "dir_name",
        "cwd_path",
        "cwd_name",
        "config_path",
        "data_path",
        "dove_data_path",
    }

    before_each(function()
        original_expand = common.expand
        original_fnameescape = common.fnameescape
        rawset(common, "fnameescape", function(path)
            return "escaped:" .. path
        end)
    end)

    after_each(function()
        rawset(common, "expand", original_expand)
        rawset(common, "fnameescape", original_fnameescape)
    end)

    for _, name in ipairs(path_functions) do
        it("optionally escapes " .. name, function()
            local raw_path = preset[name]({ escape = false })

            assert.equals("escaped:" .. raw_path, preset[name]())
            assert.equals("escaped:" .. raw_path, preset[name]({}))
            assert.equals(
                "escaped:" .. raw_path,
                preset[name]({ escape = true })
            )
        end)
    end

    it("rejects invalid options", function()
        local success, message = pcall(preset.file_path, "no")

        assert.is_false(success)
        assert.matches("options", message)

        success, message = pcall(preset.file_path, { escape = "no" })

        assert.is_false(success)
        assert.matches("options.escape", message, 1, true)

        success, message = pcall(preset.file_path, { relative = "no" })

        assert.is_false(success)
        assert.matches("options.relative", message, 1, true)
    end)

    it("returns optionally relative file and directory paths", function()
        rawset(common, "expand", function(value)
            return value
        end)

        assert.equals("escaped:%:p", preset.file_path())
        assert.equals("escaped:%:p", preset.file_path({ relative = false }))
        assert.equals("escaped:%", preset.file_path({ relative = true }))
        assert.equals("escaped:%:p:h", preset.dir_path())
        assert.equals("escaped:%:p:h", preset.dir_path({ relative = false }))
        assert.equals("escaped:%:h", preset.dir_path({ relative = true }))
        assert.equals(
            "%",
            preset.file_path({ escape = false, relative = true })
        )
        assert.equals(
            "%:h",
            preset.dir_path({ escape = false, relative = true })
        )
    end)

    it("expands a value", function()
        local received
        rawset(common, "expand", function(value)
            received = value
            return "expanded"
        end)

        assert.equals("expanded", preset.expand("anything"))
        assert.equals("anything", received)
    end)

    it("rejects an invalid expand value", function()
        local success, message = pcall(preset.expand, true)

        assert.is_false(success)
        assert.matches("value", message)
    end)
end)
