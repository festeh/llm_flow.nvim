local ui = require("llm_flow.ui")

local M = {
  line = nil,
  pos = nil,
  content = nil,
  request = nil,
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
--- @param model string The model to use for prediction
function M.predict_editor(params, model)
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
    local content = result.content
    local content_lines = vim.split(content, "\n", { plain = true })
    local truncated_content = { content_lines[1] }
    local bufnr = vim.api.nvim_get_current_buf()
    local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1] + #content_lines - 1, false)
    for i = 2, #content_lines do
      print(i, content_lines[i], buffer_lines[i])
      if content_lines[i] == buffer_lines[i] then
        break
      end
      table.insert(truncated_content, content_lines[i])
    end
    local final_content = table.concat(truncated_content, "\n")
    ui.set_text(cursor[1] - 1, cursor[2], final_content)
    return result
  end)
end

function M.setup()
end

return M
