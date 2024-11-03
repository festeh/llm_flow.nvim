local M = {}

-- Creates virtual (ghost) text at the specified position
-- @param line: 0-based line number
-- @param pos: 0-based column position
-- @param text: string to display as virtual text
function M.set_text(line, pos, text)
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('llm_flow')
  
  -- Save cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  
  -- Clear any existing virtual text in this namespace
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Split text into lines
  local lines = vim.split(text, '\n', { plain = true })

  -- Create virtual text for each line
  local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)

  for i, line_text in ipairs(lines) do
    local line_num = line + i - 1

    -- Skip if line number would be out of buffer bounds
    if line_num >= buffer_line_count then
      break
    end

    local col_pos = (i == 1) and pos or 0 -- Use pos for first line, 0 for others

    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, col_pos, {
      virt_text = { { line_text, 'Comment' } },
      virt_text_pos = 'inline',
      hl_mode = 'combine',
    })
  end
  
  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, cursor_pos)
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
