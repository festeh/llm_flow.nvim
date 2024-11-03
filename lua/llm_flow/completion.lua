local ui = require("llm_flow.ui")
local uv = vim.uv

local M = {
  line = nil,
  pos = nil,
  content = nil,
  req_id = nil,
  timer = nil,
}

function M.find_lsp_client()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in pairs(clients) do
    if client.name == "llm-flow" then
      return client
    end
  end
  return nil
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
  local uri = vim.uri_from_bufnr(bufnr)


  local request_params = vim.tbl_extend("force", params, {
    providerAndModel = "codestral/codestral-latest",
    uri = uri,
    line = cursor[1] - 1, -- Convert from 1-based to 0-based line number
    pos = cursor[2],
  })
  local status, req_id = client.request("predict_editor", request_params, function(err, result)
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
    local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1] + #content_lines - 1, false)
    for i = 2, #content_lines do
      local trimmed_content = vim.trim(content_lines[i] or "")
      local trimmed_buffer = vim.trim(buffer_lines[i] or "")
      print(i, trimmed_content, trimmed_buffer)
      if trimmed_content == trimmed_buffer then
        break
      end
      table.insert(truncated_content, content_lines[i])
    end
    local final_content = table.concat(truncated_content, "\n")
    ui.set_text(cursor[1] - 1, cursor[2], final_content)
    return result
  end)
  M.req_id = req_id
end

function M.setup()
  local group = vim.api.nvim_create_augroup('LLMFlow', { clear = true })

  -- Create autocommands for insert mode events
  vim.api.nvim_create_autocmd({ 'InsertEnter', 'TextChangedI' }, {
    group = group,
    callback = function()
      -- Cancel existing timer if any
      if M.timer then
        M.timer:stop()
        M.timer:close()
      end

      -- Create new timer for debouncing
      M.timer = uv.new_timer()
      M.timer:start(50, 0, vim.schedule_wrap(function()
        M.predict_editor()
        -- Clean up timer
        M.timer:stop()
        M.timer:close()
        M.timer = nil
      end))
    end,
  })

  -- Clear virtual text when leaving insert mode
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = group,
    callback = function()
      if M.timer then
        M.timer:stop()
        M.timer:close()
        M.timer = nil
      end
      ui.clear()
    end,
  })
end

function M.desetup()
  -- Clear any existing timer
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end
  
  -- Clear the autocommands by deleting the group
  pcall(vim.api.nvim_del_augroup_by_name, 'LLMFlow')
  
  -- Clear any remaining virtual text
  ui.clear()
end

return M
