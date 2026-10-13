local common = require("dove.common")
local preset = require("dove.preset")

return {
    targets = {
        project = {
            source_path = function()
                return common.path_join(
                    preset.dove_data_path(),
                    "projects",
                    preset.hash_sha256(preset.cwd_path()) .. ".lua"
                )
            end,
        },
        filetype = {
            source_path = function()
                return common.path_join(
                    preset.dove_data_path(),
                    "filetypes",
                    preset.file_type() .. ".lua"
                )
            end,
        },
        global = {
            source_path = function()
                return common.path_join(preset.dove_data_path(), "global.lua")
            end,
        },
    },
    fill_each_target = {
        auto_run_single_command = false,
        default_executor = function(command)
            preset.executors.split(command, { nil, "wincmd J | resize -4" })
        end,
        environment = {
            denv = common.tbl_deep_extend("force", {}, preset),
        },
        cmd_list_delimiter = function()
            local shell =
                common.basename(common.get_shell():gsub("\\", "/")):lower()
            return (shell == "cmd" or shell == "cmd.exe") and " & " or "; "
        end,
        new_source_file_template_code = table.concat({
            "return {",
            "    {",
            '        name = "placeholder greeting",',
            "        cmd = \"echo 'Hello from dove.nvim!'\",",
            "    },",
            "}",
            "",
        }, "\n"),
    },
    default_run_target = nil,
    ui = {
        picker = require("dove.picker"),
        format_selection_item = function(name, i)
            return i .. ". " .. name
        end,
    },
}
