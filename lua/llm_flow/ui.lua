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
  if line >= buffer_line_count then
    return
  end

  local ns_id = vim.api.nvim_create_namespace('llm_flow')

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, pos, {
    virt_text = { { lines[1], 'Comment' } },
    virt_text_pos = 'inline',
    hl_mode = 'combine',
  })

  if #lines > 1 then
    local virt_lines = {}
    for i = 2, #lines do
      table.insert(virt_lines, { { lines[i], 'Comment' } })
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
      virt_lines = virt_lines,
      hl_mode = 'combine',
    })
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

-- Accepts the suggested text by inserting it at the specified position
-- @param line: 0-based line number
-- @param pos: 0-based column position 
-- @param text: text to insert
function M.accept_text(line, pos, text)
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
  local new_line = current_line:sub(1, pos) .. text
  vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, {new_line})
  -- Move cursor to end of inserted text
  vim.api.nvim_win_set_cursor(0, {line + 1, pos + #text})
  M.clear()
end

return M
