-- Add command to run the script
--
--
vim.api.nvim_create_user_command('LLMRun', function(opts)
  -- Split the args into module and function
  local args = vim.split(opts.args, ' ')

  -- Clear cached llm_flow modules
  for k in pairs(package.loaded) do
    if k:match("^llm_flow") then
      package.loaded[k] = nil
    end
  end

  -- Get module and function from args
  local module_name = args[1]
  local func_name = args[2]
  local open_buf = args[3]

  -- Require module and call function
  local ok, module = pcall(require, module_name)
  if not ok then
    print("Error loading module:", module)
  end

  local func = module[func_name]
  if not func then
    -- print("Function " .. func_name .. " not found in module " .. module_name)
    print("Err: bad args")
    print(vim.inspect(arg))
    print(func_name)
    print(module_name)
    return
  end

  -- Capture both return value and printed output
  local output = ""
  -- local function capture_print(...)
  --   local args = { ... }
  --   local str = ""
  --   for i, v in ipairs(args) do
  --     if i > 1 then str = str .. "\t" end
  --     str = str .. tostring(v)
  --   end
  --   output = output .. str .. "\n"
  -- end
  --
  -- -- Replace print with our capturing function
  -- local old_print = print
  -- print = capture_print

  local ok, result = pcall(func)

  -- Restore original print
  -- print = old_print
  --
  if not ok then
    print("Error calling function:", result)
    return
  end
  --
  -- -- Combine captured output with result if any
  -- local display_text = output
  -- if result then
  --   display_text = display_text .. vim.inspect(result)
  -- end
  --
  -- -- Display the result in a floating window
  -- local lines = vim.split(display_text, '\n')
  -- local buf = vim.api.nvim_create_buf(false, true)
  -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  --
  -- -- Calculate window size and position
  -- local width = math.min(80, vim.o.columns - 4)
  -- local height = math.min(#lines, vim.o.lines - 4)
  -- local row = math.floor((vim.o.lines - height) / 2)
  -- local col = math.floor((vim.o.columns - width) / 2)
  --
  -- local opts = {
  --   relative = 'editor',
  --   width = width,
  --   height = height,
  --   row = row,
  --   col = col,
  --   style = 'minimal',
  --   border = 'rounded'
  -- }
  --
  -- vim.api.nvim_open_win(buf, true, opts)
  --
  -- -- Set buffer options
  -- vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  -- vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  -- vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
end, {
  nargs = '+',
  desc = 'Run LLM Flow function and display result'
})

vim.api.nvim_create_user_command('LLMClear', function(opts)
  require("llm_flow.ui").clear()
end, {
  desc = "ClearScreen"
})
