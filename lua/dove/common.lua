local M = {}

---@type fun(buffer: integer, namespace: integer, line_start: integer, line_end: integer)
M.clear_buffer_namespace = vim.api.nvim_buf_clear_namespace

---@type fun(window: integer, force: boolean)
M.close_window = vim.api.nvim_win_close

---@type fun(events: string|string[], opts: table): integer
M.create_autocmd = vim.api.nvim_create_autocmd

---@type fun(listed: boolean, scratch: boolean): integer
M.create_buffer = vim.api.nvim_create_buf

---@type fun(name: string): integer
M.create_namespace = vim.api.nvim_create_namespace

---@param buffer integer
function M.disable_diagnostics(buffer)
    vim.diagnostic.enable(false, { bufnr = buffer })
end

---@type fun(command: string)
M.cmd = vim.cmd

---@type fun(name: string, func: fun(opts: table?), opts: table)
M.create_user_command = vim.api.nvim_create_user_command

---@type fun(path: string): string
M.dirname = vim.fs.dirname

---@type fun(expr: string): string
M.expand = vim.fn.expand

---@type fun(path: string): string
M.fnameescape = vim.fn.fnameescape

---@type fun(path: string, modifier: string): string
M.fnamemodify = vim.fn.fnamemodify

---@param keys string
---@param mode string
function M.feedkeys(keys, mode)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(keys, true, false, true),
        mode,
        false
    )
end

---@type fun(): string
M.get_cwd = vim.fn.getcwd

---@param buffer integer
---@param line_start integer
---@param line_end integer
---@return string[]
function M.get_buffer_lines(buffer, line_start, line_end)
    return vim.api.nvim_buf_get_lines(buffer, line_start, line_end, false)
end

---@type fun(buffer: integer): integer
M.get_buffer_changedtick = vim.api.nvim_buf_get_changedtick

---@param buffer integer
---@param name string
---@return any
function M.get_buffer_option(buffer, name)
    return vim.api.nvim_get_option_value(name, { buf = buffer })
end

---@type fun(buffer: integer, name: string): any
M.get_buffer_variable = vim.api.nvim_buf_get_var

---@return integer
function M.get_columns()
    return vim.o.columns
end

---@type fun(): integer
M.get_current_buffer = vim.api.nvim_get_current_buf

---@type fun(): integer
M.get_current_window = vim.api.nvim_get_current_win

---@type fun(window: integer): [integer, integer]
M.get_window_cursor = vim.api.nvim_win_get_cursor

---@type fun(window: integer): table
M.get_window_config = vim.api.nvim_win_get_config

---@return string
function M.get_filetype()
    return vim.bo.filetype
end

---@return integer
function M.get_lines()
    return vim.o.lines
end

---@return string
function M.get_shell()
    return vim.o.shell
end

---@return string
function M.get_default_cmd_list_delimiter()
    local shell_name = M.get_shell():gsub("\\", "/"):match("([^/]+)$") or ""
    shell_name = shell_name:lower()
    if shell_name == "cmd" or shell_name == "cmd.exe" then
        return " & "
    end
    return "; "
end

---@type fun(what: string): string
M.get_stdpath = vim.fn.stdpath

---@type fun(): string
M.get_tempname = vim.fn.tempname

---@param feature string
---@return boolean
function M.has(feature)
    return vim.fn.has(feature) == 1
end

---@type fun(str: string): string
M.hash_sha256 = vim.fn.sha256

---@type fun(message: string, advice: string?)
M.health_error = vim.health.error

---@type fun(message: string)
M.health_ok = vim.health.ok

---@type fun(name: string)
M.health_start = vim.health.start

---@type fun(message: string, advice: string?)
M.health_warn = vim.health.warn

---@param path string
---@return boolean
function M.is_directory(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end

---@param path string
---@return boolean
function M.is_directory_writable(path)
    return vim.fn.filewritable(path) == 2
end

---@param name string
---@return boolean
function M.is_executable(name)
    return vim.fn.executable(name) == 1
end

---@param path string
---@return boolean
function M.is_file_and_readable(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "file"
end

---@type fun(value: any): boolean
M.is_list = vim.islist

---@type fun(buffer: integer): boolean
M.is_buffer_valid = vim.api.nvim_buf_is_valid

---@type fun(window: integer): boolean
M.is_window_valid = vim.api.nvim_win_is_valid

---@type fun(buffer: integer, client_id: integer)
M.lsp_detach_client = vim.lsp.buf_detach_client

---@param buffer integer
---@return integer[]
function M.lsp_get_client_ids(buffer)
    ---@type integer[]
    local client_ids = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buffer })) do
        client_ids[#client_ids + 1] = client["id"]
    end
    return client_ids
end

---@param path string
---@param environment table
---@return function?, string?
function M.load_source_file(path, environment)
    return loadfile(path, "bt", environment)
end

---@type fun(enabled: boolean?)
M.enable_loader = vim.loader.enable

---@param path string
---@return boolean
function M.mkdir_with_parents(path)
    if M.is_directory(path) then
        return true
    end
    local parent = M.dirname(path)
    if parent and parent ~= path then
        M.mkdir_with_parents(parent)
    end
    return vim.uv.fs_mkdir(path, 493) == true
end

---@type fun(...: string): string
M.path_join = vim.fs.joinpath

---@param path string
---@param base string
---@return string
function M.path_absolute(path, base)
    local absolute = vim.fs.abspath(path)
    if vim.fs.normalize(path) == vim.fs.normalize(absolute) then
        return absolute
    end
    return vim.fs.abspath(vim.fs.joinpath(base, path))
end

---@type fun(path: string): string
M.path_normalize = vim.fs.normalize

---@param path string
function M.path_remove(path)
    vim.fs.rm(path, { force = true })
end

---@param path string
function M.path_remove_recursive(path)
    vim.fs.rm(path, { force = true, recursive = true })
end

---@type fun(buffer: integer, enter: boolean, config: table): integer
M.open_window = vim.api.nvim_open_win

---@param command string
function M.open_terminal(command)
    vim.api.nvim_cmd({
        cmd = "terminal",
        args = { command },
        magic = { file = false, bar = false },
    }, {})
end

---@param path string
---@return string?
function M.read_file(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param path string
function M.rtp_append(path)
    vim.opt.runtimepath:append(path)
end

---@param args string[]
---@return { code: integer, signal: integer, stdout?: string, stderr?: string }
function M.run_process_silent(args)
    return vim.system(args):wait()
end

---@param command string
---@param on_exit? fun(result: {code: integer, stdout: string, stderr: string})
function M.run_shell_async(command, on_exit)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }, {}, on_exit)
end

---@param command string
---@return string
function M.run_shell_output(command)
    local result = vim.system(
        { vim.o.shell, vim.o.shellcmdflag, command },
        { text = true }
    ):wait()
    return result.stdout
end

---@param command string
function M.run_shell_silent(command)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }):wait()
end

---@type fun(pattern: string): integer
M.search = vim.fn.search

---@param buffer integer
---@param line_start integer
---@param line_end integer
---@param lines string[]
function M.set_buffer_lines(buffer, line_start, line_end, lines)
    vim.api.nvim_buf_set_lines(buffer, line_start, line_end, false, lines)
end

---@type fun(buffer: integer, namespace: integer, line: integer, column: integer, opts: table): integer
M.set_buffer_extmark = vim.api.nvim_buf_set_extmark

---@param buffer integer
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts table?
function M.set_buffer_keymap(buffer, mode, lhs, rhs, opts)
    opts = opts or {}
    opts.buffer = buffer
    vim.keymap.set(mode, lhs, rhs, opts)
end

---@param buffer integer
---@param name string
---@param value any
function M.set_buffer_option(buffer, name, value)
    vim.api.nvim_set_option_value(name, value, { buf = buffer })
end

---@type fun(buffer: integer, name: string, value: any)
M.set_buffer_variable = vim.api.nvim_buf_set_var

---@param lines string[]
function M.set_current_buffer_lines(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

---@param name string
function M.set_current_buffer_name(name)
    vim.api.nvim_buf_set_name(0, name)
end

---@param filetype string
function M.set_filetype(filetype)
    vim.bo.filetype = filetype
end

---@type fun(window: integer, position: [integer, integer])
M.set_window_cursor = vim.api.nvim_win_set_cursor

---@param window integer
---@param name string
---@param value any
function M.set_window_option(window, name, value)
    vim.api.nvim_set_option_value(name, value, { win = window })
end

---@type fun(text: string): integer
M.str_display_width = vim.fn.strdisplaywidth

---@type fun(...: any): table
M.tbl_deep_extend = vim.tbl_deep_extend

---@type fun(str: string): string
M.trim = vim.trim

---@param name string
---@param val any
---@param expected_type any
function M.validate(name, val, expected_type)
    local success, message = pcall(vim.validate, {
        [name] = { val, expected_type },
    })
    if not success then
        error("dove.nvim: " .. message)
    end
end

---@param path string
---@param lines string[]
---@param mode nil|"a"
---@return boolean
function M.write_file(path, lines, mode)
    return vim.fn.writefile(lines, path, mode or "") == 0
end

return M
