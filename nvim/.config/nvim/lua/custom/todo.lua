local M = {}

local data_file = vim.fn.stdpath "data" .. "/todo.json"
local ns = vim.api.nvim_create_namespace "custom_todo"

local groups = { "list", "day", "week", "month" }
local group_fmt = { day = "%Y-%m-%d (%a)", week = "%Y-W%V", month = "%B %Y" }

local state = {
  todos = nil,
  list = { buf = -1, win = -1 },
  desc = { buf = -1, win = -1 },
  desc_id = nil,
  group = "list",
  sort = "desc",
  line_map = {},
}

-- storage -------------------------------------------------------------------

local function load()
  if state.todos then
    return state.todos
  end
  state.todos = {}
  local f = io.open(data_file, "r")
  if f then
    local content = f:read "*a"
    f:close()
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      state.todos = decoded
    end
  end
  return state.todos
end

local function save()
  local f = io.open(data_file, "w")
  if not f then
    vim.notify("todo: unable to write " .. data_file, vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(state.todos))
  f:close()
end

local function find(id)
  for i, t in ipairs(load()) do
    if t.id == id then
      return t, i
    end
  end
end

local function next_id()
  local max = 0
  for _, t in ipairs(load()) do
    max = math.max(max, t.id)
  end
  return max + 1
end

-- rendering -----------------------------------------------------------------

local function setup_highlights()
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  vim.api.nvim_set_hl(0, "TodoDone", { fg = comment.fg, strikethrough = true, default = true })
  vim.api.nvim_set_hl(0, "TodoCheckDone", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "TodoCheckOpen", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "TodoHeader", { link = "Title", default = true })
end

local function valid_win(w)
  return w and vim.api.nvim_win_is_valid(w)
end

local function current_id()
  if not valid_win(state.list.win) then
    return nil
  end
  local line = vim.api.nvim_win_get_cursor(state.list.win)[1]
  return state.line_map[line]
end

local function footer()
  return string.format(" group: %s │ sort: %s │ a add  e edit  x del  <CR> done  g group  s sort  / search  <Tab> desc ", state.group, state.sort)
end

local function render_desc()
  if not vim.api.nvim_buf_is_valid(state.desc.buf) then
    return
  end
  local id = current_id()
  local todo = id and find(id)
  state.desc_id = id
  local lines = todo and vim.split(todo.description or "", "\n") or { "" }
  vim.api.nvim_buf_set_lines(state.desc.buf, 0, -1, false, lines)
  vim.bo[state.desc.buf].modified = false
  if valid_win(state.desc.win) then
    local title = todo and string.format(" %s · %s ", todo.text, os.date("%Y-%m-%d %H:%M", todo.created)) or " Description "
    vim.api.nvim_win_set_config(state.desc.win, { title = title, title_pos = "center" })
  end
end

local function render()
  local buf = state.list.buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local todos = vim.deepcopy(load())
  table.sort(todos, function(a, b)
    if a.created == b.created then
      return a.id < b.id
    end
    if state.sort == "asc" then
      return a.created < b.created
    end
    return a.created > b.created
  end)

  local lines, map, marks = {}, {}, {}
  local last_header
  for _, t in ipairs(todos) do
    if state.group ~= "list" then
      local header = os.date(group_fmt[state.group], t.created)
      if header ~= last_header then
        if last_header then
          table.insert(lines, "")
        end
        table.insert(lines, " " .. header)
        table.insert(marks, { line = #lines, header = true })
        last_header = header
      end
    end
    table.insert(lines, "  " .. t.text)
    map[#lines] = t.id
    table.insert(marks, { line = #lines, todo = t })
  end
  if #lines == 0 then
    lines = { "  No todos — press a to add one" }
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  state.line_map = map

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    local row = m.line - 1
    if m.header then
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { end_col = #lines[m.line], hl_group = "TodoHeader" })
    else
      local done = m.todo.done
      if done then
        vim.api.nvim_buf_set_extmark(buf, ns, row, 2, { end_col = #lines[m.line], hl_group = "TodoDone" })
      end
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        virt_text = { { done and "☑ " or "☐ ", done and "TodoCheckDone" or "TodoCheckOpen" } },
        virt_text_pos = "right_align",
      })
    end
  end

  if valid_win(state.list.win) then
    vim.api.nvim_win_set_config(state.list.win, { footer = footer(), footer_pos = "center" })
  end
  render_desc()
end

local function jump_to(id)
  for line, tid in pairs(state.line_map) do
    if tid == id then
      vim.api.nvim_win_set_cursor(state.list.win, { line, 0 })
      render_desc()
      return
    end
  end
end

-- actions -------------------------------------------------------------------

local function save_desc()
  if not state.desc_id or not vim.api.nvim_buf_is_valid(state.desc.buf) then
    return
  end
  local todo = find(state.desc_id)
  if not todo then
    return
  end
  local text = table.concat(vim.api.nvim_buf_get_lines(state.desc.buf, 0, -1, false), "\n")
  if text ~= (todo.description or "") then
    todo.description = text
    save()
  end
end

local function toggle_done()
  local todo = find(current_id() or -1)
  if not todo then
    return
  end
  todo.done = not todo.done
  todo.done_at = todo.done and os.time() or nil
  save()
  render()
end

local function add()
  vim.ui.input({ prompt = "Todo: " }, function(text)
    if not text or vim.trim(text) == "" then
      return
    end
    vim.ui.input({ prompt = "Description (optional): " }, function(desc)
      local todo = { id = next_id(), text = vim.trim(text), description = desc or "", created = os.time(), done = false }
      table.insert(load(), todo)
      save()
      render()
      jump_to(todo.id)
    end)
  end)
end

local function edit()
  local todo = find(current_id() or -1)
  if not todo then
    return
  end
  vim.ui.input({ prompt = "Edit todo: ", default = todo.text }, function(text)
    if not text or vim.trim(text) == "" then
      return
    end
    todo.text = vim.trim(text)
    save()
    render()
    jump_to(todo.id)
  end)
end

local function delete()
  local id = current_id()
  local todo, idx = find(id or -1)
  if not todo then
    return
  end
  if vim.fn.confirm("Delete '" .. todo.text .. "'?", "&Yes\n&No", 2) == 1 then
    table.remove(state.todos, idx)
    save()
    render()
  end
end

local function cycle_group()
  for i, g in ipairs(groups) do
    if g == state.group then
      state.group = groups[i % #groups + 1]
      break
    end
  end
  local id = current_id()
  render()
  if id then
    jump_to(id)
  end
end

local function toggle_sort()
  state.sort = state.sort == "desc" and "asc" or "desc"
  local id = current_id()
  render()
  if id then
    jump_to(id)
  end
end

local function focus_desc()
  if current_id() and valid_win(state.desc.win) then
    vim.api.nvim_set_current_win(state.desc.win)
  end
end

local function focus_list()
  if valid_win(state.list.win) then
    vim.api.nvim_set_current_win(state.list.win)
  end
end

-- window management ---------------------------------------------------------

local function close()
  save_desc()
  for _, w in ipairs { state.desc.win, state.list.win } do
    if valid_win(w) then
      vim.api.nvim_win_close(w, true)
    end
  end
end

local search

local function open()
  load()
  setup_highlights()

  local total_w = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local list_w = math.floor(total_w * 0.4)
  local desc_w = total_w - list_w - 2
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - total_w) / 2)

  state.list.buf = vim.api.nvim_create_buf(false, true)
  state.desc.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.list.buf].filetype = "todo"
  vim.bo[state.desc.buf].filetype = "markdown"
  vim.bo[state.desc.buf].bufhidden = "wipe"
  vim.bo[state.list.buf].bufhidden = "wipe"

  state.desc.win = vim.api.nvim_open_win(state.desc.buf, false, {
    relative = "editor",
    width = desc_w,
    height = height,
    row = row,
    col = col + list_w + 2,
    style = "minimal",
    border = "rounded",
    title = " Description ",
    title_pos = "center",
  })
  vim.wo[state.desc.win].wrap = true

  state.list.win = vim.api.nvim_open_win(state.list.buf, true, {
    relative = "editor",
    width = list_w,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Todos ",
    title_pos = "center",
    footer = footer(),
    footer_pos = "center",
  })
  vim.wo[state.list.win].cursorline = true

  local function lmap(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = state.list.buf, nowait = true, silent = true })
  end
  lmap("<CR>", toggle_done)
  lmap("a", add)
  lmap("e", edit)
  lmap("x", delete)
  lmap("dd", delete)
  lmap("g", cycle_group)
  lmap("s", toggle_sort)
  lmap("/", function()
    search()
  end)
  lmap("D", focus_desc)
  lmap("<Tab>", focus_desc)
  lmap("q", close)
  lmap("<Esc>", close)

  local function dmap(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = state.desc.buf, nowait = true, silent = true })
  end
  dmap("q", focus_list)
  dmap("<Tab>", focus_list)

  local group = vim.api.nvim_create_augroup("CustomTodo", { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", { group = group, buffer = state.list.buf, callback = render_desc })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave", "BufLeave" }, { group = group, buffer = state.desc.buf, callback = save_desc })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = { tostring(state.list.win), tostring(state.desc.win) },
    callback = function()
      vim.schedule(close)
    end,
  })

  render()
end

function M.toggle()
  if valid_win(state.list.win) then
    close()
  else
    open()
  end
end

-- search --------------------------------------------------------------------

search = function()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.ui.input({ prompt = "Search todos: " }, function(q)
      if not q or q == "" then
        return
      end
      for line, id in pairs(state.line_map) do
        local t = find(id)
        if t and (t.text .. " " .. (t.description or "")):lower():find(q:lower(), 1, true) then
          vim.api.nvim_win_set_cursor(state.list.win, { line, 0 })
          render_desc()
          return
        end
      end
      vim.notify("todo: no match for '" .. q .. "'", vim.log.levels.INFO)
    end)
    return
  end

  local items = {}
  for _, t in ipairs(load()) do
    table.insert(items, {
      text = t.text .. " " .. (t.description or "") .. " " .. os.date("%Y-%m-%d", t.created),
      todo = t,
      preview = { text = t.description ~= "" and t.description or "(no description)", ft = "markdown" },
    })
  end
  table.sort(items, function(a, b)
    return a.todo.created > b.todo.created
  end)

  close()
  snacks.picker.pick {
    title = "Todos",
    items = items,
    preview = "preview",
    format = function(item)
      local t = item.todo
      return {
        { t.done and "☑ " or "☐ ", t.done and "TodoCheckDone" or "TodoCheckOpen" },
        { os.date("%Y-%m-%d", t.created) .. "  ", "Comment" },
        { t.text, t.done and "TodoDone" or nil },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          open()
          jump_to(item.todo.id)
        end)
      end
    end,
  }
end

function M.setup()
  vim.keymap.set("n", "<leader>td", M.toggle, { desc = "[T]o[d]o list" })
  vim.api.nvim_create_user_command("Todo", M.toggle, {})
end

return M
