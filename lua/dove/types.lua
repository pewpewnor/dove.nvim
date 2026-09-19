---@alias dove.PathResolver fun(): string?

---@alias dove.Executor fun(command: string, args: string[]?)

---@class dove.Executors
---@field [string] dove.Executor

---@class dove.Target
---@field source_path dove.PathResolver|dove.PathResolver[]
---@field auto_run_single_command boolean
---@field default_executor dove.Executor

---@class dove.Targets
---@field [string] dove.Target

---@class dove.SourceEnvironment
---@field executors dove.Executors

---@class dove.Environment
---@field denv dove.SourceEnvironment
---@field [string] any

---@alias dove.Picker fun(items: any[], opts: table, on_choice: fun(item: any?, index: integer?))

---@class dove.Ui
---@field picker dove.Picker
---@field format_selection_item fun(name: string, i: integer): string

---@class dove.Config
---@field default_run_target string?
---@field targets dove.Targets
---@field environment dove.Environment
---@field cmd_list_delimiter fun(): string
---@field write_template_to_new_source_file boolean
---@field ui dove.Ui

---@class dove.MinimumTarget
---@field source_path dove.PathResolver|dove.PathResolver[]

---@class dove.RawEntry
---@field [1] string?
---@field cmd string|string[]?
---@field name string?
---@field executor dove.Executor?

---@class dove.ProcessedEntry
---@field name string
---@field command string
---@field executor dove.Executor?

---@class dove.ProcessedTarget
---@field name string
---@field source_path string
---@field auto_run_single_command boolean
---@field default_executor dove.Executor

---@class dove.Task
---@field command string
---@field executor dove.Executor
---@field args string[]

---@class dove.Subcommand
---@field func fun(target_name: string?)
---@field takes_target boolean
---@field target_optional? boolean

---@class dove.PickerEntry
---@field index integer
---@field item any
---@field label string
---@field score? integer

---@class dove.PickerOptions
---@field prompt? string
---@field format_item? fun(item: any): string

---@class dove.PickerState
---@field filtered dove.PickerEntry[]
---@field finished boolean
---@field query string
---@field render_tick integer?
---@field selected integer
---@field updating boolean
