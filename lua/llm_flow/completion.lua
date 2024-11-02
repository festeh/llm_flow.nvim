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

return M
