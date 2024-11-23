local lsp = vim.lsp


local client = nil
local client_id = nil

local M = {}

M.start = function(config)
  local host = "0.0.0.0"
  local port = 7777
  local cmd = lsp.rpc.connect(host, port)

  local server_name = "llm-flow"

  local _client_id = lsp.start_client({
    name = server_name,
    cmd = cmd,
    cmd_env = {},
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
  })
  if _client_id == nil then
    vim.notify("[LLM] Error starting llm-flow", vim.log.levels.ERROR)
    return nil
  end
  client = lsp.get_client_by_id(_client_id)
  client_id = _client_id
  return client_id
end

M.get = function()
  return client
end

return M
