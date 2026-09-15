package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local common = require("dove.common")

local configured_plenary_dir = os.getenv("PLENARY_DIR")
local plenary_dir = configured_plenary_dir
    or common.path_join(
        common.get_stdpath("cache"),
        "dove.nvim",
        "plenary.nvim"
    )
local plenary_plugin = common.path_join(plenary_dir, "plugin", "plenary.vim")
if not common.is_file_and_readable(plenary_plugin) then
    if configured_plenary_dir or common.is_directory(plenary_dir) then
        error("dove.nvim: plenary directory is invalid: " .. plenary_dir)
    end
    common.mkdir_with_parents(common.dirname(plenary_dir))
    local result = common.run_process_silent({
        "git",
        "clone",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_dir,
    })
    if result.code ~= 0 then
        common.path_remove_recursive(plenary_dir)
        error("dove.nvim: could not install plenary.nvim")
    end
end

common.rtp_append(".")
common.rtp_append(plenary_dir)

common.cmd("runtime " .. common.path_join("plugin", "plenary.vim"))
require("plenary.busted")
