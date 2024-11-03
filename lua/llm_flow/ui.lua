local M = {}

-- Creates virtual (ghost) text at the specified position
-- @param line: 0-based line number
-- @param pos: 0-based column position
-- @param text: string to display as virtual text
function M.set_text(line, pos, text)
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('llm_flow')

  -- Clear any existing virtual text in this namespace
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Create virtual text
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, pos, {
    virt_text = { { text, 'Comment' } },
    virt_text_pos = 'inline',
    hl_mode = 'combine',
  })
end

function M.example()
  M.set_text(0, 0, "benis")
end

-- Clears all virtual text created by llm_flow
function M.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('llm_flow')
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

return M
