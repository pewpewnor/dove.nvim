local M = {}

---@param buffer integer
---@param namespace integer
---@param line_start integer
---@param line_end integer
function M.clear_buffer_namespace(buffer, namespace, line_start, line_end)
    vim.api.nvim_buf_clear_namespace(buffer, namespace, line_start, line_end)
end

---@param window integer
---@param force boolean
function M.close_window(window, force)
    vim.api.nvim_win_close(window, force)
end

---@param events string|string[]
---@param opts table
function M.create_autocmd(events, opts)
    vim.api.nvim_create_autocmd(events, opts)
end

---@param listed boolean
---@param scratch boolean
---@return integer
function M.create_buffer(listed, scratch)
    return vim.api.nvim_create_buf(listed, scratch)
end

---@param name string
---@return integer
function M.create_namespace(name)
    return vim.api.nvim_create_namespace(name)
end

---@param buffer integer
function M.disable_diagnostics(buffer)
    vim.diagnostic.enable(false, { bufnr = buffer })
end

---@param command string
function M.cmd(command)
    vim.cmd(command)
end

---@param name string
---@param func fun(opts: table?)
---@param opts table
function M.create_user_command(name, func, opts)
    vim.api.nvim_create_user_command(name, func, opts)
end

---@param path string
---@return string
function M.dirname(path)
    return vim.fs.dirname(path)
end

---@param expr string
---@return string
function M.expand(expr)
    return vim.fn.expand(expr)
end

---@param path string
---@return string
function M.fnameescape(path)
    return vim.fn.fnameescape(path)
end

---@param path string
---@param modifier string
---@return string
function M.fnamemodify(path, modifier)
    return vim.fn.fnamemodify(path, modifier)
end

---@param keys string
---@param mode string
function M.feedkeys(keys, mode)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(keys, true, false, true),
        mode,
        false
    )
end

---@return string
function M.get_cwd()
    return vim.fn.getcwd()
end

---@param buffer integer
---@param line_start integer
---@param line_end integer
---@return string[]
function M.get_buffer_lines(buffer, line_start, line_end)
    return vim.api.nvim_buf_get_lines(buffer, line_start, line_end, false)
end

---@param buffer integer
---@return integer
function M.get_buffer_changedtick(buffer)
    return vim.api.nvim_buf_get_changedtick(buffer)
end

---@param buffer integer
---@param name string
---@return any
function M.get_buffer_option(buffer, name)
    return vim.api.nvim_get_option_value(name, { buf = buffer })
end

---@param buffer integer
---@param name string
---@return any
function M.get_buffer_variable(buffer, name)
    return vim.api.nvim_buf_get_var(buffer, name)
end

---@return integer
function M.get_columns()
    return vim.o.columns
end

---@return integer
function M.get_current_buffer()
    return vim.api.nvim_get_current_buf()
end

---@return integer
function M.get_current_window()
    return vim.api.nvim_get_current_win()
end

---@param window integer
---@return [integer, integer]
function M.get_window_cursor(window)
    return vim.api.nvim_win_get_cursor(window)
end

---@param window integer
---@return table
function M.get_window_config(window)
    return vim.api.nvim_win_get_config(window)
end

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

---@param what string
---@return string
function M.get_stdpath(what)
    return vim.fn.stdpath(what)
end

---@return string
function M.get_tempname()
    return vim.fn.tempname()
end

---@param feature string
---@return boolean
function M.has(feature)
    return vim.fn.has(feature) == 1
end

---@param str string
---@return string
function M.hash_sha256(str)
    return vim.fn.sha256(str)
end

---@param message string
---@param advice string?
function M.health_error(message, advice)
    vim.health.error(message, advice)
end

---@param message string
function M.health_ok(message)
    vim.health.ok(message)
end

---@param name string
function M.health_start(name)
    vim.health.start(name)
end

---@param message string
---@param advice string?
function M.health_warn(message, advice)
    vim.health.warn(message, advice)
end

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

---@param value any
---@return boolean
function M.is_list(value)
    return vim.islist(value)
end

---@param buffer integer
---@return boolean
function M.is_buffer_valid(buffer)
    return vim.api.nvim_buf_is_valid(buffer)
end

---@param window integer
---@return boolean
function M.is_window_valid(window)
    return vim.api.nvim_win_is_valid(window)
end

---@param buffer integer
---@param client_id integer
function M.lsp_detach_client(buffer, client_id)
    vim.lsp.buf_detach_client(buffer, client_id)
end

---@param buffer integer
---@return integer[]
function M.lsp_get_client_ids(buffer)
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

---@param enabled boolean?
function M.enable_loader(enabled)
    vim.loader.enable(enabled)
end

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

---@param ... string
---@return string
function M.path_join(...)
    return vim.fs.joinpath(...)
end

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

---@param path string
---@return string
function M.path_normalize(path)
    return vim.fs.normalize(path)
end

---@param path string
function M.path_remove(path)
    vim.fs.rm(path, { force = true })
end

---@param path string
function M.path_remove_recursive(path)
    vim.fs.rm(path, { force = true, recursive = true })
end

---@param buffer integer
---@param enter boolean
---@param config table
---@return integer
function M.open_window(buffer, enter, config)
    return vim.api.nvim_open_win(buffer, enter, config)
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
function M.run_process_silent(args)
    vim.system(args):wait()
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

---@param pattern string
---@return integer
function M.search(pattern)
    return vim.fn.search(pattern)
end

---@param buffer integer
---@param line_start integer
---@param line_end integer
---@param lines string[]
function M.set_buffer_lines(buffer, line_start, line_end, lines)
    vim.api.nvim_buf_set_lines(buffer, line_start, line_end, false, lines)
end

---@param buffer integer
---@param namespace integer
---@param line integer
---@param column integer
---@param opts table
function M.set_buffer_extmark(buffer, namespace, line, column, opts)
    vim.api.nvim_buf_set_extmark(buffer, namespace, line, column, opts)
end

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

---@param buffer integer
---@param name string
---@param value any
function M.set_buffer_variable(buffer, name, value)
    vim.api.nvim_buf_set_var(buffer, name, value)
end

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

---@param window integer
---@param position [integer, integer]
function M.set_window_cursor(window, position)
    vim.api.nvim_win_set_cursor(window, position)
end

---@param window integer
---@param name string
---@param value any
function M.set_window_option(window, name, value)
    vim.api.nvim_set_option_value(name, value, { win = window })
end

---@param text string
---@return integer
function M.str_display_width(text)
    return vim.fn.strdisplaywidth(text)
end

---@param ... any
---@return table
function M.tbl_deep_extend(...)
    return vim.tbl_deep_extend(...)
end

---@param str string
---@return string
function M.trim(str)
    return vim.trim(str)
end

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
