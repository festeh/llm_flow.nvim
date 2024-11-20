local ui = require("llm_flow.ui")
local uv = vim.uv
local l = require("llm_flow.logger")


local kDebounce = 100 -- ms

local M = {
  suggestion = nil,
  timer = nil,
  client = nil,
  req_id = nil,
}

local function stop_timer_and_cancel()
  ui.clear()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
  local client = M.client
  if client then
    for req_id, req in pairs(client.requests) do
      if req.type == "pending" then
        l.log(req_id, "pending")
        client.notify('cancel_predict_editor', { id = req_id })
      end
    end
    print("\n-\n")
  end
end

function M.find_lsp_client()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in pairs(clients) do
    if client.name == "llm-flow" then
      M.client = client
      return client
    end
  end
end

local function on_predict_complete(err, result, line, pos)
  if err then
    vim.notify("Prediction failed: " .. err.message, vim.log.levels.ERROR)
    return
  end

  -- Return if not in insert mode
  if vim.api.nvim_get_mode().mode ~= "i" then
    return
  end

  if M.req_id ~= result.id then
    l.log("rejected", "expected", M.req_id, "got", result.id)
    return
  end

  local content = result.content
  M.suggestion = {
    content = content,
    line = line,
    pos = pos
  }
  local content_lines = vim.split(content, "\n", { plain = true })
  local truncated_content = { content_lines[1] }
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, line, line + #content_lines, false)
  for i = 2, #content_lines do
    local trimmed_content = vim.trim(content_lines[i] or "")
    local trimmed_buffer = vim.trim(buffer_lines[i] or "")
    if trimmed_content == trimmed_buffer then
      break
    end
    table.insert(truncated_content, content_lines[i])
  end
  local final_content = table.concat(truncated_content, "\n")
  ui.set_text(line, pos, final_content)
  l.log(result.id, "completed")
  return result
end

--- @param params table The parameters for the prediction
function M.predict_editor(params)
  local client = M.find_lsp_client()

  if not client then
    return
  end

  params = params or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)

  local line = cursor[1] - 1
  local pos = cursor[2]

  local request_params = vim.tbl_extend("force", params, {
    providerAndModel = "codestral/codestral-latest",
    uri = vim.uri_from_bufnr(bufnr),
    line = line,
    pos = pos
  })
  local status, req_id = client.request("predict_editor", request_params, function(err, result)
    on_predict_complete(err, result, line, pos)
  end)
  M.req_id = req_id
  l.log("Sent request", req_id)
end

local function timed_request()
  vim.schedule_wrap(function()
    M.predict_editor()
  end
  )()
end



function M.setup()
  local group = vim.api.nvim_create_augroup('LLMFlow', { clear = true })

  -- Set up keybindings
  vim.keymap.set('i', '<C-l>', function()
    M.accept_line()
  end, { noremap = true, silent = true })

  vim.keymap.set('i', '<C-k>', function()
    M.accept_word()
  end, { noremap = true, silent = true })

  -- Create separate autocommands for insert mode events
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = timed_request
  })

  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group,
    callback = function()
      stop_timer_and_cancel()
      M.timer = uv.new_timer()
      M.timer:start(kDebounce, 0, timed_request)
    end,
  })

  -- Clear virtual text when leaving insert mode
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    callback = function()
      stop_timer_and_cancel()
      ui.clear()
    end,
  })
end

function M.accept_line()
  if not M.suggestion then
    return
  end
  stop_timer_and_cancel()
  local line = M.suggestion.line
  local pos = M.suggestion.pos
  local content = M.suggestion.content

  local lines
  if content:sub(1, 1) == "\n" then
    -- Get lines after the newline
    lines = vim.split(content:sub(2), "\n", { plain = true })
    if lines[1] then
      ui.accept_next_line(line, lines[1])
    end
  else
    -- Get all lines
    lines = vim.split(content, "\n", { plain = true })
    if lines[1] then
      ui.accept_text(line, pos, lines[1])
    end
  end

  M.timer = uv.new_timer()
  M.timer:start(kDebounce, 0, timed_request)
end

function M.accept_word()
  if M.suggestion then
    local first_line = vim.split(M.suggestion.content, "\n", { plain = true })[1]
    if first_line then
      local words = vim.split(first_line, " ", { plain = true })
      local first_word = words[1]
      if first_word then
        ui.accept_text(M.line, M.pos, first_word)
        stop_timer_and_cancel()
        M.timer = uv.new_timer()
        M.timer:start(kDebounce, 0, timed_request)
      end
    end
  end
end

function M.desetup()
  stop_timer_and_cancel()
  pcall(vim.api.nvim_del_augroup_by_name, 'LLMFlow')
end

return M
