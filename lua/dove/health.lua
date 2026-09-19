local common = require("dove.common")
local module = require("dove.module")
local validate_opts = require("dove.validate_opts")

local M = {}

local function check_neovim_version()
    if common.has("nvim-0.12") then
        common.health_ok("neovim version is v0.12.0 or newer")
    else
        common.health_error(
            "neovim v0.12.0 or newer is required",
            "upgrade your neovim installation"
        )
    end
end

---@param config any
---@return nil
local function validate_config(config)
    validate_opts(common.tbl_deep_extend("force", {}, config))
end

---@param validation_error any
---@return string
local function get_validation_error_message(validation_error)
    local message = tostring(validation_error)
    return message:match("dove%.nvim: (.+)") or message
end

---@return boolean
local function check_setup_called()
    if not module.config then
        common.health_error(
            "setup() did not complete",
            "ensure require('dove').setup() is called in your configuration with no validation errors"
        )
        return false
    end

    local success, validation_error = pcall(validate_config, module.config)
    if not success then
        common.health_error(
            "setup() options are invalid: "
                .. get_validation_error_message(validation_error)
        )
        return false
    end

    common.health_ok("setup() completed")
    return true
end

local function check_shell()
    local shell = common.get_shell()
    if common.is_executable(shell) then
        common.health_ok(string.format("shell '%s' is executable", shell))
    else
        common.health_error(
            string.format("shell '%s' is not executable", shell),
            "every executor runs commands through 'shell', set it to an installed shell"
        )
    end
end

function M.check()
    common.health_start("dove.nvim")

    check_neovim_version()
    check_setup_called()
    check_shell()
end

return M
