-- Add command to run the script
vim.api.nvim_create_user_command('LLMRun', function(opts)
    -- Split the args into module and function
    local args = vim.split(opts.args, ' ')
    if #args ~= 2 then
        vim.notify('Usage: LLMRun <module_name> <function_name>', vim.log.levels.ERROR)
        return
    end
    
    -- Get the plugin root directory
    local plugin_root = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('<sfile>:p')), ':h:h')
    
    -- Build and execute the command
    local cmd = string.format('lua %s/run.lua %s %s', plugin_root, args[1], args[2])
    local output = vim.fn.system(cmd)
    
    -- Display the result in a floating window
    local lines = vim.split(output, '\n')
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Calculate window size and position
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#lines, vim.o.lines - 4)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded'
    }
    
    vim.api.nvim_open_win(buf, true, opts)
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', {noremap = true, silent = true})
end, {
    nargs = '+',
    desc = 'Run LLM Flow function and display result'
})
