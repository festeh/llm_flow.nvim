local utils = require('llm_flow.utils')

local M = {}

M.init = function()
    local data_path = vim.fn.stdpath('data')
    local llm_flow_path = data_path .. '/llm_flow'
    
    if not utils.ensure_directory_exists(llm_flow_path) then
        -- Directory didn't exist and was created, clone the repo
        if not utils.git_clone('festeh/llm_flow', llm_flow_path) then
            vim.notify('Failed to clone llm_flow repository', vim.log.levels.ERROR)
            return false
        end
    end
    
    return true
end

return M
