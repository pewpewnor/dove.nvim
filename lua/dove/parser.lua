local common = require("dove.common")

local M = {}

---@param config dove.Config
function M.init(config)
    M.config = config
end

---@type table<table, string>
local imported_lists = setmetatable({}, { __mode = "k" })

---@param module_name string
---@return boolean
local function is_file_module(module_name)
    return module_name:sub(1, 1) == "/"
        or module_name:sub(1, 1) == "~"
        or module_name:sub(1, 2) == "./"
        or module_name:sub(1, 3) == "../"
        or module_name:sub(-4) == ".lua"
end

---@param path string
---@param parent_path string?
---@return string
local function resolve_import_path(path, parent_path)
    local expanded = common.expand(path)
    if parent_path then
        expanded = common.path_absolute(expanded, common.dirname(parent_path))
    end
    return common.path_normalize(expanded)
end

---@param path string
---@param loading table<string, boolean>
---@return table
local function load_source_file(path, loading)
    path = common.path_normalize(common.expand(path))
    if loading[path] then
        error(string.format("dove.nvim: circular require of '%s'", path))
    end
    loading[path] = true

    ---@type table<string, any>
    local environment = setmetatable({
        dove = M.config.environment,
    }, { __index = _G })

    environment.require = function(module_name)
        common.validate("require path", module_name, "string")
        if not is_file_module(module_name) then
            return require(module_name)
        end
        local imported_path = resolve_import_path(module_name, path)
        local imported = load_source_file(imported_path, loading)
        imported_lists[imported] = imported_path
        return imported
    end

    local chunk, load_error = common.load_source_file(path, environment)
    if not chunk then
        loading[path] = nil
        error(
            string.format(
                "dove.nvim: cannot load source file '%s': %s",
                path,
                load_error
            )
        )
    end

    local success, result = pcall(chunk)
    loading[path] = nil
    if not success then
        error(
            string.format(
                "dove.nvim: error evaluating source file '%s': %s",
                path,
                result
            )
        )
    end
    if type(result) ~= "table" then
        error(
            string.format(
                "dove.nvim: source file '%s' must return a table",
                path
            )
        )
    end
    return result
end

---@param command string|string[]?
---@param source_file_path string
---@return string
local function normalize_command(command, source_file_path)
    common.validate("entry command", command, { "string", "table" })
    ---@cast command string|string[]
    if type(command) == "string" then
        return command
    end
    if not common.is_list(command) then
        error(
            string.format(
                "dove.nvim: entry command must be a list in '%s'",
                source_file_path
            )
        )
    end
    if #command == 0 then
        error(
            string.format(
                "dove.nvim: entry command list cannot be empty in '%s'",
                source_file_path
            )
        )
    end
    ---@type string[]
    local commands = {}
    for index, item in ipairs(command) do
        common.validate("entry command " .. index, item, "string")
        commands[index] = item
    end
    return table.concat(commands, M.config.cmd_list_delimiter)
end

---@param item dove.RawEntry
---@param source_file_path string
---@return dove.ProcessedEntry
local function parse_entry(item, source_file_path)
    if item[1] ~= nil and item.cmd ~= nil then
        error(
            string.format(
                "dove.nvim: entry cannot have both a positional command and 'cmd' in '%s'",
                source_file_path
            )
        )
    end
    local command = normalize_command(item[1] or item.cmd, source_file_path)
    common.validate("entry name", item.name, { "string", "nil" })
    common.validate("entry executor", item.executor, { "function", "nil" })
    return {
        name = item.name or command,
        command = command,
        executor = item.executor,
    }
end

---@param list table
---@param source_file_path string
---@return dove.ProcessedEntry[]
local function parse_list(list, source_file_path)
    if not common.is_list(list) then
        error(
            string.format(
                "dove.nvim: source file '%s' must return a list of entries",
                source_file_path
            )
        )
    end
    ---@type dove.ProcessedEntry[]
    local entries = {}
    for _, item in ipairs(list) do
        local imported_path = imported_lists[item]
        if imported_path then
            local imported_entries = parse_list(item, imported_path)
            for _, entry in ipairs(imported_entries) do
                entries[#entries + 1] = entry
            end
        elseif type(item) == "table" then
            entries[#entries + 1] = parse_entry(item, source_file_path)
        else
            error(
                string.format(
                    "dove.nvim: each entry must be a table in '%s'",
                    source_file_path
                )
            )
        end
    end
    return entries
end

---@param path string
---@return dove.ProcessedEntry[]?
function M.parse_source_file(path)
    if not common.is_file_and_readable(path) then
        print("dove.nvim: no source file found")
        return nil
    end
    ---@type table<string, boolean>
    local loading = {}
    local source = load_source_file(path, loading)
    return parse_list(source, path)
end

return M
