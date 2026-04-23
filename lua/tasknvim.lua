-- lua/tasknvim.lua
local M = {}

-- Atualiza contagem de tarefas por título
local function update_task_counts()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local new_lines = {}
  local current_title = nil
  local title_line = nil
  local counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0 }

  for i, line in ipairs(lines) do
    --local title = line:match("^%s*%-%s*(.+)")
    local title = line:match("^%-%s*(.+)")
    if title then
      if current_title and title_line then
        local total = counts.done + counts.progress + counts.pending + counts.priority + counts.priority_max
        new_lines[title_line] = string.gsub(new_lines[title_line], "%s*%[.*%]$", "")
        new_lines[title_line] = new_lines[title_line] ..
                                string.format("[%d/%d/%d/%d/%d/%d]",
                                  counts.done, counts.progress, counts.pending,
                                  counts.priority, counts.priority_max, total)
      end
      current_title = title
      title_line = i
      counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0 }
    else
      counts.done         = counts.done         + select(2, line:gsub("%[[xX]%]", ""))
      counts.progress     = counts.progress     + select(2, line:gsub("%[%+%]",   ""))
      counts.pending      = counts.pending      + select(2, line:gsub("%[%s%]",   ""))
      counts.priority     = counts.priority     + select(2, line:gsub("%[%!%]",   ""))
      counts.priority_max = counts.priority_max + select(2, line:gsub("%[%>]",    ""))
    end
    new_lines[i] = line
  end

  if current_title and title_line then
    local total = counts.done + counts.progress + counts.pending + counts.priority + counts.priority_max
    new_lines[title_line] = string.gsub(new_lines[title_line], "%s*%[.*%]$", "")
    new_lines[title_line] = new_lines[title_line] ..
                            string.format("[%d/%d/%d/%d/%d/%d]",
                              counts.done, counts.progress, counts.pending,
                              counts.priority, counts.priority_max, total)
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
      if #nums == 6 then
        local offsets = {}
        local p = start_pos
        for _, n in ipairs(nums) do
          local s, e = line:find(n, p, true)
          table.insert(offsets, {s-1, e})
          p = e + 1
        end
        -- Aplicar cores
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoGreen",   i-1, offsets[1][1], offsets[1][2]) -- x
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoBlue",    i-1, offsets[2][1], offsets[2][2]) -- +
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoRed",     i-1, offsets[3][1], offsets[3][2]) -- [ ]
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoMagenta", i-1, offsets[4][1], offsets[4][2]) -- [!]
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoOrange",  i-1, offsets[5][1], offsets[5][2]) -- [>]
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoYellow",  i-1, offsets[6][1], offsets[6][2]) -- total
      end
    end
  end
end

-- Setup do plugin
function M.setup(opts)
  opts = opts or {}

  -- cores padrão
  local colors = {
    green    = "#00FF00",
    red      = "#FF0000",
    blue     = "#0000FF",
    yellow   = "#FFFF00",
    magenta  = "#FF00FF",
    orange   = "#FFA500",
    title_fg = "#000000",
    title_bg = "#808080",
  }

  -- override opcional
  for k, v in pairs(opts) do
    colors[k] = v
  end

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "TASKNVIM",
    callback = function() vim.bo.filetype = "task" end,
  })

  -- Highlights básicos
  vim.cmd("highlight TodoGreen   guifg=" .. colors.green  )
  vim.cmd("highlight TodoRed     guifg=" .. colors.red    )
  vim.cmd("highlight TodoBlue    guifg=" .. colors.blue   )
  vim.cmd("highlight TodoYellow  guifg=" .. colors.yellow )
  vim.cmd("highlight TodoMagenta guifg=" .. colors.magenta)
  vim.cmd("highlight TodoOrange  guifg=" .. colors.orange )

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
      vim.cmd("highlight TaskUnchecked   guifg=#000000 guibg=" .. colors.red    )
      vim.cmd("highlight TaskChecked     guifg=#000000 guibg=" .. colors.green  )
      vim.cmd("highlight TaskInProgress  guifg=#000000 guibg=" .. colors.blue   )
      vim.cmd("highlight TaskPriorityMax guifg=#000000 guibg=" .. colors.orange )
      vim.cmd("highlight TaskPriority    guifg=#000000 guibg=" .. colors.magenta)

      vim.cmd(string.format("highlight TaskSubTitle guifg=%s guibg=%s ctermfg=black",  colors.title_fg, colors.title_bg))
      vim.cmd(string.format("highlight TaskMainTitle guifg=%s guibg=%s ctermfg=black", colors.title_fg, colors.title_bg))
    end,
  })

  vim.api.nvim_create_autocmd({ "BufRead", "BufWritePost" }, {
    pattern = "TASKNVIM",
    callback = update_task_counts,
  })
end

return M
