-- lua/tasknvim.lua
local M = {}

M.config = {
  center = true, -- Centraliza as tabelas do Kanban e Dashboard horizontalmente no centro da tela
}

-- Histórico em memória de tarefas marcadas como concluídas nesta sessão (para priorizar no DONE)
local recent_done_tasks = {}

-- Tabelas de lookup O(1) para prioridade e contagem direta de tags
local PRIORITY_WEIGHT = {
  [">"] = 1, -- [>] Prioridade Máxima
  ["!"] = 2, -- [!] Prioridade
  ["#"] = 3, -- [#] Bug
  ["*"] = 4, -- [*] Quebrado
  ["/"] = 5, -- [/] Refatoração
  ["?"] = 6, -- [?] Dúvida
  ["@"] = 7, -- [@] Delegado
  [" "] = 8, -- [ ] Pendente
}

local TAG_TO_COUNT_KEY = {
  ["x"] = "done",
  ["+"] = "progress",
  [" "] = "pending",
  ["!"] = "priority",
  [">"] = "priority_max",
  ["@"] = "delegated",
  ["?"] = "doubt",
  ["#"] = "bug",
  ["/"] = "refactor",
  ["*"] = "broken",
}

-- Aplica os grupos de highlight para os contadores, tags e dashboard
local function setup_highlights()
  -- Contadores
  vim.cmd("highlight TodoGreen     guifg=#00FF00")
  vim.cmd("highlight TodoRed       guifg=#FF0000")
  vim.cmd("highlight TodoBlue      guifg=#0000FF")
  vim.cmd("highlight TodoYellow    guifg=#FFFF00")
  vim.cmd("highlight TodoMagenta   guifg=#FF00FF")
  vim.cmd("highlight TodoOrange    guifg=#FFA500")
  vim.cmd("highlight TodoCyan      guifg=#00FFFF")
  vim.cmd("highlight TodoBug       guifg=#FF4444")
  vim.cmd("highlight TodoRefactor  guifg=#E040FB")
  vim.cmd("highlight TodoBroken    guifg=#8B0000")
  vim.cmd("highlight TodoTotal     guifg=#FFFFFF")

  -- Tags de tarefas (com cores consistentes)
  vim.cmd("highlight TaskUnchecked   guifg=#000000 guibg=#FF0000")
  vim.cmd("highlight TaskChecked     guifg=#000000 guibg=#00FF00")
  vim.cmd("highlight TaskInProgress  guifg=#000000 guibg=#0000FF")
  vim.cmd("highlight TaskPriorityMax guifg=#000000 guibg=#FFA500")
  vim.cmd("highlight TaskPriority    guifg=#000000 guibg=#FF00FF")
  vim.cmd("highlight TaskDelegated   guifg=#000000 guibg=#00FFFF")
  vim.cmd("highlight TaskDoubt       guifg=#000000 guibg=#FFFF00")
  vim.cmd("highlight TaskBug         guifg=#000000 guibg=#FF4444")
  vim.cmd("highlight TaskRefactor    guifg=#000000 guibg=#E040FB")
  vim.cmd("highlight TaskBroken      guifg=#000000 guibg=#8B0000")

  -- Títulos (fundo cinza escuro #444444 com texto cinza claro #cccccc)
  vim.cmd("highlight TaskSubTitle  guifg=#cccccc guibg=#444444 ctermfg=252 ctermbg=238")
  vim.cmd("highlight TaskMainTitle guifg=#cccccc guibg=#444444 ctermfg=252 ctermbg=238")

  -- Dashboard Geral
  vim.cmd("highlight TaskDashBorder   guifg=#555555")
  vim.cmd("highlight TaskDashTitle    guifg=#FFFFFF gui=bold")
  vim.cmd("highlight TaskDashTotal    guifg=#FFFFFF gui=bold")
  vim.cmd("highlight TaskDashBullet   guifg=#00FFFF")
  vim.cmd("highlight TaskDashDone     guifg=#00FF00 gui=bold")
  vim.cmd("highlight TaskDashProgress guifg=#FFA500")
  vim.cmd("highlight TaskDashPending  guifg=#888888")
  vim.cmd("highlight TaskDashBug      guifg=#FF4444 gui=bold")

  -- Mini-Quadro Kanban
  vim.cmd("highlight TaskKanbanBorder     guifg=#555555")
  vim.cmd("highlight TaskKanbanHeaderTodo guifg=#FFA500 gui=bold")
  vim.cmd("highlight TaskKanbanHeaderProg guifg=#61AFEF gui=bold")
  vim.cmd("highlight TaskKanbanHeaderDone guifg=#98C379 gui=bold")
  vim.cmd("highlight TaskKanbanEmpty      guifg=#666666 gui=italic")
end

-- Gera a barra de progresso visual de 10 blocos e a porcentagem
local function format_progress_bar(done, total)
  if total == 0 then
    return string.rep("░", 10), 0.0
  end
  local percent = (done / total) * 100
  local filled = math.floor((percent / 100) * 10)
  if filled > 10 then filled = 10 end
  local empty = 10 - filled
  return string.rep("█", filled) .. string.rep("░", empty), percent
end

-- Trunca ou preenche uma string para ter exatamente `target_width` de exibição no terminal (complexidade O(L))
local function pad_or_truncate(str, target_width)
  local dw = vim.fn.strdisplaywidth(str)
  if dw == target_width then
    return str
  elseif dw < target_width then
    return str .. string.rep(" ", target_width - dw)
  else
    local parts = {}
    local cur_w = 0
    for char in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
      local cw = (char:byte(1) < 128 and 1) or vim.fn.strdisplaywidth(char)
      if cur_w + cw + 1 > target_width then
        break
      end
      cur_w = cur_w + cw
      table.insert(parts, char)
    end
    local res = table.concat(parts)
    local ellipsis_w = vim.fn.strdisplaywidth(res .. "…")
    local pad_w = math.max(0, target_width - ellipsis_w)
    return res .. "…" .. string.rep(" ", pad_w)
  end
end

-- Gera as linhas do mini-quadro Kanban
local function build_kanban_lines(kanban_data, col_w)
  if not kanban_data then return {} end

  local t1 = "─ PRIORITY "
  local t2 = "─ IN PROGRESS "
  local t3 = "─ DONE "

  local d1 = col_w - vim.fn.strdisplaywidth(t1)
  if d1 < 0 then d1 = 0 end
  local d2 = col_w - vim.fn.strdisplaywidth(t2)
  if d2 < 0 then d2 = 0 end
  local d3 = col_w - vim.fn.strdisplaywidth(t3)
  if d3 < 0 then d3 = 0 end

  local top_border = "┌" .. t1 .. string.rep("─", d1)
                  .. "┬" .. t2 .. string.rep("─", d2)
                  .. "┬" .. t3 .. string.rep("─", d3)
                  .. "┐"

  local num_rows = math.max(#kanban_data.col1, #kanban_data.col2, #kanban_data.col3)
  if num_rows > 10 then num_rows = 10 end
  if num_rows < 3 then num_rows = 3 end

  local rows = {}
  for row = 1, num_rows do
    local item1 = kanban_data.col1[row]
    local item2 = kanban_data.col2[row]
    local item3 = kanban_data.col3[row]

    local s1 = item1 and string.format(" • %s %s", item1.tag, item1.text) or (row == 1 and " • (Nenhuma pendência)" or "")
    local s2 = item2 and string.format(" • %s %s", item2.tag, item2.text) or (row == 1 and " • (Nenhuma em andamento)" or "")
    local s3 = item3 and string.format(" • %s %s", item3.tag, item3.text) or (row == 1 and " • (Nenhuma concluída)" or "")

    local row_str = "│" .. pad_or_truncate(s1, col_w)
                 .. "│" .. pad_or_truncate(s2, col_w)
                 .. "│" .. pad_or_truncate(s3, col_w)
                 .. "│"
    table.insert(rows, row_str)
  end

  local bot_border = "└" .. string.rep("─", col_w)
                  .. "┴" .. string.rep("─", col_w)
                  .. "┴" .. string.rep("─", col_w)
                  .. "┘"

  local klines = { top_border }
  for _, r in ipairs(rows) do
    table.insert(klines, r)
  end
  table.insert(klines, bot_border)
  return klines
end

-- Constrói o dashboard Roadmap de Módulos com Mini-Quadro Kanban
local function build_dashboard(topics, kanban_data)
  local global_counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0, delegated = 0, doubt = 0, bug = 0, refactor = 0, broken = 0 }
  local global_done = 0
  local global_total = 0

  for _, t in ipairs(topics) do
    for k, v in pairs(t.counts) do
      global_counts[k] = (global_counts[k] or 0) + v
    end
    global_done = global_done + t.counts.done
    global_total = global_total + t.total
  end

  local global_bar, global_percent = format_progress_bar(global_done, global_total)

  local max_title_len = 0
  for _, t in ipairs(topics) do
    if #t.name > max_title_len then
      max_title_len = #t.name
    end
  end
  if max_title_len < 30 then max_title_len = 30 end

  local topic_lines = {}

  for _, t in ipairs(topics) do
    local counter_str = string.format("%3d %3d %3d %3d %3d %3d %3d %3d %3d %3d %3d",
      t.counts.done, t.counts.progress, t.counts.pending,
      t.counts.priority, t.counts.priority_max, t.counts.delegated,
      t.counts.doubt, t.counts.bug, t.counts.refactor, t.counts.broken, t.total)

    local padding = string.rep(" ", max_title_len - #t.name)
    local line_str = string.format("• %s%s   [%s] %6.2f%%   %s",
      t.name, padding, t.bar, t.percent, counter_str)
    table.insert(topic_lines, line_str)
  end

  -- Linha de TOTAL no rodapé, formatada no mesmo padrão das outras
  local global_counter_str = string.format("%3d %3d %3d %3d %3d %3d %3d %3d %3d %3d %3d",
    global_counts.done, global_counts.progress, global_counts.pending,
    global_counts.priority, global_counts.priority_max, global_counts.delegated,
    global_counts.doubt, global_counts.bug, global_counts.refactor, global_counts.broken, global_total)

  local total_padding = string.rep(" ", max_title_len - 5)
  local total_line = string.format("• TOTAL%s   [%s] %6.2f%%   %s",
    total_padding, global_bar, global_percent, global_counter_str)
  table.insert(topic_lines, total_line)

  -- Calcula a largura máxima considerando as bordas laterais "│ " e " │" (+4)
  local max_inner_len = 0
  for _, tl in ipairs(topic_lines) do
    local dlen = vim.fn.strdisplaywidth(tl)
    if dlen > max_inner_len then max_inner_len = dlen end
  end

  local max_line_len = max_inner_len + 4
  if max_line_len < 100 then max_line_len = 100 end

  -- Largura de cada uma das 3 colunas do Kanban (alinhando com a largura total)
  local col_w = math.ceil((max_line_len - 4) / 3)
  if col_w < 32 then col_w = 32 end
  max_line_len = col_w * 3 + 4

  local kanban_lines = build_kanban_lines(kanban_data, col_w)

  -- Envolve cada linha do roadmap de tópicos dentro das paredes da caixa: "│ " .. ... .. " │"
  local inner_width = max_line_len - 4
  local framed_topic_lines = {}
  for _, tl in ipairs(topic_lines) do
    local row_str = "│ " .. pad_or_truncate(tl, inner_width) .. " │"
    table.insert(framed_topic_lines, row_str)
  end

  local header_text = " DASHBOARD "
  local h_dw = vim.fn.strdisplaywidth(header_text)
  local half_border = math.floor((max_line_len - 2 - h_dw) / 2)
  if half_border < 3 then half_border = 3 end
  local top_border = "┌" .. string.rep("─", half_border) .. header_text .. string.rep("─", max_line_len - 2 - half_border - h_dw) .. "┐"
  local bottom_border = "└" .. string.rep("─", max_line_len - 2) .. "┘"

  local dash_lines = {}
  for _, kl in ipairs(kanban_lines) do
    table.insert(dash_lines, kl)
  end
  table.insert(dash_lines, "")
  table.insert(dash_lines, top_border)
  for _, ftl in ipairs(framed_topic_lines) do
    table.insert(dash_lines, ftl)
  end
  table.insert(dash_lines, bottom_border)
  return dash_lines
end

-- Atualiza contagem de tarefas por título e gera o dashboard geral
local function update_task_counts(target_buf)
  local buf = (type(target_buf) == "number" and target_buf)
    or (type(target_buf) == "table" and type(target_buf.buf) == "number" and target_buf.buf)
    or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Pula o bloco de dashboard existente para não reprocessá-lo como tarefas
  local content_lines = {}
  local in_dashboard = false
  local passed_dashboard = false

  for _, line in ipairs(lines) do
    if not passed_dashboard then
      if not in_dashboard then
        if line:match("^%s*====.*====") or line:match("^%s*┌.*DASHBOARD") or line:match("^%s*┌─.*PRIORITY") or line:match("^%s*┌─.*A FAZER") then
          in_dashboard = true
        elseif not line:match("^%s*$") then
          table.insert(content_lines, line)
        end
      else
        if line:match("^%s*====+$") or (line:match("^%s*└.*┘$") and not line:match("┴")) then
          in_dashboard = false
          passed_dashboard = true
        end
      end
    else
      table.insert(content_lines, line)
    end
  end

  local task_lines = {}
  local topics = {}
  local current_title = nil
  local title_line = nil
  local counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0, delegated = 0, doubt = 0, bug = 0, refactor = 0, broken = 0 }
  local todo_tasks = {}
  local in_progress_tasks = {}
  local done_tasks = {}
  local task_order = 0

  local function finalize_section()
    if current_title and title_line then
      local total = counts.done + counts.progress + counts.pending + counts.priority + counts.priority_max + counts.delegated + counts.doubt + counts.bug + counts.refactor + counts.broken
      local bar, percent = format_progress_bar(counts.done, total)
      local clean_title = string.gsub(task_lines[title_line], "%s*%-?%[.*$", "")
      local raw_name = clean_title:gsub("^%-%s*", "")
      local upper_name = string.upper(raw_name)
      task_lines[title_line] = "- " .. upper_name

      table.insert(topics, {
        name = upper_name,
        counts = counts,
        total = total,
        bar = bar,
        percent = percent,
      })
    end
  end

  for _, line in ipairs(content_lines) do
    local title = line:match("^%-%s*([^%-].*)")
    if title then
      if current_title and title_line then
        finalize_section()
        -- Garante exatamente duas linhas em branco entre o tópico anterior e o novo
        while #task_lines > title_line and task_lines[#task_lines]:match("^%s*$") do
          table.remove(task_lines)
        end
        table.insert(task_lines, "")
        table.insert(task_lines, "")
      else
        -- Remove linhas vazias em excesso no topo do arquivo antes do primeiro tópico
        while #task_lines > 0 and task_lines[#task_lines]:match("^%s*$") do
          table.remove(task_lines)
        end
      end

      table.insert(task_lines, line)
      current_title = title
      title_line = #task_lines
      counts = { done = 0, progress = 0, pending = 0, priority = 0, priority_max = 0, delegated = 0, doubt = 0, bug = 0, refactor = 0, broken = 0 }
    else
      -- Padroniza a indentação de 4 espaços e força a primeira letra da tarefa a ser maiúscula
      if line:match("^%s*%[[%s%+%-%*xX%!%>@%?#%/]%]") then
        local tag, sep, content = line:match("^%s*(%[[%s%+%-%*xX%!%>@%?#%/]%])(%s*%-?%s*)(.*)$")
        if tag and sep and content and #content > 0 then
          local first_char = content:sub(1, 1)
          local remainder = content:sub(2)
          local clean_content = string.upper(first_char) .. remainder
          line = "    " .. tag .. sep .. clean_content

          local tag_char = tag:sub(2, 2):lower()
          local count_key = TAG_TO_COUNT_KEY[tag_char]
          if count_key then
            counts[count_key] = counts[count_key] + 1
          end

          task_order = task_order + 1
          local weight = PRIORITY_WEIGHT[tag_char] or 99
          if tag_char == "+" then
            table.insert(in_progress_tasks, { tag = tag, text = clean_content, order = task_order, weight = weight })
          elseif tag_char == "x" then
            table.insert(done_tasks, { tag = tag, text = clean_content, order = task_order, weight = weight })
          else
            -- Todas as outras tarefas pertencem à fila de "A FAZER"
            table.insert(todo_tasks, { tag = tag, text = clean_content, order = task_order, weight = weight })
          end
        else
          line = "    " .. line:gsub("^%s*", "")
          local tag_char = line:match("^%s*%[(.)%]")
          if tag_char then
            local count_key = TAG_TO_COUNT_KEY[tag_char:lower()]
            if count_key then
              counts[count_key] = counts[count_key] + 1
            end
          end
        end
      end

      table.insert(task_lines, line)
    end
  end

  finalize_section()

  -- Monta o resultado final: Dashboard + 2 quebras + tarefas
  local final_lines = {}
  if #topics > 0 then
    -- Ordenação por prioridade: O(1) atômico por comparação usando peso pré-calculado
    table.sort(todo_tasks, function(a, b)
      if a.weight ~= b.weight then
        return a.weight < b.weight
      end
      return a.order < b.order
    end)

    local col1_tasks = {}
    for _, item in ipairs(todo_tasks) do
      if #col1_tasks < 10 then table.insert(col1_tasks, item) end
    end

    local col2_tasks = {}
    for _, item in ipairs(in_progress_tasks) do
      if #col2_tasks < 10 then table.insert(col2_tasks, item) end
    end

    local done_map = {}
    for _, item in ipairs(done_tasks) do
      done_map[item.text] = item
    end

    local col3_tasks = {}
    local seen = {}

    -- 1. Prioriza tarefas marcadas como concluídas recentemente pelo usuário nesta sessão
    for _, text in ipairs(recent_done_tasks) do
      if done_map[text] and not seen[text] and #col3_tasks < 10 then
        table.insert(col3_tasks, done_map[text])
        seen[text] = true
      end
    end

    -- 2. Demais tarefas concluídas do arquivo, de baixo para cima (mais recentes primeiro)
    for i = #done_tasks, 1, -1 do
      local item = done_tasks[i]
      if not seen[item.text] and #col3_tasks < 10 then
        table.insert(col3_tasks, item)
        seen[item.text] = true
      end
    end

    local kanban_data = {
      col1 = col1_tasks,
      col2 = col2_tasks,
      col3 = col3_tasks,
    }

    local dash_lines = build_dashboard(topics, kanban_data)
    table.insert(final_lines, "")

    -- Centralização horizontal das tabelas no centro da janela/tela
    local pad = ""
    if M.config and M.config.center then
      local win = vim.fn.bufwinid(buf)
      local win_w = (win > 0 and vim.api.nvim_win_get_width(win)) or vim.o.columns or 120
      local text_w = win_w
      if win > 0 then
        local wininfo = vim.fn.getwininfo(win)[1]
        if wininfo and wininfo.textoff then
          text_w = math.max(1, win_w - wininfo.textoff)
        end
      end
      local table_w = vim.fn.strdisplaywidth(dash_lines[1] or "")
      local margin = math.max(0, math.floor((text_w - table_w) / 2))
      pad = string.rep(" ", margin)
    end

    for _, dl in ipairs(dash_lines) do
      table.insert(final_lines, pad .. dl)
    end
    table.insert(final_lines, "")
    table.insert(final_lines, "")
  end

  for _, tl in ipairs(task_lines) do
    table.insert(final_lines, tl)
  end

  -- Evita modificar o buffer se não houve alterações
  local changed = (#lines ~= #final_lines)
  if not changed then
    for i, l in ipairs(lines) do
      if l ~= final_lines[i] then
        changed = true
        break
      end
    end
  end

  if changed then
    local cur_win = vim.api.nvim_get_current_win()
    local cur_buf = vim.api.nvim_win_is_valid(cur_win) and vim.api.nvim_win_get_buf(cur_win)
    local saved_cursor = (cur_buf == buf) and vim.api.nvim_win_get_cursor(cur_win) or nil

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_lines)

    if saved_cursor and vim.api.nvim_win_is_valid(cur_win) then
      local max_l = vim.api.nvim_buf_line_count(buf)
      local target_row = math.min(saved_cursor[1], max_l)
      pcall(vim.api.nvim_win_set_cursor, cur_win, { target_row, saved_cursor[2] })
    end
  end

  -- Aplica highlights coloridos aos contadores e barras de progresso
  vim.api.nvim_buf_clear_namespace(buf, 0, 0, -1)
  for i, line in ipairs(final_lines) do
    -- Destaque para as barras de progresso e porcentagens (em títulos e no dashboard)
    local bar_start, bar_str = line:match("()%[([█░]+)%]")
    if bar_start and bar_str then
      local filled_count = select(2, bar_str:gsub("█", ""))
      local s_bar = bar_start
      if filled_count > 0 then
        local fill_bytes = #string.rep("█", filled_count)
        vim.api.nvim_buf_add_highlight(buf, 0, "TodoGreen", i - 1, s_bar, s_bar + fill_bytes)
      end
      local empty_count = select(2, bar_str:gsub("░", ""))
      if empty_count > 0 then
        local empty_start = s_bar + #string.rep("█", filled_count)
        local empty_bytes = #string.rep("░", empty_count)
        vim.api.nvim_buf_add_highlight(buf, 0, "Comment", i - 1, empty_start, empty_start + empty_bytes)
      end
    end

    -- Destaque na porcentagem e nos 11 contadores de tarefas
    local pct_start, pct_str = line:match("()([%d%.]+%%)")
    if pct_start and pct_str then
      vim.api.nvim_buf_add_highlight(buf, 0, "TodoGreen", i - 1, pct_start - 1, pct_start - 1 + #pct_str)

      local counter_start = pct_start + #pct_str + 3
      local slot_colors = {
        "TodoGreen",     -- 1: done [x]
        "TodoBlue",      -- 2: in progress [+]
        "TodoRed",       -- 3: pending [ ]
        "TodoMagenta",   -- 4: priority [!]
        "TodoOrange",    -- 5: priority max [>]
        "TodoCyan",      -- 6: delegated [@]
        "TodoYellow",    -- 7: doubt [?]
        "TodoBug",       -- 8: bug [#]
        "TodoRefactor",  -- 9: refactor [/]
        "TodoBroken",    -- 10: broken [*]
        "TodoTotal",     -- 11: total
      }
      for k = 1, 11 do
        local slot_start = counter_start + (k - 1) * 4
        local slot = line:sub(slot_start, slot_start + 2)
        local d_s, d_e = slot:find("%d+")
        if d_s and d_e then
          local col_start = (slot_start - 1) + (d_s - 1)
          local col_end   = (slot_start - 1) + d_e
          vim.api.nvim_buf_add_highlight(buf, 0, slot_colors[k], i - 1, col_start, col_end)
        end
      end
    end
  end
end

local task_options = {
  { tag = "x", label = " [x] Concluído (Done)" },
  { tag = " ", label = " [ ] Pendente (Pending)" },
  { tag = "+", label = " [+] Em Progresso (In Progress)" },
  { tag = "!", label = " [!] Prioridade (Priority)" },
  { tag = ">", label = " [>] Prioridade Máxima (Max Priority)" },
  { tag = "@", label = " [@] Delegado (Delegated)" },
  { tag = "?", label = " [?] Dúvida (Doubt)" },
  { tag = "#", label = " [#] Bug" },
  { tag = "/", label = " [/] Refatoração (Refactor)" },
  { tag = "*", label = " [*] Quebrado (Broken)" },
}

-- Abre menu flutuante interativo para selecionar status da tarefa
local function open_status_menu()
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(orig_win)
  local lnum = cursor[1]
  local line = vim.api.nvim_buf_get_lines(orig_buf, lnum - 1, lnum, false)[1]

  -- Se o cursor estiver em uma linha do Kanban (começa com │), pula para a tarefa correspondente
  if line and line:match("^%s*│") then
    local bars = {}
    for b in line:gmatch("()│") do
      table.insert(bars, b)
    end
    if #bars >= 4 then
      local cur_byte = cursor[2] + 1
      local col_str = ""
      if cur_byte < bars[2] then
        col_str = line:sub(bars[1] + #'│', bars[2] - 1)
      elseif cur_byte < bars[3] then
        col_str = line:sub(bars[2] + #'│', bars[3] - 1)
      else
        col_str = line:sub(bars[3] + #'│', bars[4] - 1)
      end

      local tag, task_text = col_str:match("%s*•%s*(%[[^%]]+%])%s*(.-)%s*$")
      if tag and task_text and #task_text > 0 and not task_text:match("^%(Nenhum") then
        task_text = task_text:gsub("….*$", ""):gsub("%s+$", "")
        if #task_text >= 3 then
          local all_lines = vim.api.nvim_buf_get_lines(orig_buf, 0, -1, false)
          for idx, l in ipairs(all_lines) do
            if l:match("^%s*%[") and l:find(tag, 1, true) and l:find(task_text, 1, true) then
              vim.api.nvim_win_set_cursor(orig_win, { idx, 4 })
              vim.cmd("normal! zz")
              return
            end
          end
        end
      end
    end
  end

  -- Se o cursor estiver sobre um item da visão geral (dashboard), pula direto para a tarefa do tópico correspondente
  if line and line:find("•") then
    local topic_name = line:match("•%s+(.-)%s+%[")
    if topic_name and topic_name ~= "TOTAL" then
      local all_lines = vim.api.nvim_buf_get_lines(orig_buf, 0, -1, false)
      for idx, l in ipairs(all_lines) do
        local t = l:match("^%-%s*([^%-].*)")
        if t then
          local clean_t = t:gsub("%s*%-?%[.*$", ""):gsub("%s*$", "")
          if clean_t:upper() == topic_name:upper() then
            -- Pula para a primeira tarefa sob o tópico se existir, ou para o próprio título do tópico
            local target_line = idx
            if all_lines[idx + 1] and all_lines[idx + 1]:match("^%s*%[") then
              target_line = idx + 1
            end
            vim.api.nvim_win_set_cursor(orig_win, { target_line, 4 })
            vim.cmd("normal! zz")
            return
          end
        end
      end
    end
    vim.cmd("normal! \r")
    return
  end

  -- Se o cursor estiver sobre o título de um tópico (- TITULO), volta para o item correspondente na visão geral
  local title = line and line:match("^%-%s*([^%-].*)")
  if title then
    local clean_title = title:gsub("%s*%-?%[.*$", ""):gsub("%s*$", "")
    local all_lines = vim.api.nvim_buf_get_lines(orig_buf, 0, -1, false)
    for idx, l in ipairs(all_lines) do
      if l:find("•") then
        local dash_name = l:match("•%s+(.-)%s+%[")
        if dash_name and dash_name:upper() == clean_title:upper() then
          vim.api.nvim_win_set_cursor(orig_win, { idx, 4 })
          vim.cmd("normal! zz")
          return
        end
      end
    end
    vim.cmd("normal! \r")
    return
  end

  -- Ignora linhas vazias, separadores e bordas
  if not line or line:match("^%s*$") or line:match("^%s*%-") or line:match("^%s*===") or line:match("^%s*[┌└]") then
    vim.cmd("normal! \r")
    return
  end

  -- Verifica se a linha contém uma tag de tarefa [.]
  local s_tag, _, current_char = line:find("%[([^%]]?)%]")
  if not s_tag then
    vim.cmd("normal! \r")
    return
  end

  -- Prepara buffer do menu flutuante
  local menu_buf = vim.api.nvim_create_buf(false, true)
  local menu_lines = {}
  local default_index = 1

  for idx, opt in ipairs(task_options) do
    table.insert(menu_lines, opt.label)
    if opt.tag == current_char then
      default_index = idx
    end
  end

  vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, menu_lines)
  vim.bo[menu_buf].modifiable = false
  vim.bo[menu_buf].filetype = "task"

  -- Dimensões e posicionamento da janela flutuante
  local width = 38
  local height = #task_options

  local win_opts = {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Selecionar Status ",
    title_pos = "center",
  }

  local menu_win = vim.api.nvim_open_win(menu_buf, true, win_opts)
  vim.wo[menu_win].cursorline = true

  -- Posiciona o cursor na opção atual
  vim.api.nvim_win_set_cursor(menu_win, { default_index, 0 })

  -- Função para fechar o menu
  local function close_menu()
    if vim.api.nvim_win_is_valid(menu_win) then
      vim.api.nvim_win_close(menu_win, true)
    end
  end

  -- Confirma seleção com Enter
  local function select_option()
    local selected_row = vim.api.nvim_win_get_cursor(menu_win)[1]
    local selected_tag = task_options[selected_row].tag
    close_menu()

    -- Atualiza a linha do buffer original
    if vim.api.nvim_buf_is_valid(orig_buf) then
      local cur_lines = vim.api.nvim_buf_get_lines(orig_buf, lnum - 1, lnum, false)
      if cur_lines[1] then
        local new_line = cur_lines[1]:gsub("%[([^%]]?)%]", "[" .. selected_tag .. "]", 1)
        vim.api.nvim_buf_set_lines(orig_buf, lnum - 1, lnum, false, { new_line })

        local _, _, content = new_line:match("^%s*(%[[^%]]+%])(%s*%-?%s*)(.*)$")
        if content and #content > 0 then
          local clean_content = string.upper(content:sub(1, 1)) .. content:sub(2)
          for k, v in ipairs(recent_done_tasks) do
            if v == clean_content then
              table.remove(recent_done_tasks, k)
              break
            end
          end
          if selected_tag:lower() == "x" then
            table.insert(recent_done_tasks, 1, clean_content)
          end
        end

        update_task_counts(orig_buf)
      end
    end
  end

  -- Atalhos dentro da janela flutuante
  local key_opts = { buffer = menu_buf, silent = true, nowait = true }
  vim.keymap.set("n", "<CR>", select_option, key_opts)
  vim.keymap.set("n", "<Esc>", close_menu, key_opts)
  vim.keymap.set("n", "q", close_menu, key_opts)
end

-- Insere nova tarefa na linha de baixo e entra em modo insert com 4 espaços de indentação
local function add_task_below()
  local buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local indent = "    "
  local new_line = indent .. "[ ] - "

  vim.api.nvim_buf_set_lines(buf, lnum, lnum, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #new_line })
  vim.cmd("startinsert!")
end

-- Setup do plugin
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
  setup_highlights()

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "TASKNVIM",
    callback = function() vim.bo.filetype = "task" end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "TASKNVIM",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()

      vim.cmd("syntax clear")
      vim.cmd([[syntax match TaskMainTitle     /^-.*/]])
      vim.cmd([[syntax match TaskSubTitle      /--.*/]])

      vim.cmd("syntax  match TaskUnchecked   /\\[ \\]/")
      vim.cmd("syntax  match TaskChecked     /\\[x\\]/")
      vim.cmd("syntax  match TaskInProgress  /\\[+\\]/")
      vim.cmd("syntax  match TaskPriority    /\\[!\\]/")
      vim.cmd("syntax  match TaskPriorityMax /\\[>\\]/")
      vim.cmd("syntax  match TaskDelegated   /\\[@\\]/")
      vim.cmd("syntax  match TaskDoubt       /\\[?\\]/")
      vim.cmd("syntax  match TaskBug         /\\[#\\]/")
      vim.cmd("syntax  match TaskRefactor    /\\[\\/\\]/")
      vim.cmd("syntax  match TaskBroken      /\\[\\*\\]/")

      -- Sintaxe do Dashboard
      vim.cmd([[syntax match TaskDashBorder   /^\s*====.*====$/]])
      vim.cmd([[syntax match TaskDashBorder   /^\s*[┌└]─.*[┐┘]$/]])
      vim.cmd([[syntax match TaskDashTitle    /DASHBOARD/]])
      vim.cmd([[syntax match TaskDashTotal    /\<TOTAL\>/]])
      vim.cmd([[syntax match TaskDashBullet   /•/]])
      vim.cmd([[syntax match TaskDashDone     /✓ CONCLUIDO/]])
      vim.cmd([[syntax match TaskDashPending  /○ PENDENTE/]])
      vim.cmd([[syntax match TaskDashBug      /(\d\+ Bugs\?)/]])

      -- Sintaxe do Mini-Quadro Kanban
      vim.cmd([[syntax match TaskKanbanBorder     /[┌┐└┘├┤┬┴│─]/]])
      vim.cmd([[syntax match TaskKanbanHeaderTodo /\<PRIORITY\>/]])
      vim.cmd([[syntax match TaskKanbanHeaderProg /\<IN PROGRESS\>/]])
      vim.cmd([[syntax match TaskKanbanHeaderDone /\<DONE\>/]])
      vim.cmd([[syntax match TaskKanbanEmpty      /(Nenhuma[^)]*)/]])

      setup_highlights()

      -- Atalho Enter (<CR>) para abrir menu de status em tarefas
      vim.keymap.set("n", "<CR>", open_status_menu, {
        buffer = buf,
        silent = true,
        desc = "TaskNvim: Selecionar status com menu flutuante",
      })

      -- Atalho ';' para criar nova tarefa na linha de baixo
      vim.keymap.set("n", ";", add_task_below, {
        buffer = buf,
        silent = true,
        desc = "TaskNvim: Nova tarefa na linha de baixo",
      })
    end,
  })

  -- Atualiza no BufRead e BufWritePre (evita deixar buffer marcado como modificado após :w)
  vim.api.nvim_create_autocmd({ "BufRead", "BufWritePre" }, {
    pattern = "TASKNVIM",
    callback = update_task_counts,
  })

  -- Reajusta e centraliza dinamicamente em tempo real ao redimensionar terminal (zoom) ou janelas (tiles/splits)
  local function on_window_resize()
    if not (M.config and M.config.center) then return end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match("TASKNVIM$") or vim.bo[buf].filetype == "task" then
          local was_mod = vim.bo[buf].modified
          update_task_counts(buf)
          if not was_mod and vim.api.nvim_buf_is_valid(buf) then
            vim.bo[buf].modified = false
          end
        end
      end
    end
  end

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    callback = on_window_resize,
  })
end

return M
