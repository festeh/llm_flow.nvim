local ui = require("llm_flow.ui")
local uv = vim.uv


local kDebounce = 250 -- ms

local M = {
  suggestion = nil,
  line = nil,
  pos = nil,
  content = nil,
  timer = nil,
  client = nil
}

local function stop_timer_and_cancel()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
  local client = M.client
  if client then
    for req_id, _ in pairs(client.requests) do
      client.notify('cancel_predict_editor', { id = req_id })
    end
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

local function on_predict_complete(err, result)
  if err then
    vim.notify("Prediction failed: " .. err.message, vim.log.levels.ERROR)
    return
  end
  local content = result.content
  M.suggestion = content
  local content_lines = vim.split(content, "\n", { plain = true })
  local truncated_content = { content_lines[1] }
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, M.line, M.line + #content_lines, false)
  for i = 2, #content_lines do
    local trimmed_content = vim.trim(content_lines[i] or "")
    local trimmed_buffer = vim.trim(buffer_lines[i] or "")
    if trimmed_content == trimmed_buffer then
      break
    end
    table.insert(truncated_content, content_lines[i])
  end
  local final_content = table.concat(truncated_content, "\n")
  ui.set_text(M.line, M.pos, final_content)
  return result
end




--- Send a prediction request using the specified model
--- @param params table The parameters for the prediction
function M.predict_editor(params)
  local client = M.find_lsp_client()

  if not client then
    vim.notify("No llm-flow LSP client found", vim.log.levels.ERROR)
    return
  end

  params = params or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)

  local line = cursor[1] - 1
  local pos = cursor[2]

  M.line = line
  M.pos = pos

  local request_params = vim.tbl_extend("force", params, {
    providerAndModel = "codestral/codestral-latest",
    uri = vim.uri_from_bufnr(bufnr),
    line = line,
    pos = pos
  })
  local status, req_id = client.request("predict_editor", request_params, on_predict_complete)
end

local function timed_request()
  vim.schedule_wrap(function()
    stop_timer_and_cancel()
    vim.notify("launched")
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

local function get_virtual_text_after_cursor()
  if not M.suggestion then return "" end
  local lines = vim.split(M.suggestion, "\n", { plain = true })
  local first_line = lines[1] or ""
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local current_line = vim.api.nvim_get_current_line()
  -- Account for real text length difference
  local virtual_offset = #first_line - #current_line
  if virtual_offset < 0 then return "" end
  return first_line:sub(col + 1 + virtual_offset)
end

function M.accept_line()
  if M.suggestion then
    local lines = vim.split(M.suggestion, "\n", { plain = true })
    
    -- If there's no virtual text after cursor and we have more than one line
    local virtual_text = get_virtual_text_after_cursor()
    if virtual_text == "" and #lines > 1 then
      -- Accept the next line instead
      local next_line = lines[2]
      if next_line then
        ui.accept_text(M.line, M.pos, next_line)
        -- Move cursor to end of accepted line
        vim.schedule(function()
          local new_pos = #next_line
          vim.api.nvim_win_set_cursor(0, {M.line + 1, new_pos})
        end)
      end
    else
      -- Regular behavior - accept first line
      local first_line = lines[1]
      if first_line then
        ui.accept_text(M.line, M.pos, first_line)
      end
    end
    
    stop_timer_and_cancel()
    M.timer = uv.new_timer()
    M.timer:start(kDebounce, 0, timed_request)
  end
end

function M.accept_word()
  if M.suggestion then
    local first_line = vim.split(M.suggestion, "\n", { plain = true })[1]
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
  ui.clear()
end

return M
