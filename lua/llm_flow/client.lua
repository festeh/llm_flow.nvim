local lsp = vim.lsp

local client = nil
local client_id = nil
local server_proc = nil

local M = {}

-- Find a random available port
local function get_random_port()
  local socket = vim.loop.new_tcp()
  socket:bind("127.0.0.1", 0)
  local port = socket:getsockname().port
  socket:close()
  return port
end

-- Spawn server process
local function spawn_server(port)
  local cmd = "lsp-server"
  local args = { "--port", tostring(port) }
  
  local handle
  handle = vim.loop.spawn(cmd, {
    args = args,
    detached = true
  },
  function(code)
    handle:close()
    if code ~= 0 then
      vim.notify("[LLM] Server process exited with code: " .. code, vim.log.levels.ERROR)
    end
  end)
  
  if not handle then
    vim.notify("[LLM] Failed to spawn server process", vim.log.levels.ERROR)
    return nil
  end
  
  return handle
end

M.start = function(opts)
  opts = opts or {}
  local host = "127.0.0.1"
  local port
  
  if opts.debug then
    -- Debug mode - connect to existing server
    host = "0.0.0.0" 
    port = 7777
  else
    -- Production mode - spawn new server
    port = get_random_port()
    server_proc = spawn_server(port)
    if not server_proc then
      return nil
    end
    -- Give server time to start
    vim.loop.sleep(1000)
  end

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
