---@diagnostic disable: undefined-field

local common = require("dove.common")
local executors = require("dove.executors")

describe("executors", function()
    local original_print
    local original_cmd
    local original_run_shell_async

    local function set_common(name, value)
        rawset(common, name, value)
    end

    before_each(function()
        original_print = print
        original_cmd = common.cmd
        original_run_shell_async = common.run_shell_async
    end)

    after_each(function()
        print = original_print
        set_common("cmd", original_cmd)
        set_common("run_shell_async", original_run_shell_async)
    end)

    it("sets the height of a split terminal", function()
        local command
        set_common("cmd", function(value)
            command = value
        end)

        executors.split("make test", { "12" })

        assert.equals("rightbelow 12 split | terminal make test", command)
    end)

    it("runs a command after opening a split terminal", function()
        local command
        set_common("cmd", function(value)
            command = value
        end)

        executors.split("make test", { nil, "wincmd J | resize -3" })

        assert.equals(
            "rightbelow split | wincmd J | resize -3 | terminal make test",
            command
        )
    end)

    it("prints the actual background job exit code", function()
        local on_exit = function(_) end
        local message
        set_common("run_shell_async", function(_, callback)
            on_exit = callback
        end)
        print = function(value)
            message = value
        end

        executors.bg_exit_status("ignored command")
        on_exit({ code = 7 })

        assert.equals("dove.nvim: command job error (exit code 7)", message)
    end)
end)
