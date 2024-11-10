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

  -- Get current line content to check position validity
  local current_line = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
  if not current_line or pos > #current_line then
    return
  end

  local ns_id = vim.api.nvim_create_namespace('llm_flow')

  -- Set first line as inline virtual text
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, pos, {
    virt_text = { { lines[1], 'rainbow3' } },
    virt_text_pos = 'inline',
    hl_mode = 'combine',
  })

  if #lines > 1 then
    local virt_lines = {}
    for i = 2, #lines do
      table.insert(virt_lines, { { lines[i], 'rainbow2' } })
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
      virt_lines = virt_lines,
      hl_mode = 'combine',
    })
  end
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
  M.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
  -- Split the current line into before and after cursor parts
  local before_cursor = current_line:sub(1, pos)
  local after_cursor = current_line:sub(pos + 1)
  -- Create new line by joining before_cursor + new_text + after_cursor
  local new_line = before_cursor .. text .. after_cursor
  vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, { new_line })
  -- Move cursor to end of inserted text
  vim.api.nvim_win_set_cursor(0, { line + 1, pos + #text })
  M.clear()
end

-- Accepts the next line of suggestion by inserting it and shifting existing lines down
-- @param line: 0-based line number
-- @param next_line: text to insert as new line
function M.accept_next_line(line, next_line)
  M.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Get all lines after current line
  local existing_lines = vim.api.nvim_buf_get_lines(bufnr, line + 1, -1, false)
  -- Create new lines array with next_line inserted
  local new_lines = { next_line }
  vim.list_extend(new_lines, existing_lines)
  -- Replace all lines starting from line + 1
  vim.api.nvim_buf_set_lines(bufnr, line + 1, line + 1 + #existing_lines, false, new_lines)
  -- Move cursor to end of accepted line
  vim.schedule(function()
    local new_pos = #next_line
    vim.api.nvim_win_set_cursor(0, { line + 2, new_pos })
  end)
end

return M
