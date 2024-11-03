local M = {}

function M.find_lsp_client()
  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
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
function M.predict(params, model)
  local client = M.find_lsp_client()
  if not client then
    vim.notify("No llm-flow LSP client found", vim.log.levels.ERROR)
    return
  end

  params = params or {}

  local request_params = vim.tbl_extend("force", params, { model = model })
  client.request("predict", request_params, function(err, result)
    if err then
      vim.notify("Prediction failed: " .. err.message, vim.log.levels.ERROR)
      return
    end
    return result
  end)
end

return M
