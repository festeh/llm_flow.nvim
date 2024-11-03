local ui = require("llm_flow.ui")
local uv = vim.uv

local M = {
  line = nil,
  pos = nil,
  content = nil,
  req_id = nil,
  timer = nil,
}

local function stop_timer()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
end

function M.find_lsp_client()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local found = nil
  for _, client in pairs(clients) do
    if client.name == "llm-flow" then
      found = client
    end
    print(client.name)
    print(vim.inspect(client))
    print("------------------------------")
    print()
  end
  return found
end

local function on_predict_complete(err, result)
  if err then
    vim.notify("Prediction failed: " .. err.message, vim.log.levels.ERROR)
    return
  end
  if result.id ~= M.req_id then
    print("cancelled", result.id, M.req_id)
    return
  end
  local content = result.content
  local content_lines = vim.split(content, "\n", { plain = true })
  local truncated_content = { content_lines[1] }
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, M.line, M.line + #content_lines, false)
  for i = 2, #content_lines do
    local trimmed_content = vim.trim(content_lines[i] or "")
    local trimmed_buffer = vim.trim(buffer_lines[i] or "")
    print(i, "|", trimmed_content, "|, |", trimmed_buffer, "|")

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

  print(client.name)
  print(vim.inspect(client.server_capabilities))

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
  M.req_id = req_id
end

local function timed_request()
  vim.notify("timed req")
  stop_timer()
  vim.schedule_wrap(function()
    vim.notify("launched")
    M.predict_editor()
  end
  )()
end

function M.setup()
  local group = vim.api.nvim_create_augroup('LLMFlow', { clear = true })

  -- Create separate autocommands for insert mode events
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = timed_request
  })

  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group,
    callback = function()
      stop_timer()
      M.timer = uv.new_timer()
      M.timer:start(250, 0, timed_request)
    end,
  })

  -- Clear virtual text when leaving insert mode
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    callback = function()
      stop_timer()
      ui.clear()
    end,
  })
end

function M.desetup()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
  pcall(vim.api.nvim_del_augroup_by_name, 'LLMFlow')
  ui.clear()
end

return M
