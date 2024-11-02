local utils = require('llm_flow.utils')

local M = {}

M.init = function()
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

  return true
end

return M
