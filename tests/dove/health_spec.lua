---@diagnostic disable: undefined-field

local health = require("dove.health")

describe("health check", function()
    it("does not fail before setup", function()
        local success, message = pcall(health.check)

        assert.is_true(success, message)
    end)
end)
