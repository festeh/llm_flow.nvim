local M = {}

-- Creates virtual (ghost) text at the specified position
-- @param line: 0-based line number
-- @param pos: 0-based column position
-- @param text: string to display as virtual text
function M.set_text(line, pos, text)
  M.clear()

  local lines = vim.split(text, '\n', { plain = true })
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
  for i, line_text in ipairs(lines) do
    local line_num = line + i - 1
    if line_num >= buffer_line_count then
      break
    end
    local ns_id = vim.api.nvim_create_namespace('llm_flow')
    if i == 1 then
      -- First line is inline virtual text
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num, pos, {
        virt_text = { { line_text, 'Comment' } },
        virt_text_pos = 'inline',
        hl_mode = 'combine',
      })
    else
      -- Subsequent lines are inserted as new lines
      vim.api.nvim_buf_set_lines(bufnr, line_num, line_num, false, { line_text })
    end
  end
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
