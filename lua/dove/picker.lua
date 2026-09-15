local common = require("dove.common")

local minimum_height = 12
local minimum_width = 70
local namespace = common.create_namespace("dove.picker")

local function disable_completion_plugins()
    local blink = package.loaded["blink.cmp"]
    if blink and blink.hide then
        blink.hide()
    end
    local cmp = package.loaded.cmp
    if cmp then
        cmp.setup.buffer({ enabled = false })
        cmp.close()
    end
end

---@param label string
---@param query string
---@return integer?
local function match_score(label, query)
    if query == "" then
        return 0
    end

    local normalized_label = label:lower()
    local normalized_query = query:lower()
    local substring_start = normalized_label:find(normalized_query, 1, true)
    if substring_start then
        return 100000 - substring_start * 100 - #label
    end

    local score = -#label
    local label_index = 1
    local previous_match = 0
    for query_index = 1, #normalized_query do
        local query_character = normalized_query:sub(query_index, query_index)
        local match_index =
            normalized_label:find(query_character, label_index, true)
        if not match_index then
            return nil
        end
        score = score - match_index
        if match_index == previous_match + 1 then
            score = score + 20
        end
        if
            match_index == 1
            or normalized_label
                :sub(match_index - 1, match_index - 1)
                :match("[%s%p]")
        then
            score = score + 10
        end
        previous_match = match_index
        label_index = match_index + 1
    end
    return score
end

---@param entries dove.PickerEntry[]
---@param query string
---@return dove.PickerEntry[]
local function filter_entries(entries, query)
    ---@type dove.PickerEntry[]
    local filtered = {}
    for _, entry in ipairs(entries) do
        local score = match_score(entry.label, query)
        if score then
            filtered[#filtered + 1] = {
                index = entry.index,
                item = entry.item,
                label = entry.label,
                score = score,
            }
        end
    end
    table.sort(filtered, function(left, right)
        if left.score == right.score then
            return left.index < right.index
        end
        return left.score > right.score
    end)
    return filtered
end

---@param items any[]
---@param opts dove.PickerOptions
---@param on_choice fun(item: any?, index: integer?)
local function picker(items, opts, on_choice)
    opts = opts or {}
    local format_item = opts.format_item or tostring
    ---@type dove.PickerEntry[]
    local entries = {}
    local content_width = 0
    for index, item in ipairs(items) do
        local label = format_item(item):gsub("[\r\n]+", " ")
        entries[index] = {
            index = index,
            item = item,
            label = label,
        }
        content_width = math.max(content_width, common.str_display_width(label))
    end

    local editor_lines = common.get_lines()
    local editor_columns = common.get_columns()
    local available_height = math.max(1, editor_lines - 4)
    local maximum_height =
        math.max(minimum_height, math.floor(editor_lines * 0.7))
    local height = math.min(
        math.max(minimum_height, #entries + 1),
        maximum_height,
        available_height
    )
    local available_width = math.max(1, editor_columns - 4)
    local width =
        math.min(math.max(minimum_width, content_width + 4), available_width)
    local prompt = (opts.prompt or "Select one of"):gsub("[\r\n]+", " ")
    local buffer = common.create_buffer(false, true)
    common.set_buffer_option(buffer, "autocomplete", false)
    common.set_buffer_option(buffer, "bufhidden", "wipe")
    common.set_buffer_option(buffer, "buftype", "nofile")
    common.set_buffer_option(buffer, "complete", "")
    common.set_buffer_option(buffer, "completefunc", "")
    common.set_buffer_option(buffer, "formatexpr", "")
    common.set_buffer_option(buffer, "omnifunc", "")
    common.set_buffer_option(buffer, "tagfunc", "")
    common.set_buffer_variable(buffer, "cmp_enabled", false)
    common.set_buffer_variable(buffer, "completion", false)
    common.disable_diagnostics(buffer)

    local window = common.open_window(buffer, true, {
        relative = "editor",
        row = math.max(0, math.floor((editor_lines - height) / 2) - 1),
        col = math.max(0, math.floor((editor_columns - width - 2) / 2)),
        width = width,
        height = height,
        border = "rounded",
        style = "minimal",
        title = " " .. prompt .. " ",
        title_pos = "center",
    })
    common.set_window_option(window, "wrap", false)
    common.set_window_option(
        window,
        "winhighlight",
        "Normal:NormalFloat,FloatBorder:FloatBorder"
    )

    ---@type dove.PickerState
    local state = {
        filtered = entries,
        finished = false,
        query = "",
        render_tick = nil,
        selected = #entries > 0 and 1 or 0,
        updating = false,
    }

    local function render()
        if state.finished or not common.is_buffer_valid(buffer) then
            return
        end
        state.updating = true
        ---@type string[]
        local lines = { "> " .. state.query, "" }
        local result_capacity = height - 2
        local first_result = 1
        if state.selected > result_capacity then
            first_result = state.selected - result_capacity + 1
        end
        for result_offset = 0, result_capacity - 1 do
            local result_index = first_result + result_offset
            local entry = state.filtered[result_index]
            if not entry then
                break
            end
            local prefix = result_index == state.selected and "> " or "  "
            lines[#lines + 1] = prefix .. entry.label
        end
        if #state.filtered == 0 then
            lines[3] = "  No matches"
        end
        while #lines < height do
            lines[#lines + 1] = ""
        end
        common.set_buffer_lines(buffer, 0, -1, lines)
        state.render_tick = common.get_buffer_changedtick(buffer)
        common.clear_buffer_namespace(buffer, namespace, 0, -1)
        common.set_buffer_extmark(buffer, namespace, 0, 0, {
            end_col = 2,
            hl_group = "Question",
        })
        if #state.filtered == 0 then
            common.set_buffer_extmark(buffer, namespace, 2, 0, {
                end_col = #lines[3],
                hl_group = "Comment",
            })
        elseif state.selected > 0 then
            common.set_buffer_extmark(
                buffer,
                namespace,
                state.selected - first_result + 2,
                0,
                {
                    line_hl_group = "PmenuSel",
                }
            )
        end
        state.updating = false
    end

    local function finish(entry)
        if state.finished then
            return
        end
        state.finished = true
        common.cmd("stopinsert")
        if common.is_window_valid(window) then
            common.close_window(window, true)
        end
        if entry then
            on_choice(entry.item, entry.index)
        else
            on_choice(nil, nil)
        end
    end

    local function choose()
        finish(state.filtered[state.selected])
    end

    local function move_selection(offset)
        local count = #state.filtered
        if count == 0 then
            return
        end
        state.selected = (state.selected - 1 + offset) % count + 1
        render()
    end

    local function focus_prompt()
        if common.is_window_valid(window) then
            common.set_window_cursor(window, { 1, #state.query + 1 })
            common.cmd("startinsert!")
        end
    end

    local keymap_options = { nowait = true, silent = true }
    for _, key in ipairs({ "<Down>", "<C-n>", "<C-j>", "<Tab>" }) do
        common.set_buffer_keymap(buffer, { "i", "n" }, key, function()
            move_selection(1)
        end, keymap_options)
    end
    for _, key in ipairs({ "<Up>", "<C-p>", "<C-k>", "<S-Tab>" }) do
        common.set_buffer_keymap(buffer, { "i", "n" }, key, function()
            move_selection(-1)
        end, keymap_options)
    end
    for _, key in ipairs({ "<CR>", "<C-y>" }) do
        common.set_buffer_keymap(
            buffer,
            { "i", "n" },
            key,
            choose,
            keymap_options
        )
    end
    for _, key in ipairs({ "<Esc>", "<C-c>" }) do
        common.set_buffer_keymap(buffer, { "i", "n" }, key, function()
            finish(nil)
        end, keymap_options)
    end
    common.set_buffer_keymap(buffer, "n", "q", function()
        finish(nil)
    end, keymap_options)
    for _, key in ipairs({ "i", "a" }) do
        common.set_buffer_keymap(buffer, "n", key, focus_prompt, keymap_options)
    end

    common.create_autocmd("CursorMovedI", {
        buffer = buffer,
        callback = function()
            local cursor = common.get_window_cursor(window)
            if cursor[1] ~= 1 or cursor[2] < 2 then
                common.set_window_cursor(window, { 1, 2 })
            end
        end,
    })
    common.create_autocmd("LspAttach", {
        buffer = buffer,
        callback = function(event)
            common.lsp_detach_client(buffer, event.data.client_id)
        end,
    })
    for _, client_id in ipairs(common.lsp_get_client_ids(buffer)) do
        common.lsp_detach_client(buffer, client_id)
    end
    common.create_autocmd("InsertEnter", {
        buffer = buffer,
        callback = disable_completion_plugins,
    })
    common.create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = buffer,
        callback = function()
            if state.updating or state.finished then
                return
            end
            if common.get_buffer_changedtick(buffer) == state.render_tick then
                return
            end
            local cursor_column = common.get_window_cursor(window)[2]
            local lines = common.get_buffer_lines(buffer, 0, 1)
            local prompt_line = lines[1] or ""
            if prompt_line:sub(1, 2) == "> " then
                state.query = prompt_line:sub(3)
            else
                state.query = prompt_line:gsub("^>?%s*", "")
            end
            state.filtered = filter_entries(entries, common.trim(state.query))
            state.selected = #state.filtered > 0 and 1 or 0
            render()
            if common.is_window_valid(window) then
                common.set_window_cursor(window, {
                    1,
                    math.max(2, math.min(cursor_column, #state.query + 2)),
                })
            end
        end,
    })
    common.create_autocmd("WinClosed", {
        pattern = tostring(window),
        once = true,
        callback = function()
            if not state.finished then
                state.finished = true
                on_choice(nil, nil)
            end
        end,
    })

    render()
    common.set_window_cursor(window, { 1, 1 })
    disable_completion_plugins()
    common.cmd("startinsert!")
end

return picker
