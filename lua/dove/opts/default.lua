local common = require("dove.common")
local default_environment = require("dove.opts.environment")

return {
    targets = {
        project = {
            source = function()
                return common.path_join(
                    default_environment.dove_data_path(),
                    "projects",
                    default_environment.hash_sha256(
                        default_environment.cwd_path()
                    ) .. ".lua"
                )
            end,
        },
        filetype = {
            source = function()
                return common.path_join(
                    default_environment.dove_data_path(),
                    "filetypes",
                    default_environment.file_type() .. ".lua"
                )
            end,
        },
        global = {
            source = function()
                return common.path_join(
                    default_environment.dove_data_path(),
                    "global.lua"
                )
            end,
        },
    },
    parent_target = {
        ignore = false,
        auto_run_single_entry = false,
        environment = {
            denv = common.tbl_deep_extend("force", {}, default_environment),
        },
        default_executor = default_environment.executors.default,
        cmd_list_delimiter = function()
            local shell =
                common.basename(common.get_shell():gsub("\\", "/")):lower()
            return (shell == "cmd" or shell == "cmd.exe") and " & " or "; "
        end,
        ---@return string
        new_source_file_placeholder_text = function()
            return table.concat({
                "return {",
                "    {",
                '        name = "placeholder greeting",',
                "        cmd = \"echo 'Hello from dove.nvim!'\",",
                "    },",
                "}",
                "",
            }, "\n")
        end,
    },
    unspecified_target_name = nil,
    ui = {
        picker = require("dove.picker"),
        format_selection_item = function(name, i)
            return i .. ". " .. name
        end,
    },
}
