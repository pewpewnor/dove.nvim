---@diagnostic disable: undefined-field

local common = require("arbit.common")
local picker = require("arbit.picker")

describe("built-in picker", function()
    local original_window

    before_each(function()
        original_window = common.get_current_window()
    end)

    after_each(function()
        local current_window = common.get_current_window()
        if
            current_window ~= original_window
            and common.is_window_valid(current_window)
        then
            common.close_window(current_window, true)
        end
    end)

    it("opens a centered minimum-height fuzzy picker", function()
        local chosen
        picker({ "1. alpha", "2. beta", "3. gamma" }, {
            prompt = "Choose",
        }, function(item, index)
            chosen = { item, index }
        end)

        local window = common.get_current_window()
        local buffer = common.get_current_buffer()
        local config = common.get_window_config(window)
        assert.equals("editor", config.relative)
        assert.equals(12, config.height)
        assert.equals(70, config.width)
        assert.equals(
            math.floor((common.get_columns() - config.width - 2) / 2),
            config.col
        )
        assert.same({ 1, 2 }, common.get_window_cursor(window))
        assert.equals("nofile", common.get_buffer_option(buffer, "buftype"))
        assert.is_false(common.get_buffer_option(buffer, "autocomplete"))
        assert.equals("", common.get_buffer_option(buffer, "filetype"))
        assert.equals("", common.get_buffer_option(buffer, "complete"))
        assert.equals("", common.get_buffer_option(buffer, "completefunc"))
        assert.equals("", common.get_buffer_option(buffer, "formatexpr"))
        assert.equals("", common.get_buffer_option(buffer, "omnifunc"))
        assert.equals("", common.get_buffer_option(buffer, "tagfunc"))
        assert.is_false(common.get_buffer_variable(buffer, "cmp_enabled"))
        assert.is_false(common.get_buffer_variable(buffer, "completion"))

        common.feedkeys("<Down>", "x")
        common.cmd("doautocmd <nomodeline> TextChangedI")
        local lines =
            common.get_buffer_lines(common.get_current_buffer(), 0, -1)
        assert.equals("  1. alpha", lines[3])
        assert.equals("> 2. beta", lines[4])

        common.cmd("stopinsert")
        common.set_current_buffer_lines({ ">   gm  " })
        common.cmd("doautocmd <nomodeline> TextChanged")

        lines = common.get_buffer_lines(common.get_current_buffer(), 0, -1)
        assert.equals(">   gm  ", lines[1])
        assert.equals("", lines[2])
        assert.equals("> 3. gamma", lines[3])
        assert.equals("", lines[12])

        common.feedkeys("<CR>", "x")
        assert.same({ "3. gamma", 3 }, chosen)
    end)

    it("uses formatted item labels", function()
        local items = {
            { name = "first" },
            { name = "second" },
        }
        picker(items, {
            format_item = function(item)
                return "item " .. item.name
            end,
        }, function() end)

        local lines =
            common.get_buffer_lines(common.get_current_buffer(), 0, -1)
        assert.equals("", lines[2])
        assert.equals("> item first", lines[3])
        assert.equals("  item second", lines[4])
    end)
end)
