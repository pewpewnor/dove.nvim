---@diagnostic disable: undefined-field

local common = require("dove.common")
local health = require("dove.health")
local module = require("dove.module")

describe("health check", function()
    it("does not fail before setup", function()
        local config = module.config
        local original_health_error = common.health_error
        local original_health_ok = common.health_ok
        local original_health_start = common.health_start
        module.config = nil
        common.health_error = function() end
        common.health_ok = function() end
        common.health_start = function() end

        local success, message = pcall(health.check)
        module.config = config
        common.health_error = original_health_error
        common.health_ok = original_health_ok
        common.health_start = original_health_start

        assert.is_true(success, message)
    end)
end)
