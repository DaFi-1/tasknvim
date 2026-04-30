-- lua/tasknvim.lua
local M = {}

-- Atualiza contagem de tarefas por título
local function update_task_counts()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local new_lines = {}
  local current_title = nil
  local title_line = nil
  local counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0, cancelled = 0, delegated = 0 }

  for i, line in ipairs(lines) do
    --local title = line:match("^%s*%-%s*(.+)")
    local title = line:match("^%-%s*(.+)")
    if title then
      if current_title and title_line then
        local total = counts.done + counts.progress + counts.pending + counts.priority + counts.priority_max + counts.cancelled + counts.delegated
        new_lines[title_line] = string.gsub(new_lines[title_line], "%s*%[.*%]$", "")
        new_lines[title_line] = new_lines[title_line] ..
                                string.format("[%d/%d/%d/%d/%d/%d/%d/%d]",
                                  counts.done, counts.progress, counts.pending,
                                  counts.priority, counts.priority_max, counts.cancelled, counts.delegated, total)
      end
      current_title = title
      title_line = i
      counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0, cancelled = 0, delegated = 0 }
    else
      counts.done         = counts.done         + select(2, line:gsub("%[[xX]%]", ""))
      counts.progress     = counts.progress     + select(2, line:gsub("%[%+%]",   ""))
      counts.pending      = counts.pending      + select(2, line:gsub("%[%s%]",   ""))
      counts.priority     = counts.priority     + select(2, line:gsub("%[%!%]",   ""))
      counts.priority_max = counts.priority_max + select(2, line:gsub("%[%>]",    ""))
      counts.cancelled    = counts.cancelled    + select(2, line:gsub("%[%-%]",   ""))
      counts.delegated    = counts.delegated    + select(2, line:gsub("%[%@%]",   ""))
    end
    new_lines[i] = line
  end

  if current_title and title_line then
    local total = counts.done + counts.progress + counts.pending + counts.priority + counts.priority_max + counts.cancelled + counts.delegated
    new_lines[title_line] = string.gsub(new_lines[title_line], "%s*%[.*%]$", "")
    new_lines[title_line] = new_lines[title_line] ..
                            string.format("[%d/%d/%d/%d/%d/%d/%d/%d]",
                              counts.done, counts.progress, counts.pending,
                              counts.priority, counts.priority_max, counts.cancelled, counts.delegated, total)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)

  -- Aplica highlights coloridos ao contador
  vim.api.nvim_buf_clear_namespace(buf, 0, 0, -1)
  for i, line in ipairs(new_lines) do
    local start_pos = line:find("%[")
    if start_pos then
      local nums = {}
      for n in line:sub(start_pos+1):gmatch("(%d+)") do
        table.insert(nums, n)
      end
      if #nums == 8 then
        local offsets = {}
        local p = start_pos
        for _, n in ipairs(nums) do
          local s, e = line:find(n, p, true)
          table.insert(offsets, {s-1, e})
          p = e + 1
        end
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoGreen",   i-1, offsets[1][1], offsets[1][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoBlue",    i-1, offsets[2][1], offsets[2][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoRed",     i-1, offsets[3][1], offsets[3][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoMagenta", i-1, offsets[4][1], offsets[4][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoOrange",  i-1, offsets[5][1], offsets[5][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoDarkGreen", i-1, offsets[6][1], offsets[6][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoCyan",    i-1, offsets[7][1], offsets[7][2])
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoYellow",  i-1, offsets[8][1], offsets[8][2])
      end
    end
  end
end

-- Setup do plugin
function M.setup()
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "TASKNVIM",
    callback = function() vim.bo.filetype = "task" end,
  })

  vim.cmd("highlight TodoGreen     guifg=#00FF00")
  vim.cmd("highlight TodoRed       guifg=#FF0000")
  vim.cmd("highlight TodoBlue      guifg=#0000FF")
  vim.cmd("highlight TodoYellow    guifg=#FFFF00")
  vim.cmd("highlight TodoMagenta   guifg=#FF00FF")
  vim.cmd("highlight TodoOrange    guifg=#FFA500")
  vim.cmd("highlight TodoDarkGreen guifg=#008000")
  vim.cmd("highlight TodoCyan      guifg=#00FFFF")

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "TASKNVIM",
    callback = function()
      vim.cmd("syntax clear")
      vim.cmd([[syntax match TaskMainTitle     /^-.*/]])
      vim.cmd([[syntax match TaskSubTitle      /--.*/]])

      vim.cmd("syntax  match TaskUnchecked   /\\[ \\]/")
      vim.cmd("syntax  match TaskChecked     /\\[x\\]/")
      vim.cmd("syntax  match TaskInProgress  /\\[+\\]/")
      vim.cmd("syntax  match TaskPriority    /\\[!\\]/")
      vim.cmd("syntax  match TaskPriorityMax /\\[>\\]/")
      vim.cmd("syntax  match TaskCancelled   /\\[-\\]/")
      vim.cmd("syntax  match TaskDelegated   /\\[@\\]/")
      vim.cmd("highlight TaskUnchecked   guifg=#000000 guibg=#FF0000")
      vim.cmd("highlight TaskChecked     guifg=#000000 guibg=#00FF00")
      vim.cmd("highlight TaskInProgress  guifg=#000000 guibg=#0000FF")
      vim.cmd("highlight TaskPriorityMax guifg=#000000 guibg=#FFA500")
      vim.cmd("highlight TaskPriority    guifg=#000000 guibg=#FF00FF")
      vim.cmd("highlight TaskCancelled   guifg=#000000 guibg=#008000")
      vim.cmd("highlight TaskDelegated   guifg=#000000 guibg=#00FFFF")

      vim.cmd("highlight TaskSubTitle  guifg=#000000 guibg=#808080 ctermfg=black")
      vim.cmd("highlight TaskMainTitle guifg=#000000 guibg=#808080 ctermfg=black")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufRead", "BufWritePost" }, {
    pattern = "TASKNVIM",
    callback = update_task_counts,
  })
end

return M
