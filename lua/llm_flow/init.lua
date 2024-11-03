local utils = require('llm_flow.utils')
local lsp = vim.lsp
local api = vim.api

local M = {}


local function ensure_install()
  local data_path = vim.fn.stdpath('data')
  local llm_flow_path = data_path .. '/llm_flow'
  local executable_path = llm_flow_path .. '/bin/lsp-server'

  -- Step 1: Ensure repository exists
  if not utils.check_directory_exists(llm_flow_path) then
    if not utils.git_clone('festeh/llm_flow', llm_flow_path) then
      vim.notify('Failed to clone llm_flow repository', vim.log.levels.ERROR)
      return false
    end
  end

  -- Step 2: Check and build executable if needed
  if not utils.check_executable_exists(executable_path) then
    -- Ensure bin directory exists
    vim.fn.mkdir(llm_flow_path .. '/bin', 'p')

    if not utils.build_go_executable(llm_flow_path) then
      vim.notify('Failed to build lsp-server executable', vim.log.levels.ERROR)
      return false
    end
    vim.notify('Successfully built lsp-server executable', vim.log.levels.INFO)
  end
end



M.setup = function()
  ensure_install()
  local host = "0.0.0.0"
  local port = 7777
  local cmd = lsp.rpc.connect(host, port)

  local server_name = "llm-flow"

  local client_id = lsp.start_client({
    name = server_name,
    cmd = cmd,
    cmd_env = {},
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
  })
  if client_id == nil then
    vim.notify("[LLM] Error starting llm-flow", vim.log.levels.ERROR)
    return false
  end

  local augroup = server_name
  api.nvim_create_augroup(augroup, { clear = true })
  api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    pattern = { "*.c", "*.lua", "*.py" },
    callback = function(ev)
      if not lsp.buf_is_attached(ev.buf, client_id) then
        lsp.buf_attach_client(ev.buf, client_id)
      end
    end,
  })
  M.client_id = client_id

  -- TODO: restore
  -- api.nvim_create_autocmd("VimLeavePre", {
  --   group = augroup,
  --   callback = function()
  --     lsp.stop_client(client_id)
  --   end,
  -- })

  return true
end

return M
